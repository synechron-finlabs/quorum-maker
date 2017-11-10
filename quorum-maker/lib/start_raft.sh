#!/bin/bash
set -u
set -e
NETID=87234

mkdir -p qdata/logs
CORE_NODE_IP="$(ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')"

GLOBAL_ARGS="--raft --nodiscover --networkid $NETID --rpc --rpcaddr 0.0.0.0 --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum"

echo "[*] Starting Constellation node" > qdata/logs/constellation_nodeCreate.log

PATTERN="s/CORE_NODE_IP/${CORE_NODE_IP}/g"

sed -i "$PATTERN" nodeCreate.conf

constellation-node nodeCreate.conf 2> qdata/logs/constellation_nodeCreate.log &
sleep 1

echo "[*] Starting nodeCreate node" >> qdata/logs/nodeCreate.log

PRIVATE_CONFIG=nodeCreate.conf geth --verbosity 6 --datadir qdata $GLOBAL_ARGS --rpcport 22000 --port 21000 --nat extip:$CORE_NODE_IP 2>>qdata/logs/nodeCreate.log 
