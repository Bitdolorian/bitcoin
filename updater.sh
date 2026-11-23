#!/bin/bash
cd ~/bitcoin || exit 1
pm2 stop bitcoin && ./updater.sh -d ~ -n bitcoin -s && pm2 start bitcoin   
