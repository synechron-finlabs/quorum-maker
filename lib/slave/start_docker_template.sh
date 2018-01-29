#!/bin/bash
 
function readInputs(){  
    read -p $'\e[1;31mPlease enter this node IP Address: \e[0m' pCurrentIp
    read -p $'\e[1;32mPlease enter this node RPC Port: \e[0m' rPort
    read -p $'\e[1;32mPlease enter this node Constellation Port: \e[0m' cPort
    read -p $'\e[1;33mPlease enter node manager Port: \e[0m' tgoPort  
    
    #append values in setup.conf file
    echo 'CURRENT_IP='$pCurrentIp >> ./setup.conf
    echo 'RPC_PORT='$rPort >> ./setup.conf
    echo 'WHISPER_PORT='$wPort >> ./setup.conf
    echo 'CONSTELLATION_PORT='$cPort >> ./setup.conf 
    echo 'RAFT_PORT='$raPort >> ./setup.conf
    echo 'THIS_NODEMANAGER_PORT='$tgoPort >> ./setup.conf
    echo 'MASTER_IP='$mainIp > ${sNode}/setup.conf
    echo 'NODEMANAGER_PORT='$mgoPort >>  ${sNode}/setup.conf
    
    url=http://$mainIp:$mgoPort/peer
    PATTERN="s|#url#|${url}|g"
    sed -i $PATTERN start.sh
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
    
    var="$(grep -F -m 1 'THIS_NODEMANAGER_PORT=' $1)"; var="${var#*=}"
    tgoPort=$var

    var="$(grep -F -m 1 'MASTER_IP=' $1)"; var="${var#*=}"
    mainIp=$var

    var="$(grep -F -m 1 'NODEMANAGER_PORT=' $1)"; var="${var#*=}"
    mgoPort=$var
    
}

#docker command to up the slave node
function startNodeforRaftPrep(){
    docker run -d -it -v $(pwd):/home  -w /${PWD##*}/home  \
           -p $rPort:$rPort -p $wPort:$wPort -p $wPort:$wPort/udp -p $cPort:$cPort -p $raPort:$raPort -p $tgoPort:8000\
           -e CURRENT_NODE_IP=$pCurrentIp \
           -e R_PORT=$rPort \
           -e W_PORT=$wPort \
           -e C_PORT=$cPort \
           -e RA_PORT=$raPort \
           $dockerImage ./start.sh > sDockerHash.txt
}

function startNode(){
    docker run -it --name $node -v $(pwd):/home  -w /${PWD##*}/home/node  \
           -p $rPort:$rPort -p $wPort:$wPort -p $wPort:$wPort/udp -p $cPort:$cPort -p $raPort:$raPort -p $tgoPort:8000\
           -e CURRENT_NODE_IP=$pCurrentIp \
           -e R_PORT=$rPort \
           -e W_PORT=$wPort \
           -e C_PORT=$cPort \
           -e RA_PORT=$raPort \
           $dockerImage ./start_${node}.sh
}

function copyGoService(){
    cd ..
    cat lib/slave/go_service_template.sh > ./${node}/node/go_service.sh
    chmod +x ./${node}/node/go_service.sh
    cd ${node}
}

function startNodetemplate(){
    net=#netv#
    cd ..
    chmod +x ./${node}/node/start_${node}.sh
    cd ${node}

}

function stopDocker(){
    dockerH=$(cat sDockerHash.txt)
    sleep 20
    sudo docker rm -f $dockerH
    rm -f sDockerHash.txt
    sleep 5
}

function main(){
    dockerImage=syneblock/quorum-master:Go2.0
    node=#nodename#
    mainIp=#pMainIp#
    mgoPort=#mgoPort#
    raPort=#raftPort#
    wPort=#wisPort#
    #if [ -z "$1" ]; then
    #    FILE=setup.conf
    #else
    #    FILE=$1
    #fi

    #if [ -f $FILE ]; then
    #    readFromFile $FILE
    #else
    #    readInputs
    #fi
    readInputs
    copyGoService
    startNodeforRaftPrep
    stopDocker
    startNodetemplate
    publickey=$(cat node/keys/$node.pub)
     echo -e '\e[1;32mSuccessfully created and started \e[0m'$node
     echo -e '\e[1;32mYou can send transactions to: \e[0m'$pCurrentIp:$rPort
     echo -e '-------------------------------------------------------------------------------------'
     echo -e '\e[1;32mFor private transactions, use \e[0m'$publickey
     echo -e '-------------------------------------------------------------------------------------'
     echo -e '\e[1;32mTo join this node from a different host, please run Quorum Maker and Choose option to run Join Network.\e[0m'
     echo -e '\e[1;32mWhen asked, enter \e[0m'$pCurrentIp '\e[1;32mfor Node Manager IP and \e[0m'$tgoPort '\e[1;32mfor NodeManager port.\e[0m'
    startNode
}
main
