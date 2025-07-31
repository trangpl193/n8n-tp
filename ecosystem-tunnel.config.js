module.exports = {
  apps: [{
    name: 'cloudflared-tunnel',
    script: 'C:\\cloudflared\\cloudflared.exe',
    args: 'tunnel --config C:\\cloudflared\\config.yml run',
    cwd: 'C:\\cloudflared',
    instances: 1,
    exec_mode: 'fork',
    watch: false,
    ignore_watch: ['node_modules', 'logs'],
    max_memory_restart: '1G',
    error_file: './logs/cloudflared-error.log',
    out_file: './logs/cloudflared-out.log',
    log_file: './logs/cloudflared-combined.log',
    pid_file: './logs/cloudflared.pid',
    time: true,
    env: {
      NODE_ENV: 'production'
    },
    autorestart: true,
    restart_delay: 5000,
    max_restarts: 3
  }]
}
