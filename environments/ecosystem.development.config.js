// =================================================================
// PM2 Development Configuration
// =================================================================

module.exports = {
  apps: [{
    name: 'strangematic-dev',
    script: '../packages/cli/bin/n8n',
    cwd: 'D:/Github/n8n-tp',

    // Environment Configuration
    env: {
      NODE_ENV: 'development',
      N8N_PORT: 5679,
      N8N_EDITOR_BASE_URL: 'http://localhost:5679',
      WEBHOOK_URL: 'http://localhost:5679'
    },

    // Performance Configuration - Conservative for Development
    instances: 1,
    exec_mode: 'fork',
    max_memory_restart: '1G',
    min_uptime: '5s',
    max_restarts: 5,
    autorestart: true,
    restart_delay: 2000,

    // Logging Configuration
    log_file: './logs/strangematic-dev.log',
    error_file: './logs/strangematic-dev-error.log',
    out_file: './logs/strangematic-dev-out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true,

    // Development Features
    watch: true,
    watch_delay: 1000,
    ignore_watch: [
      'node_modules',
      'logs',
      '.git',
      'dist',
      'build',
      'environments'
    ],

    // Environment file loading
    env_file: './environments/.env.development',

    // Process management
    kill_timeout: 3000,
    listen_timeout: 5000,

    // Development health check
    health_check_url: 'http://localhost:5679/healthz',
    health_check_grace_period: 5000
  }]
};
