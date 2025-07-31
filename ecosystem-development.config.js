module.exports = {
  apps: [{
    name: 'strangematic-dev',
    script: './packages/cli/bin/n8n',
    cwd: 'C:/Github/n8n-tp',
    instances: 1,
    exec_mode: 'fork',
    watch: true,
    ignore_watch: ['node_modules', 'logs', '.git', 'cypress'],
    max_memory_restart: '1G',
    error_file: './logs/dev-error.log',
    out_file: './logs/dev-out.log',
    log_file: './logs/dev-combined.log',
    time: true,
    env: {
      NODE_ENV: 'development',
      N8N_PORT: 5679,
      DB_TYPE: 'postgresdb',
      DB_POSTGRESDB_HOST: 'localhost',
      DB_POSTGRESDB_PORT: 5432,
      DB_POSTGRESDB_DATABASE: 'strangematic_n8n_dev',
      DB_POSTGRESDB_USER: 'strangematic_dev',
      DB_POSTGRESDB_PASSWORD: 'dev_secure_2024!',
      N8N_BASIC_AUTH_ACTIVE: 'false',
      N8N_HOST: 'localhost',
      N8N_PROTOCOL: 'http',
      WEBHOOK_URL: 'http://localhost:5679'
    },
    autorestart: true,
    restart_delay: 1000,
    max_restarts: 5
  }]
}
