#!/bin/bash
set -u
set -e
NETID=#networkId#
RAFTID=#raftId#

GLOBAL_ARGS="--raft --nodiscover --networkid $NETID --raftjoinexisting $RAFTID --rpc --rpcaddr 0.0.0.0 --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum --emitcheckpoints"

echo "[*] Starting Constellation node" > qdata/logs/constellation_#sNode#.log

constellation-node #sNode#.conf 2>> qdata/logs/constellation_#sNode#.log &
sleep 1

echo "[*] Starting #sNode# node" >> qdata/logs/#sNode#.log
echo "[*] geth --verbosity 6 --datadir qdata" $GLOBAL_ARGS" --raftport $RA_PORT --rpcport "$R_PORT "--port "$W_PORT "--nat extip:"$CURRENT_NODE_IP>> qdata/logs/sNode1.log

PRIVATE_CONFIG=#sNode#.conf geth --verbosity 6 --datadir qdata $GLOBAL_ARGS --raftport $RA_PORT --rpcport $R_PORT --port $W_PORT --nat extip:$CURRENT_NODE_IP 2>>qdata/logs/#sNode#.log 

