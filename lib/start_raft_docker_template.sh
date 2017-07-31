#!/bin/bash
set -u
set -e

CORE_NODE_IP="$(dig +short $CORE_NODE_IP)"
CORE_MASTERNODE_IP="$(dig +short $CORE_MASTERNODE_IP)"

GLOBAL_ARGS="--raft --rpc --rpcaddr 0.0.0.0 --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum"

cp qdata/#nodeName#.conf .

PATTERN="s/CORE_NODE_IP/${CORE_NODE_IP}/g"
PATTERN2="s/CORE_MASTERNODE_IP/${CORE_MASTERNODE_IP}/g"

sed -i "$PATTERN" #nodeName#.conf
sed -i "$PATTERN2" #nodeName#.conf

echo "[*] Starting Constellation node"
constellation-node #nodeName#.conf 2> qdata/logs/constellation_#nodeName#.log &
sleep 1

echo "[*] Starting #nodeName# node"
PRIVATE_CONFIG=#nodeName#.conf nohup geth --datadir qdata $GLOBAL_ARGS --rpcport 22000 --port 21000 2>qdata/logs/#nodeName#.log

