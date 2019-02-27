#!/bin/bash

function upcheck() {
    DOWN=true
    k=10
    while ${DOWN}; do
        sleep 1
        DOWN=false
        
        if [ ! -S "qdata/${NODE_NAME}.ipc" ]; then
            echo "Node is not yet listening on ${NODE_NAME}.ipc" >> qdata/gethLogs/${NODE_NAME}.log
            DOWN=true
        fi

        result=$(curl -s http://$CURRENT_NODE_IP:$C_PORT/upcheck)

        if [ ! "${result}" == "I'm up!" ]; then
            echo "Node is not yet listening on http" >> qdata/gethLogs/${NODE_NAME}.log
            DOWN=true
        fi
    
        k=$((k - 1))
        if [ ${k} -le 0 ]; then
            echo "Constellation/Tessera is taking a long time to start.  Look at the Constellation/Tessera logs for help diagnosing the problem." >> qdata/gethLogs/${NODE_NAME}.log
        fi
       
        sleep 5
    done
}

ENABLED_API="admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,raft"
GLOBAL_ARGS="--raft --nodiscover --gcmode=archive --networkid $NETID --rpc --rpcaddr 0.0.0.0 --rpcapi $ENABLED_API --emitcheckpoints"

tessera="java -jar /tessera/tessera-app.jar"

echo "[*] Starting Constellation node" > qdata/constellationLogs/constellation_${NODE_NAME}.log

constellation-node ${NODE_NAME}.conf >> qdata/constellationLogs/constellation_${NODE_NAME}.log 2>&1 &

upcheck

echo "[*] Starting ${NODE_NAME} node" >> qdata/gethLogs/${NODE_NAME}.log
echo "[*] geth --verbosity 6 --datadir qdata" $GLOBAL_ARGS" --raftport $RA_PORT --rpcport "$R_PORT "--port "$W_PORT "--nat extip:"$CURRENT_NODE_IP>> qdata/gethLogs/${NODE_NAME}.log

PRIVATE_CONFIG=qdata/$NODE_NAME.ipc geth --verbosity 6 --datadir qdata $GLOBAL_ARGS --rpccorsdomain "*" --raftport $RA_PORT --rpcport $R_PORT --port $W_PORT --ws --wsaddr 0.0.0.0 --wsport $WS_PORT --wsorigins '*' --wsapi $ENABLED_API --nat extip:$CURRENT_NODE_IP 2>>qdata/gethLogs/${NODE_NAME}.log &

./nodemanager.sh $R_PORT $NODE_MANAGER_PORT
