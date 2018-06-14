#!/bin/bash
set -u
set -e

NETID=#networkId#
RAFTID=#raftId#


GLOBAL_ARGS="--raft --nodiscover --networkid $NETID --raftjoinexisting $RAFTID  --rpc --rpcaddr 0.0.0.0 --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,raft --emitcheckpoints"

echo "[*] Starting Constellation node" > qdata/constellationLogs/constellation_#sNode#.log

constellation-node #sNode#.conf >> qdata/constellationLogs/constellation_#sNode#.log 2>&1 &
sleep 1

echo "[*] Starting #sNode# node" >> qdata/gethLogs/#sNode#.log
echo "[*] geth --verbosity 6 --datadir qdata --raft --nodiscover --networkid $NETID --raftjoinexisting $RAFTID --rpc --rpcaddr 0.0.0.0 --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,raft --emitcheckpoints --raftport $RA_PORT --rpcport $R_PORT --port $W_PORT --nat extip:$CURRENT_NODE_IP">> qdata/gethLogs/#sNode#.log

PRIVATE_CONFIG=qdata/slave.ipc geth --verbosity 6 --datadir qdata $GLOBAL_ARGS --raftport $RA_PORT --rpcport $R_PORT --port $W_PORT --nat extip:$CURRENT_NODE_IP 2>>qdata/gethLogs/#sNode#.log &

cd /root/quorum-maker/
./start_nodemanager.sh $R_PORT $NM_PORT
