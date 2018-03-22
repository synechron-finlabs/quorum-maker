#!/bin/bash
set -u
set -e
NETID=#network_Id_value#
RA_PORT=#raftPort#

GLOBAL_ARGS="--raft --nodiscover --networkid $NETID --rpc --rpcaddr 0.0.0.0 --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,raft --emitcheckpoints"

echo "[*] Starting Constellation node" > qdata/logs/constellation_#mNode#.log

constellation-node #mNode#.conf 2>> qdata/logs/constellation_#mNode#.log &
sleep 1

echo "[*] Starting #mNode# node" >> qdata/logs/#mNode#.log
echo "[*] geth --verbosity 6 --datadir qdata" $GLOBAL_ARGS" --raftport $RA_PORT --rpcport "$R_PORT "--port "$W_PORT "--nat extip:"$CURRENT_NODE_IP>> qdata/logs/#mNode#.log

PRIVATE_CONFIG=qdata/master.ipc geth --verbosity 6 --datadir qdata $GLOBAL_ARGS --raftport $RA_PORT --rpcport $R_PORT --port $W_PORT --nat extip:$CURRENT_NODE_IP 2>>qdata/logs/#mNode#.log &

echo "inside go service"
./nodemanager.sh

