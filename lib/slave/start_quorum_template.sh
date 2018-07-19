#!/bin/bash
set -u
set -e

GLOBAL_ARGS="--raft --nodiscover --networkid $NETID --raftjoinexisting $RAFTID  --rpc --rpcaddr 0.0.0.0 --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,raft --emitcheckpoints"

echo "[*] Starting Constellation node" > qdata/constellationLogs/constellation_${NODENAME}.log

constellation-node \
--url=http://$CURRENT_NODE_IP:$C_PORT/ \
--port=$C_PORT \
--workdir=qdata \
--socket=$NODENAME.ipc \
--publickeys=/home/node/keys/$NODENAME.pub \
--privatekeys=/home/node/keys/$NODENAME.key \
--tls=off \
--othernodes=http://$MASTER_IP:$MC_PORT/ >> qdata/constellationLogs/constellation_${NODENAME}.log 2>&1 &

# Fix to wait till ipc file get generated
while : ; do
    
    sleep 1

    re="$NODENAME.ipc"
	enodestr=$(ls -al qdata)
    
    if [[ $enodestr =~ $re ]];then
        break;
    fi

done

echo "[*] Starting ${NODENAME} node" >> qdata/gethLogs/${NODENAME}.log
echo "[*] geth --verbosity 6 --datadir qdata --raft --nodiscover --networkid $NETID --raftjoinexisting $RAFTID --rpc --rpcaddr 0.0.0.0 --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,raft --emitcheckpoints --raftport $RA_PORT --rpcport $R_PORT --port $W_PORT --nat extip:$CURRENT_NODE_IP">> qdata/gethLogs/${NODENAME}.log

PRIVATE_CONFIG=qdata/$NODENAME.ipc geth --verbosity 6 --datadir qdata $GLOBAL_ARGS --rpccorsdomain "*" --raftport $RA_PORT --rpcport $R_PORT --port $W_PORT --ws --wsaddr 0.0.0.0 --wsport $WS_PORT --wsorigins '*' --wsapi --nat extip:$CURRENT_NODE_IP 2>>qdata/gethLogs/${NODENAME}.log &

cd /root/quorum-maker/
./start_nodemanager.sh $R_PORT $NM_PORT
