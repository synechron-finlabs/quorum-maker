#!/bin/bash

function readInputs(){   
    read -p $'\e[1;31mPlease enter this node IP Address: \e[0m' pCurrentIp
    read -p $'\e[1;32mPlease enter this node RPC Port: \e[0m' rPort
    read -p $'\e[1;32mPlease enter this node Network Listening Port: \e[0m' wPort
    read -p $'\e[1;32mPlease enter this node Constellation Port: \e[0m' cPort
    read -p $'\e[1;35mPlease enter this node raft port: \e[0m' raPort
    read -p $'\e[1;93mPlease enter node manager port: \e[0m' mgoPort

    #append values in Setup.conf file 
    echo 'CURRENT_IP='$pCurrentIp > ./setup.conf
    echo 'RPC_PORT='$rPort >> ./setup.conf
    echo 'WHISPER_PORT='$wPort >> ./setup.conf
    echo 'CONSTELLATION_PORT='$cPort >> ./setup.conf
    echo 'RAFT_PORT='$raPort >> ./setup.conf
    echo 'NODEMANAGER_PORT='$mgoPort >>  ./setup.conf
    echo 'NETWORK_ID='$net >>  ./setup.conf
    echo 'RAFT_ID='1 >>  ./setup.conf

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
    
    var="$(grep -F -m 1 'RAFT_PORT=' $1)"; var="${var#*=}"
    raPort=$var
    
    var="$(grep -F -m 1 'NODEMANAGER_PORT=' $1)"; var="${var#*=}"
    mgoPort=$var
    
}

function staticNode(){
    PATTERN1="s/#CURRENT_IP#/${pCurrentIp}/g"
    PATTERN2="s/#W_PORT#/${wPort}/g"
    PATTERN3="s/#raftPprt#/${raPort}/g"

    sed -i "$PATTERN1" node/qdata/static-nodes.json
    sed -i "$PATTERN2" node/qdata/static-nodes.json
    sed -i "$PATTERN3" node/qdata/static-nodes.json
}

function nodeConf(){
    PATTERN1="s/#CURRENT_IP#/${pCurrentIp}/g"
    PATTERN2="s/#C_PORT#/${cPort}/g"

    sed -i "$PATTERN1" node/#nodename#.conf
    sed -i "$PATTERN2" node/#nodename#.conf
}

function copyRaft(){
    PATTERN="s/#raftPort#/${raPort}/g"
    sed -i $PATTERN node/start_#nodename#.sh
    chmod +x node/start_#nodename#.sh
}

function copyGoService(){
    cd ..
    cat lib/master/go_service_template.sh > #nodename#/node/go_service.sh
    chmod +x #nodename#/node/go_service.sh
    cd #nodename#
}

function startNode(){
    docker run -it --name $nodeName -v $(pwd):/home  -w /${PWD##*}/home/node  \
           -p $rPort:$rPort -p $wPort:$wPort -p $wPort:$wPort/udp -p $cPort:$cPort -p $raPort:$raPort -p $mgoPort:8000 \
           -e CURRENT_NODE_IP=$pCurrentIp \
           -e R_PORT=$rPort \
           -e W_PORT=$wPort \
           -e C_PORT=$cPort \
	       -e RA_PORT=$raPort \
           $dockerImage ./#start_cmd#
}

function main(){
    dockerImage=syneblock/quorum-master:Go2.0
    net=#netid#
    nodeName=#nodename#
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

     staticNode
     nodeConf
     copyRaft
     copyGoService
     publickey=$(cat node/keys/$nodeName.pub)
     echo -e '************************************************************************************************************************'
     echo -e '\e[1;32mSuccessfully created and started \e[0m'$nodeNome
     echo -e '\e[1;32mYou can send transactions to: \e[0m'$pCurrentIp:$rPort
     echo -e '\e[1;32mFor private transactions, use \e[0m'$publickey
     echo -e '\e[1;32mTo join this node from a different host, please run Quorum Maker and Choose option to run Join Network.\e[0m'
     echo -e '\e[1;32mWhen asked, enter \e[0m'$pCurrentIp '\e[1;32mfor Node Manager IP and \e[0m'$mgoPort '\e[1;32mfor NodeManager port.\e[0m'
     echo -e '************************************************************************************************************************'
     startNode
}
main
