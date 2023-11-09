# syntax = docker/dockerfile:1

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.0.0
FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim as base

# Rails app lives here
WORKDIR /rails

# Set production environment
ENV BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development" \
    DEV_DATABASE_NAME="myapp_development" \
    TEST_DATABASE_NAME="myapp_test" \
    PROD_DATABASE="myapp_production" \
    DB_HOST="pgsql-app"  \
    DB_PORT="5432"  \
    DB_USERNAME="postgres"  \
    DB_PASSWORD="Admin@123\$%" \
    SECRET_TOKEN=46af077dde569c266dbf02eb0818fb1d78417e64d68e3c378c3e2b6f5635bb0663dd5196e0a54fdf77448c701c27ff4da467f270c44a6f140e746b5d0deb9e78

# Throw-away build stage to reduce size of final image
FROM base as build

# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev libvips pkg-config

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Copy application code
COPY . .


# Final stage for app image
FROM base

# Install packages needed for deployment
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl nginx libvips postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copy built artifacts: gems, application
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security
RUN useradd rails --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp

USER root
# Start the server by default, this can be overwritten at runtime
EXPOSE 3000
# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]
