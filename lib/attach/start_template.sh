#!/bin/bash

source qm.variables
source node/common.sh
    
function readFromFile(){
    var="$(grep -F -m 1 'NODENAME=' $1)"; var="${var#*=}"
    node=$var

    var="$(grep -F -m 1 'CURRENT_IP=' $1)"; var="${var#*=}"
    pCurrentIp=$var

    var="$(grep -F -m 1 'RPC_PORT=' $1)"; var="${var#*=}"
    rPort=$var
    
    var="$(grep -F -m 1 'WHISPER_PORT=' $1)"; var="${var#*=}"
    wPort=$var
    
    var="$(grep -F -m 1 'CONSTELLATION_PORT=' $1)"; var="${var#*=}"
    cPort=$var
    
    var="$(grep -F -m 1 'RAFT_PORT=' $1)"; var="${var#*=}"
    raPort=$var
    
    var="$(grep -F -m 1 'THIS_NODEMANAGER_PORT=' $1)"; var="${var#*=}"
    tgoPort=$var

    var="$(grep -F -m 1 'NODENAME=' $1)"; var="${var#*=}"
    node=$var

    var="$(grep -F -m 1 'PUBKEY=' $1)"; var="${var#*=}"
    publickey=$var
        
}

# docker command to join th network 
function startNode(){
    docker run -it --rm --name $node \
           -v $(pwd):/home \
           -v $(pwd)/node/contracts:/root/quorum-maker/contracts \
           -w /home/node  \
           -p $tgoPort:$tgoPort\
           -e CURRENT_NODE_IP=$pCurrentIp \
           -e R_PORT=$rPort \
           -e NM_PORT=$tgoPort \
           $dockerImage ./start_$node.sh
}

function main(){
    readFromFile setup.conf
    startNode
}
main
