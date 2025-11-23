module.exports = {
  apps: [{
    name: 'devops-pipeline',
    script: './src/index.js',

    // Modo cluster para aprovechar todos los cores
    instances: 'max',
    exec_mode: 'cluster',

    // Variables de entorno
    env: {
      NODE_ENV: 'development',
      PORT: 3000
    },
    env_production: {
      NODE_ENV: 'production',
      PORT: 3000
    },

    // Logs
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true,
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',

    // Reinicio automático
    autorestart: true,
    max_memory_restart: '500M',
    max_restarts: 10,
    min_uptime: '10s',

    // Watch (solo desarrollo)
    watch: false,
    ignore_watch: ['node_modules', 'logs', '.git'],

    // Otras configuraciones
    merge_logs: true,

    // Configuración de cron para restart (opcional)
    // cron_restart: '0 0 * * *', // Reiniciar cada día a medianoche

    // Variables de entorno específicas
    env_staging: {
      NODE_ENV: 'staging',
      PORT: 3001
    }
  }],

  // Configuración de deploy (opcional)
  deploy: {
    production: {
      user: 'appuser',
      host: 'localhost',
      ref: 'origin/master',
      repo: 'https://github.com/sntramirez/devops-pipeline.git',
      path: '/opt/devops-pipeline',
      'post-deploy': 'npm ci --production && pm2 reload ecosystem.config.js --env production',
      'pre-deploy-local': '',
      'post-deploy-local': ''
    },
    staging: {
      user: 'appuser',
      host: 'localhost',
      ref: 'origin/develop',
      repo: 'https://github.com/sntramirez/devops-pipeline.git',
      path: '/opt/devops-pipeline-staging',
      'post-deploy': 'npm ci && pm2 reload ecosystem.config.js --env staging',
      'pre-deploy-local': '',
      'post-deploy-local': ''
    }
  }
};
