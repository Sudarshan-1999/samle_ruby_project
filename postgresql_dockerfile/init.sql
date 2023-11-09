CREATE USER admin;
CREATE DATABASE app_development;
GRANT ALL PRIVILEGES ON DATABASE app_development TO admin;
ALTER USER postgres with PASSWORD 'Admin@123$%';
ALTER USER admin with PASSWORD 'Admin@123$%';
ALTER USER admin WITH superuser;
