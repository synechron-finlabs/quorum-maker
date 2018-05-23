#!/bin/bash
set -u
set -e
NETID=#network_Id_value#
RA_PORT=#raftPort#
RA_PORT=ra_Port
R_PORT=r_Port
W_PORT=w_Port
CURRENT_NODE_IP=nodeIp
NODE_MANAGER_PORT=nm_Port
process=""

GLOBAL_ARGS="--raft --nodiscover --networkid $NETID --rpc --rpcaddr 0.0.0.0 --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,raft --emitcheckpoints"

echo "[*] Starting Constellation node" > qdata/constellationLogs/constellation_#mNode#.log

constellation-node #mNode#.conf 2>> qdata/constellationLogs/constellation_#mNode#.log &
sleep 1

echo "[*] Starting #mNode# node" >> qdata/gethLogs/#mNode#.log
echo "[*] geth --verbosity 6 --datadir qdata" $GLOBAL_ARGS" --raftport $RA_PORT --rpcport "$R_PORT "--port "$W_PORT "--nat extip:"$CURRENT_NODE_IP>> qdata/gethLogs/#mNode#.log

PRIVATE_CONFIG=qdata/master.ipc geth --verbosity 6 --datadir qdata $GLOBAL_ARGS --raftport $RA_PORT --rpcport $R_PORT --port $W_PORT --nat extip:$CURRENT_NODE_IP 2>>qdata/gethLogs/#mNode#.log &

echo "inside go service"
process=$(ps -ef | grep $NODE_MANAGER_PORT |grep NodeManagerGo| awk '{print $2}')
if [  -z "$process" ]; then
./nodemanager.sh
fi
