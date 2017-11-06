#!/bin/bash
set -u
set -e

echo "[*] Cleaning up temporary data directories"
rm -rf qdata/
#rm -f start_node1.sh
#rm -f node1.conf

echo "[*] Configuring node1 node"
mkdir -p qdata/logs
mkdir -p qdata/keystore
if [ -f "keys/node1BM" ]
then
    cp keys/node1BM qdata/keystore
fi

if [ -f "keys/node1V" ]
then
    cp keys/node1V qdata/keystore
fi
geth --datadir qdata init genesis.json

echo "[*] Updating configuration files"
#cp ./start_raft1.sh start_raft.sh
#cp ./nodeTest.conf node1.conf

THIS_IP="$(ifconfig enp2s0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')"
PATTERN="s/#node1_ip#/$THIS_IP/g"

sed -i $PATTERN start_raft.sh
sed -i $PATTERN node1.conf

chmod +x start_raft.sh

MASTER_IP="$(ifconfig enp2s0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')"
PATTERN="s/#master_ip#/$MASTER_IP/g"
sed -i  $PATTERN start_raft.sh
sed -i  $PATTERN node1.conf
