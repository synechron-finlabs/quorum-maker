#!/bin/bash
set -u
set -e
NETID=87234

mkdir -p qdata/logs
CORE_NODE_IP=10.34.15.42

GLOBAL_ARGS="--raft --nodiscover --networkid $NETID --rpc --rpcaddr 0.0.0.0 --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum"

echo "[*] Starting Constellation node" > qdata/logs/constellation_#nodename#.log

PATTERN="s/CORE_NODE_IP/${CORE_NODE_IP}/g"

sed -i "$PATTERN" #nodename#.conf

constellation-node #nodename#.conf 2> qdata/logs/constellation_#nodename#.log &
sleep 1

echo "[*] Starting #nodename# node" >> qdata/logs/#nodename#.log

PRIVATE_CONFIG=#nodename#.conf geth --verbosity 6 --datadir qdata $GLOBAL_ARGS --rpcport 22000 --port 21000 --nat extip:$CORE_NODE_IP 2>>qdata/logs/#nodename#.log 
