#!/bin/bash

function readFromFile(){
    var="$(grep -F -m 1 'CURRENT_IP=' $1)"; var="${var#*=}"
    pCurrentIp=$var

    var="$(grep -F -m 1 'RPC_PORT=' $1)"; var="${var#*=}"
    rPort=$var
    
    var="$(grep -F -m 1 'WHISPER_PORT=' $1)"; var="${var#*=}"
    wPort=$var
    
    var="$(grep -F -m 1 'CONSTELLATION_PORT=' $1)"; var="${var#*=}"
    cPort=$var
    
    var="$(grep -F -m 1 'BOOTNODE_PORT=' $1)"; var="${var#*=}"
    bPort=$var
    pBootnodePort=$var
    
    var="$(grep -F -m 1 'MASTER_IP=' $1)"; var="${var#*=}"
    pMainIp=$var
    
    var="$(grep -F -m 1 'MASTER_CONSTELLATION_PORT=' $1)"; var="${var#*=}"
    pCPort=$var
}


function main(){
    
    let pMainIp=0
    let pBootnodePort=0
    let pCPort=0
    let bPort=0

    if [ -z "$1" ]; then
        FILE=setup.conf
    else
        FILE=$1
    fi

    if [ -f $FILE ]; then
        readFromFile $FILE
    else
        readInputs
    fi
    
    #docker command to run node inside docker usning startScript
    docker run -it -v $(pwd):/home  -w /${PWD##*}/home/node  \
           -p $rPort:$rPort -p $wPort:$wPort -p $wPort:$wPort/udp -p $cPort:$cPort \
           -e CURRENT_NODE_IP=$pCurrentIp \
           -e R_PORT=$rPort \
           -e W_PORT=$wPort \
           -e C_PORT=$cPort $B_PORT_VAR\
           -e MAIN_IP=$pMainIp \
           -e MJ_PORT=$mjPort \
           syneblock/quorum-master:quorum2.0.0 ./#start_cmd#
}

main $1
