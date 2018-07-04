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

    var="$(grep -F -m 1 'MASTER_CONSTELLATION_PORT=' $1)"; var="${var#*=}"
    mcPort=$var
    
    var="$(grep -F -m 1 'RAFT_PORT=' $1)"; var="${var#*=}"
    raPort=$var
    
    var="$(grep -F -m 1 'THIS_NODEMANAGER_PORT=' $1)"; var="${var#*=}"
    tgoPort=$var

    var="$(grep -F -m 1 'MASTER_IP=' $1)"; var="${var#*=}"
    mainIp=$var

    var="$(grep -F -m 1 'MAIN_NODEMANAGER_PORT=' $1)"; var="${var#*=}"
    mgoPort=$var

    var="$(grep -F -m 1 'PUBKEY=' $1)"; var="${var#*=}"
    publickey=$var

    var="$(grep -F -m 1 'NETWORK_ID=' $1)"; var="${var#*=}"
    networkId=$var

    var="$(grep -F -m 1 'RAFT_ID=' $1)"; var="${var#*=}"
    raftId=$var
        
}

# docker command to join th network 
function startNode(){

    docker kill $node 2> /dev/null && docker rm $node 2> /dev/null

    docker run -it --rm --name $node \
           -v $(pwd):/home \
           -v $(pwd)/node/contracts:/root/quorum-maker/contracts \
           -w /home/node  \
           -p $rPort:$rPort \
           -p $wPort:$wPort \
           -p $wPort:$wPort/udp \
           -p $cPort:$cPort \
           -p $raPort:$raPort \
           -p $tgoPort:$tgoPort\
           -e NODENAME=$node \
           -e CURRENT_NODE_IP=$pCurrentIp \
           -e R_PORT=$rPort \
           -e W_PORT=$wPort \
           -e C_PORT=$cPort \
           -e RA_PORT=$raPort \
           -e NM_PORT=$tgoPort \
           -e NETID=$networkId \
           -e RAFTID=$raftId \
           -e MASTER_IP=$mainIp \
           -e MC_PORT=$mcPort \
           $dockerImage ./start_$node.sh
}

function main(){
    
    docker run -it --rm -v $(pwd):/home  -w /${PWD##*}/home  \
              $dockerImage node/pre_start_check.sh

    readFromFile setup.conf

    if [ -z $networkId ]; then
        exit
    fi

    startNode
}
main
