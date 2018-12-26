#!/bin/bash

function upcheck() {
    DOWN=true
    k=10
    while ${DOWN}; do
        sleep 1
        DOWN=false
        
        if [ ! -S "qdata/${NODENAME}.ipc" ]; then
            echo "Node is not yet listening on ${NODENAME}.ipc" >> qdata/gethLogs/${NODENAME}.log
            DOWN=true
        fi

        result=$(curl -s http://$CURRENT_NODE_IP:$C_PORT/upcheck)

        if [ ! "${result}" == "I'm up!" ]; then
            echo "Node is not yet listening on http" >> qdata/gethLogs/${NODENAME}.log
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
GLOBAL_ARGS="--raft --nodiscover --networkid $NETID --raftjoinexisting $RAFTID  --rpc --rpcaddr 0.0.0.0 --rpcapi $ENABLED_API --emitcheckpoints"

tessera="java -jar /tessera/tessera-app.jar"

echo "[*] Starting Constellation node" > qdata/constellationLogs/constellation_${NODENAME}.log

constellation-node ${NODENAME}.conf >> qdata/constellationLogs/constellation_${NODENAME}.log 2>&1 &

upcheck

echo "[*] Starting ${NODENAME} node" >> qdata/gethLogs/${NODENAME}.log
echo "[*] geth --verbosity 6 --datadir qdata --raft --nodiscover --networkid $NETID --raftjoinexisting $RAFTID --rpc --rpcaddr 0.0.0.0 --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,raft --emitcheckpoints --raftport $RA_PORT --rpcport $R_PORT --port $W_PORT --nat extip:$CURRENT_NODE_IP">> qdata/gethLogs/${NODENAME}.log

PRIVATE_CONFIG=qdata/$NODENAME.ipc geth --verbosity 6 --datadir qdata $GLOBAL_ARGS --rpccorsdomain "*" --raftport $RA_PORT --rpcport $R_PORT --port $W_PORT --ws --wsaddr 0.0.0.0 --wsport $WS_PORT --wsorigins '*' --wsapi $ENABLED_API --nat extip:$CURRENT_NODE_IP 2>>qdata/gethLogs/${NODENAME}.log &

cd /root/quorum-maker/
./start_nodemanager.sh $R_PORT $NM_PORT
