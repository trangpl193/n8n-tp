-- n8n Database Setup Script cho strangematic.com
-- Run with: psql -U postgres -h localhost -p 5432 -f database-setup.sql

-- Create database cho n8n
CREATE DATABASE strangematic_n8n;

-- Create dedicated user cho n8n
CREATE USER strangematic_user WITH PASSWORD 'strangematic_2024_secure!';

-- Grant all privileges on database
GRANT ALL PRIVILEGES ON DATABASE strangematic_n8n TO strangematic_user;

-- Allow user to create databases (needed for migrations)
ALTER USER strangematic_user CREATEDB;

-- Connect to new database và grant schema privileges
\c strangematic_n8n;

-- Grant schema privileges
GRANT ALL ON SCHEMA public TO strangematic_user;
GRANT ALL ON ALL TABLES IN SCHEMA public TO strangematic_user;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO strangematic_user;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO strangematic_user;

-- Grant future privileges (for new tables created by n8n)
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO strangematic_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO strangematic_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO strangematic_user;

-- List databases để verify
\l

-- List users để verify
\du

-- Show current database
SELECT current_database();

-- Success message
SELECT 'Database setup completed successfully for strangematic.com n8n instance' AS status;
