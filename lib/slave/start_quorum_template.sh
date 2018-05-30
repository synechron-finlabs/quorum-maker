#!/bin/bash
set -u
set -e
NETID=#networkId#
RAFTID=#raftId#

RA_PORT=ra_Port
R_PORT=r_Port
W_PORT=w_Port
CURRENT_NODE_IP=nodeIp
NODE_MANAGER_PORT=nm_Port
process=""

GLOBAL_ARGS="--raft --nodiscover --networkid $NETID --raftjoinexisting $RAFTID  --rpc --rpcaddr 0.0.0.0 --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,raft --emitcheckpoints"

echo "[*] Starting Constellation node" > qdata/constellationLogs/constellation_#sNode#.log

constellation-node #sNode#.conf 2>> qdata/constellationLogs/constellation_#sNode#.log &
sleep 1

echo "[*] Starting #sNode# node" >> qdata/gethLogs/#sNode#.log
echo "[*] geth --verbosity 6 --datadir qdata" $GLOBAL_ARGS" --raftport $RA_PORT --rpcport "$R_PORT "--port "$W_PORT "--nat extip:"$CURRENT_NODE_IP>> qdata/gethLogs/#sNode#.log

PRIVATE_CONFIG=qdata/slave.ipc geth --verbosity 6 --datadir qdata $GLOBAL_ARGS --raftport $RA_PORT --rpcport $R_PORT --port $W_PORT --nat extip:$CURRENT_NODE_IP 2>>qdata/gethLogs/#sNode#.log &

./nodemanager.sh



