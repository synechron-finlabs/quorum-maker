#!/bin/bash

function installDocker(){
    echo "Installing Docker"

    sudo apt-get update

    sudo apt-get install \
         apt-transport-https \
         ca-certificates \
         curl \
         software-properties-common

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

    sudo add-apt-repository \
         "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
         $(lsb_release -cs) \
         stable"

    sudo apt-get update

    sudo apt-get install docker-ce
    
    sudo curl -o /usr/local/bin/docker-compose -L \
         "https://github.com/docker/compose/releases/download/1.11.2/docker-compose-$(uname -s)-$(uname -m)"

    sudo chmod +x /usr/local/bin/docker-compose
    sleep 5
    echo "Docker Installed successfully"
}

function readFromFile(){
    var="$(grep -F -m 1 'CURRENT_IP=' $1)"; var="${var#*=}"
    pCurrentIp=$var

    var="$(grep -F -m 1 'RPC_PORT=' $1)"; var="${var#*=}"
    rPort=$var
    
    var="$(grep -F -m 1 'WHISPER_PORT=' $1)"; var="${var#*=}"
    wPort=$var
    
    var="$(grep -F -m 1 'CONSTELLATION_PORT=' $1)"; var="${var#*=}"
    cPort=$var
    
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
    #COMMENT_IF_MASTER# read -p $'\e[1;33mPlease enter main node IP Address: \e[0m' pMainIp
    #COMMENT_IF_MASTER# read -p $'\e[1;35mPlease enter main constellation node port: \e[0m' pCPort

}
function main(){
    if [ -z "$(which docker)" ]; then
        installDocker
    fi

    let pMainIp=0
    let pCPort=0

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

    docker run -d -it -v $(pwd)/$line:/${PWD##*/}  -w /${PWD##*}/#NODE_NAME#/node  \
           -p $rPort:$rPort -p $wPort:$wPort -p $wPort:$wPort/udp -p $cPort:$cPort \
           -e MAIN_NODE_IP=$pMainIp \
           -e MAIN_C_PORT=$pCPort -e CURRENT_NODE_IP=$pCurrentIp \
           -e R_PORT=$rPort \
           -e W_PORT=$wPort \
           -e C_PORT=$cPort $B_PORT_VAR\
           syneblock/quorum ./#start_cmd#

}

main $1
