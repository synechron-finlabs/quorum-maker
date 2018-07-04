#!/bin/bash

source qm.variables
source node/common.sh

# docker command to join th network 
function startNode(){
    
    docker kill $NODENAME 2> /dev/null && docker rm $NODENAME 2> /dev/null
    
    docker run -it --rm --name $NODENAME \
           -v $(pwd):/home \
           -v $(pwd)/node/contracts:/root/quorum-maker/contracts \
           -w /home/node  \
           -p $THIS_NODEMANAGER_PORT:$THIS_NODEMANAGER_PORT\
           -e CURRENT_NODE_IP=$CURRENT_IP \
           -e R_PORT=$RPC_PORT \
           -e NM_PORT=$THIS_NODEMANAGER_PORT \
           $dockerImage ./start_$NODENAME.sh
}

function main(){
    source setup.conf
    startNode
}
main
