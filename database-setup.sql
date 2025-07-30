-- n8n Database Setup Script cho strangematic.com
-- Execute này bằng postgres user

-- Create database
CREATE DATABASE strangematic_n8n;

-- Create user với secure password
CREATE USER strangematic_user WITH PASSWORD 'strangematic_2024_secure!';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE strangematic_n8n TO strangematic_user;

-- Grant CREATEDB privilege cho n8n migrations
ALTER USER strangematic_user CREATEDB;

-- Connect to new database và grant schema privileges
\c strangematic_n8n;
GRANT ALL ON SCHEMA public TO strangematic_user;
GRANT ALL ON ALL TABLES IN SCHEMA public TO strangematic_user;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO strangematic_user;

-- Verify setup
\l
\du 