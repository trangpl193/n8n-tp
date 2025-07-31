-- Setup Development Database for n8n
-- Run: "C:\Program Files\PostgreSQL\17\bin\psql.exe" -U postgres -h localhost -p 5432 -f setup-dev-database.sql

-- Create development database
CREATE DATABASE strangematic_n8n_dev;

-- Create development user with secure password
CREATE USER strangematic_dev WITH PASSWORD 'dev_secure_2024!';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE strangematic_n8n_dev TO strangematic_dev;

-- Connect to dev database and grant schema privileges
\c strangematic_n8n_dev

-- Grant schema permissions
GRANT ALL ON SCHEMA public TO strangematic_dev;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO strangematic_dev;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO strangematic_dev;

-- Verify setup
SELECT datname FROM pg_database WHERE datname = 'strangematic_n8n_dev';
SELECT usename FROM pg_user WHERE usename = 'strangematic_dev';

\echo 'Development database setup completed successfully!'
