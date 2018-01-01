#!/bin/bash
set -u
set -e

echo "[*] Cleaning up temporary data directories"
rm -rf qdata/
rm -f start_#nodeName#.sh
rm -f #nodeName#.conf

echo "[*] Configuring #nodeName# node"
mkdir -p qdata/logs
mkdir -p qdata/keystore
if [ -f "keys/#nodeName#BM" ]
then
    cp keys/#nodeName#BM qdata/keystore
fi

if [ -f "keys/#nodeName#V" ]
then
    cp keys/#nodeName#V qdata/keystore
fi
geth --datadir qdata init genesis.json

echo "[*] Updating configuration files"
cp setup/start_#nodeName#.sh start_#nodeName#.sh
cp setup/#nodeName#.conf #nodeName#.conf

THIS_IP="$(ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')"
PATTERN="s/##nodeName#_ip#/$THIS_IP/g"

sed -i $PATTERN start_#nodeName#.sh
sed -i $PATTERN #nodeName#.conf

chmod +x start_#nodeName#.sh

