// =================================================================
// PM2 Production Configuration cho strangematic.com Hub
// =================================================================

module.exports = {
  apps: [{
    name: 'strangematic-prod',
    script: '../packages/cli/bin/n8n',
    cwd: 'D:/Github/n8n-tp',

    // Environment Configuration
    env: {
      NODE_ENV: 'production',
      N8N_PORT: 5678,
      N8N_EDITOR_BASE_URL: 'https://app.strangematic.com',
      WEBHOOK_URL: 'https://api.strangematic.com'
    },

    // Performance Configuration - Dell OptiPlex 3060 Optimized
    instances: 1,
    exec_mode: 'fork',
    max_memory_restart: '2G',
    min_uptime: '10s',
    max_restarts: 10,
    autorestart: true,
    restart_delay: 5000,

    // Logging Configuration
    log_file: './logs/strangematic-prod.log',
    error_file: './logs/strangematic-prod-error.log',
    out_file: './logs/strangematic-prod-out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true,

    // Monitoring
    watch: false,
    ignore_watch: ['node_modules', 'logs', '.git'],

    // Environment file loading
    env_file: './environments/.env.production',

    // Process management
    kill_timeout: 5000,
    listen_timeout: 10000,

    // Health monitoring
    health_check_url: 'http://localhost:5678/healthz',
    health_check_grace_period: 10000
  }]
};
