module.exports = {
  apps: [
    {
      name: "bitcoin",
      // Correct path to the IPC-enabled binary
      script: "/home/YOUR PATH/bitcoin/libexec/bitcoin-node", 
      args: "-conf=/home/YOUR PATH/bitcoin/data/bitcoin.conf -datadir=/home/YOUR PATH/bitcoin/data -ipcbind=unix",
      cwd: "/home/YOUR PATH/bitcoin",
      env: {
        NODE_ENV: "production"
      }
    }
  ]
};   
