#!/bin/bash
set -u
set -e
NETID=87234

mkdir -p qdata/logs
CORE_NODE_IP="$(ifconfig enp2s0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')"

GLOBAL_ARGS="--raft --nodiscover --networkid $NETID --rpc --rpcaddr 0.0.0.0 --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum"

echo "[*] Starting Constellation node" > qdata/logs/constellation_node1.log

#cp qdata/node1.conf .

PATTERN="s/CORE_NODE_IP/${CORE_NODE_IP}/g"

sed -i "$PATTERN" node1.conf

constellation-node node1.conf 2> qdata/logs/constellation_node1.log &
sleep 1

echo "[*] Starting node1 node" >> qdata/logs/node1.log

PRIVATE_CONFIG=node1.conf geth --verbosity 6 --datadir qdata $GLOBAL_ARGS --rpcport 22000 --port 21000 --nat extip:$CORE_NODE_IP 2>>qdata/logs/node1.log 
