module.exports = {
  apps: [
    {
      name: 'ckstats-btc',
      script: 'pnpm',
      args: 'start',
      interpreter: 'bash', // <--- Add this line
      instances: 1,
      exec_mode: 'fork',
      env_production: {
        NODE_ENV: 'production',
        PORT: 3000,
      },
    },
  ],
};   
