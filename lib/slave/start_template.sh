#!/bin/bash

source qm.variables
source node/common.sh

function startNode() {

    NODENAME=$NODENAME \
        CURRENT_NODE_IP=$CURRENT_IP \
        R_PORT=$RPC_PORT \
        W_PORT=$WHISPER_PORT \
        C_PORT=$CONSTELLATION_PORT \
        RA_PORT=$RAFT_PORT \
        NM_PORT=$THIS_NODEMANAGER_PORT \
        WS_PORT=$WS_PORT \
        NETID=$NETWORK_ID \
        RAFTID=$RAFT_ID \
        MASTER_IP=$MASTER_IP \
        MC_PORT=$MASTER_CONSTELLATION_PORT \
        ./start_$NODENAME.sh
}

function main() {

    node/pre_start_check.sh

    source setup.conf

    if [ -z $NETWORK_ID ]; then
        exit
    fi

    cd node
    
    startNode
}
main
