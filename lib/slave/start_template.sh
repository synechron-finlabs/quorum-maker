#!/bin/bash

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

    var="$(grep -F -m 1 'MASTER_IP=' $1)"; var="${var#*=}"
    mainIp=$var

    var="$(grep -F -m 1 'MAIN_NODEMANAGER_PORT=' $1)"; var="${var#*=}"
    mgoPort=$var

    var="$(grep -F -m 1 'NODENAME=' $1)"; var="${var#*=}"
    node=$var

    var="$(grep -F -m 1 'PUBKEY=' $1)"; var="${var#*=}"
    publickey=$var

    var="$(grep -F -m 1 'NETWORK_ID=' $1)"; var="${var#*=}"
    networkId=$var

    
        
}

# docker command to join th network 
function startNode(){
    docker run -it --rm --name $node -v $(pwd):/home  -w /${PWD##*}/home/node  \
           -p $rPort:$rPort -p $wPort:$wPort -p $wPort:$wPort/udp -p $cPort:$cPort -p $raPort:$raPort -p $tgoPort:$tgoPort\
           -e CURRENT_NODE_IP=$pCurrentIp \
           -e R_PORT=$rPort \
           -e W_PORT=$wPort \
           -e C_PORT=$cPort \
           -e RA_PORT=$raPort \
           -e NM_PORT=$tgoPort \
           $dockerImage ./#start_cmd#
}

function main(){
    
    docker run -it --rm -v $(pwd):/home  -w /${PWD##*}/home  \
              $dockerImage node/pre_start_check.sh

    readFromFile setup.conf

    if [ -z $networkId ]; then
        exit
    fi

    uiUrl="http://localhost:"$tgoPort"/"

    echo -e '****************************************************************************************************************'

    echo -e '\e[1;32mSuccessfully created and started \e[0m'$node
    echo -e '\e[1;32mYou can send transactions to \e[0m'$pCurrentIp:$rPort
    echo -e '\e[1;32mFor private transactions, use \e[0m'$publickey
    echo -e '\e[1;32mFor accessing Quorum Maker UI, please open the following from a web browser \e[0m'$uiUrl
    echo -e '\e[1;32mTo join this node from a different host, please run Quorum Maker and choose option to run Join Network\e[0m'
    echo -e '\e[1;32mWhen asked, enter \e[0m'$pCurrentIp '\e[1;32mfor Existing Node IP and \e[0m'$tgoPort '\e[1;32mfor Node Manager port\e[0m'

    echo -e '****************************************************************************************************************'

    startNode
}
main
