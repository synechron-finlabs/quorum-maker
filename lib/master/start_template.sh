#!/bin/bash

source qm.variables
source node/common.sh

# if setup.conf available read from file to create a network
function readFromFile(){
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
    nodeName=$var

    var="$(grep -F -m 1 'PUBKEY=' $1)"; var="${var#*=}"
    publickey=$var

    var="$(grep -F -m 1 'ROLE=' $1)"; var="${var#*=}"
    role=$var

    var="$(grep -F -m 1 'NETWORK_ID=' $1)"; var="${var#*=}"
    networkId=$var
}

# docker command to create a network
function startNode(){
    docker run -it --rm --name $nodeName -v $(pwd):/home  -w /${PWD##*}/home/node  \
           -p $rPort:$rPort -p $wPort:$wPort -p $wPort:$wPort/udp -p $cPort:$cPort -p $raPort:$raPort -p $tgoPort:$tgoPort \
           -e CURRENT_NODE_IP=$pCurrentIp \
           -e R_PORT=$rPort \
           -e W_PORT=$wPort \
           -e C_PORT=$cPort \
	       -e RA_PORT=$raPort \
           $dockerImage ./start_${nodeName}.sh
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
