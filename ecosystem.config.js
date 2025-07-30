// PM2 Ecosystem Configuration cho strangematic.com
// Production-ready n8n automation hub

module.exports = {
	apps: [
		{
			name: 'strangematic-hub',
			script: 'node',
			args: 'packages/cli/bin/n8n',
			cwd: 'C:/Github/n8n-tp',

			// Environment Configuration
			env: {
				NODE_ENV: 'production',
				N8N_EDITOR_BASE_URL: 'https://app.strangematic.com',
				WEBHOOK_URL: 'https://api.strangematic.com',
				N8N_HOST: 'app.strangematic.com',
				N8N_PROTOCOL: 'https',
				N8N_PORT: 5678,

				// Database Connection
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

				// Performance - Dell OptiPlex 3060 Optimization
				N8N_EXECUTIONS_PROCESS: 'main',
				N8N_CONCURRENCY: 4,
				N8N_EXECUTIONS_TIMEOUT: 3600,
				N8N_EXECUTIONS_TIMEOUT_MAX: 7200,

				// Logging
				N8N_LOG_LEVEL: 'info',
				N8N_LOG_OUTPUT: 'file',
				N8N_LOG_FILE_LOCATION: 'C:/Github/n8n-tp/logs/',

				// Webhook Configuration
				N8N_PATH: '/',
				N8N_LISTEN_ADDRESS: '0.0.0.0',
				N8N_BASIC_AUTH_ACTIVE: 'false',
			},

			// PM2 Configuration
			instances: 1,
			autorestart: true,
			watch: false,
			max_memory_restart: '2G',
			restart_delay: 5000,
			exec_mode: 'fork',

			// Logging Configuration
			log_file: 'C:/Github/n8n-tp/logs/strangematic-combined.log',
			out_file: 'C:/Github/n8n-tp/logs/strangematic-out.log',
			error_file: 'C:/Github/n8n-tp/logs/strangematic-error.log',
			log_date_format: 'YYYY-MM-DD HH:mm:ss Z',

			// Monitoring
			pmx: true,
			min_uptime: '60s',
			max_restarts: 10,

			// Windows Service Configuration
			windowsHide: true,

			// Health Check
			health_check_grace_period: 30000,

			// Production Environment Variables
			env: {
				NODE_ENV: 'production',
			},
		},
	],

	// PM2 Global Settings
	deploy: {
		production: {
			user: 'NODE',
			host: 'localhost',
			ref: 'origin/main',
			repo: 'https://github.com/n8n-io/n8n.git',
			path: 'C:/Github/n8n-tp',
			'pre-deploy-local': '',
			'post-deploy': 'npm install && pm2 reload ecosystem.config.js --env production',
			'pre-setup': '',
		},
	},
};
