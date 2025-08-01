// PM2 Ecosystem - AI Agent Safe Configuration
// Optimized để prevent terminal hanging và stuck commands

module.exports = {
	apps: [
		{
			name: 'strangematic-hub',
			script: 'node',
			args: 'packages/cli/bin/n8n',
			cwd: process.cwd(),

			// Environment
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
				DB_POSTGRESDB_PASSWORD: 'postgres123',

				// Security
				N8N_SECURE_COOKIE: 'true',
				N8N_JWT_SECRET: 'strangematic_jwt_secret_2024_ultra_secure_key_for_authentication',
				N8N_ENCRYPTION_KEY: 'strangematic_encryption_key_2024_ultra_secure_for_data_protection',

				// Performance (AI Agent Safe)
				N8N_EXECUTIONS_PROCESS: 'main',
				N8N_CONCURRENCY: 2, // Reduced để prevent overload
				N8N_EXECUTIONS_TIMEOUT: 1800, // 30 minutes
				N8N_EXECUTIONS_TIMEOUT_MAX: 3600, // 1 hour

				// Logging (Minimal để prevent log conflicts)
				N8N_LOG_LEVEL: 'warn',
				N8N_LOG_OUTPUT: 'file',
				N8N_LOG_FILE_LOCATION: './logs/',

				// Network
				N8N_PATH: '/',
				N8N_LISTEN_ADDRESS: '0.0.0.0',
				N8N_BASIC_AUTH_ACTIVE: 'false',
				
				// Cloudflare Tunnel Support
				N8N_PROXY_HOPS: '1',
				N8N_TRUST_PROXY: 'true',

				// Stability
				N8N_RUNNERS_ENABLED: 'true', // Enable task runners
			},

			// PM2 Configuration (AI Agent Optimized)
			instances: 1,
			exec_mode: 'fork', // More stable than cluster
			autorestart: true,
			watch: false,
			max_memory_restart: '1G', // Lower memory limit
			restart_delay: 3000, // Shorter restart delay

			// Graceful shutdown
			kill_timeout: 5000,
			wait_ready: true,
			listen_timeout: 10000,

			// Logging (Controlled output)
			log_file: './logs/pm2-combined.log',
			out_file: './logs/pm2-out.log',
			error_file: './logs/pm2-error.log',
			log_date_format: 'YYYY-MM-DD HH:mm:ss',
			merge_logs: true,

			// Monitoring
			pmx: false, // Disable PMX để reduce overhead
			automation: false,

			// Restart conditions (Conservative)
			min_uptime: '30s',
			max_restarts: 5, // Limit restarts

			// Health monitoring
			health_check_grace_period: 3000,

			// Windows specific
			windowsHide: true,

			// Environment specific
			node_args: ['--max-old-space-size=1024'], // Limit memory usage
		},
	],

	// Global PM2 settings
	deploy: {
		production: {
			user: 'NODE',
			host: 'localhost',
			ref: 'origin/develop',
			repo: '.',
			path: process.cwd(),
			'post-deploy': 'pm2 reload ecosystem-stable.config.js --env production',
		},
	},
};
