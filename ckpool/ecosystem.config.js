module.exports = {
  apps: [{
    name: 'ckpool-btc',
    script: '/home/eduard/bitcoin/ckpool/src/ckpool',
    args: '-c /home/eduard/bitcoin/ckpool/ckpool.conf -n ckpool-btc',
    interpreter: 'none',
    autorestart: true,
    restart_delay: 5000,
    log_type: 'json'
  }]
}
