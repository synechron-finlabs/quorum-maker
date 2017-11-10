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

function readInputs(){
        
    read -p $'\e[1;31mPlease enter this node\' IP Address: \e[0m' pCurrentIp
    read -p $'\e[1;32mPlease enter this node\'s RPC Port: \e[0m' rPort
    read -p $'\e[1;32mPlease enter this node\'s Network Listening Port: \e[0m' wPort
    read -p $'\e[1;32mPlease enter this node\'s Constellation Port: \e[0m' cPort
    read -p $'\e[1;33mPlease enter main node IP Address: \e[0m' pMainIp
    read -p $'\e[1;35mPlease enter main java endpoint port: \e[0m' mjPort

    echo 'CURRENT_IP='$pCurrentIp >  ./nodeSetup.conf
	echo 'RPC_PORT='$rPort >>  ./nodeSetup.conf
	echo 'WHISPER_PORT='$wPort >>  ./nodeSetup.conf
	echo 'CONSTELLATION_PORT='$cPort >>  ./nodeSetup.conf
	echo 'MASTER_IP='$pMainIp >>  ./nodeSetup.conf
	echo 'MASTER_JAVA_PORT='$mjPort >>  ./nodeSetup.conf
}
function main(){
  
   readInputs
    
    docker run -d -it -v $(pwd)/$line:/${PWD##*/}  -w /${PWD##*}/#NODE_NAME#/node  \
           -p $rPort:$rPort -p $wPort:$wPort -p $wPort:$wPort/udp -p $cPort:$cPort \
           $B_PORT_MAPPING -e MAIN_NODE_IP=$pMainIp -e BOOTNODE_PORT=$pBootnodePort \
           -e MAIN_C_PORT=$pCPort -e CURRENT_NODE_IP=$pCurrentIp \
           -e R_PORT=$rPort \
           -e W_PORT=$wPort \
           -e C_PORT=$cPort $B_PORT_VAR\
           syneblock/quorum ./#start_cmd#

}

main $1
