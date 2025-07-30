// PM2 Configuration - FIXED for AI Agent
// Direct node execution to avoid npm.cmd issues

module.exports = {
	apps: [
		{
			name: 'strangematic-hub',
			script: 'packages/cli/bin/n8n',
			interpreter: 'node',
			cwd: process.cwd(),

			// Environment Variables
			env: {
				NODE_ENV: 'production',
				N8N_EDITOR_BASE_URL: 'https://app.strangematic.com',
				WEBHOOK_URL: 'https://api.strangematic.com',
				N8N_HOST: 'app.strangematic.com',
				N8N_PROTOCOL: 'https',
				N8N_PORT: 5678,

				// Database
				DB_TYPE: 'postgresdb',
				DB_POSTGRESDB_HOST: 'localhost',
				DB_POSTGRESDB_PORT: 5432,
				DB_POSTGRESDB_DATABASE: 'strangematic_n8n',
				DB_POSTGRESDB_USER: 'strangematic_user',
				DB_POSTGRESDB_PASSWORD: 'strangematic_2024_secure!',

				// Security
				N8N_SECURE_COOKIE: 'true',
				N8N_JWT_SECRET: 'strangematic_jwt_secret_2024_ultra_secure_key_for_authentication',
				N8N_ENCRYPTION_KEY: 'strangematic_encryption_key_2024_ultra_secure_for_data_protection',

				// Performance
				N8N_EXECUTIONS_PROCESS: 'main',
				N8N_CONCURRENCY: 3,
				N8N_EXECUTIONS_TIMEOUT: 3600,
				N8N_EXECUTIONS_TIMEOUT_MAX: 7200,

				// Logging
				N8N_LOG_LEVEL: 'info',
				N8N_LOG_OUTPUT: 'console',

				// Network
				N8N_PATH: '/',
				N8N_LISTEN_ADDRESS: '0.0.0.0',
				N8N_BASIC_AUTH_ACTIVE: 'false',

				// Task Runners
				N8N_RUNNERS_ENABLED: 'true',
			},

			// PM2 Settings
			instances: 1,
			exec_mode: 'fork',
			autorestart: true,
			watch: false,
			max_memory_restart: '2G',
			restart_delay: 4000,

			// Process Management
			kill_timeout: 5000,
			min_uptime: '10s',
			max_restarts: 10,

			// Logging (simplified)
			merge_logs: true,

			// Windows
			windowsHide: true,
		},
	],
};
