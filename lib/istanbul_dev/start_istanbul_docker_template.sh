#!/bin/bash
set -u
set -e

CORE_NODE_IP="$(dig +short $CORE_NODE_IP)"
CORE_MASTERNODE_IP="$(dig +short $CORE_MASTERNODE_IP)"

GLOBAL_ARGS="--syncmode full --mine --rpc --rpcaddr 0.0.0.0 --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,istanbul"

cp qdata/#nodeName#.conf .

PATTERN="s/CORE_NODE_IP/${CORE_NODE_IP}/g"
PATTERN2="s/CORE_MASTERNODE_IP/${CORE_MASTERNODE_IP}/g"

sed -i "$PATTERN" #nodeName#.conf
sed -i "$PATTERN2" #nodeName#.conf

echo "[*] Starting Constellation on #nodeName#"
constellation-node #nodeName#.conf 2> qdata/logs/constellation_#nodeName#.log &
sleep 1
echo "[*] Started Constellation on #nodeName#"


if [ -f /qdata/geth/nodekey ]; then
echo "present"
cat /qdata/geth/nodekey
fi

echo "[*] Starting Quorum on #nodeName#"
PRIVATE_CONFIG=qdata/#nodeName#.ipc geth --verbosity 6 --datadir qdata $GLOBAL_ARGS --rpcport 22000 --port 21000 2>qdata/logs/#nodeName#.log &

echo "[*] Started Quorum on #nodeName#"

while true 
do 
 sleep 5
done

