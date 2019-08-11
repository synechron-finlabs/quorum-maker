#!/bin/bash

source qm.variables
source node/common.sh

function startNode() {

    CURRENT_NODE_IP=$CURRENT_IP \
        R_PORT=$RPC_PORT \
        W_PORT=$WHISPER_PORT \
        C_PORT=$CONSTELLATION_PORT \
        RA_PORT=$RAFT_PORT \
        NODE_MANAGER_PORT=$THIS_NODEMANAGER_PORT \
        WS_PORT=$WS_PORT \
        NETID=$NETWORK_ID \
        NODE_NAME=$NODENAME \
        ./start_${NODENAME}.sh
}

function main() {

    node/pre_start_check.sh $@

    if [ -f setup.conf ]; then
        source setup.conf
    fi

    if [ -z $NETWORK_ID ]; then
        exit
    fi

    cd node
    startNode
}
main
