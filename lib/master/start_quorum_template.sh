#!/bin/bash
set -u
set -e

GLOBAL_ARGS="--raft --nodiscover --networkid $NETID --rpc --rpcaddr 0.0.0.0 --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,raft --emitcheckpoints"

echo "[*] Starting Constellation node" > qdata/constellationLogs/constellation_${NODE_NAME}.log

constellation-node constellation.conf >> qdata/constellationLogs/constellation_${NODE_NAME}.log 2>&1 &

# Fix to wait till ipc file get generated
while : ; do
    
    sleep 1

    re="$NODE_NAME.ipc"
	enodestr=$(ls -al qdata)
    
    if [[ $enodestr =~ $re ]];then
        break;
    fi

done

echo "[*] Starting ${NODE_NAME} node" >> qdata/gethLogs/${NODE_NAME}.log
echo "[*] geth --verbosity 6 --datadir qdata" $GLOBAL_ARGS" --raftport $RA_PORT --rpcport "$R_PORT "--port "$W_PORT "--nat extip:"$CURRENT_NODE_IP>> qdata/gethLogs/${NODE_NAME}.log

PRIVATE_CONFIG=qdata/$NODE_NAME.ipc geth --verbosity 6 --datadir qdata $GLOBAL_ARGS --rpccorsdomain "*" --raftport $RA_PORT --rpcport $R_PORT --port $W_PORT --ws --wsaddr 0.0.0.0 --wsport $WS_PORT --wsorigins '*' --wsapi --nat extip:$CURRENT_NODE_IP 2>>qdata/gethLogs/${NODE_NAME}.log &

./nodemanager.sh $R_PORT $NODE_MANAGER_PORT
