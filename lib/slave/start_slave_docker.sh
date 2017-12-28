#!/bin/bash
 
function readInputs(){  
    read -p $'\e[1;31mPlease enter this node IP Address: \e[0m' pCurrentIp
    read -p $'\e[1;32mPlease enter this node RPC Port: \e[0m' rPort
    read -p $'\e[1;32mPlease enter this node Network Listening Port: \e[0m' wPort
    read -p $'\e[1;32mPlease enter this node Constellation Port: \e[0m' cPort
    read -p $'\e[1;35mPlease enter this node raft port: \e[0m' raPort
    read -p $'\e[1;33mPlease enter this node java endpoint Port: \e[0m' tjPort  
    
    #append values in setup.conf file
    echo 'CONSTELLATION_PORT='$cPort >> ./setup.conf 
    echo 'CURRENT_IP='$pCurrentIp >> ./setup.conf
    echo 'RPC_PORT='$rPort >> ./setup.conf
    echo 'WHISPER_PORT='$wPort >> ./setup.conf
    echo 'RAFT_PORT='$raPort >> ./setup.conf
    echo 'THIS_NODE_JAVA_PORT='$tjPort >> ./setup.conf
    
    url=http://#pMainIp#:#mjavaPort#/joinNetwork
    PATTERN="s|#url#|${url}|g"
    sed -i $PATTERN start.sh
}

#docker command to up the slave node
function startNodeforRaftPrep(){
    echo "starting raft"
    docker run -d -it -v $(pwd):/home  -w /${PWD##*}/home  \
           -p $rPort:$rPort -p $wPort:$wPort -p $wPort:$wPort/udp -p $cPort:$cPort -p $raPort:$raPort -p $tjPort:8080\
           -e CURRENT_NODE_IP=$pCurrentIp \
           -e R_PORT=$rPort \
           -e W_PORT=$wPort \
           -e C_PORT=$cPort \
           -e RA_PORT=$raPort \
           syneblock/quorum-master:quorum2.0.0 ./start.sh > sDockerHash.txt
}

function startNode(){
    
    docker run -d -it --name $node -v $(pwd):/home  -w /${PWD##*}/home/node  \
           -p $rPort:$rPort -p $wPort:$wPort -p $wPort:$wPort/udp -p $cPort:$cPort -p $raPort:$raPort -p $tjPort:8080\
           -e CURRENT_NODE_IP=$pCurrentIp \
           -e R_PORT=$rPort \
           -e W_PORT=$wPort \
           -e C_PORT=$cPort \
           -e RA_PORT=$raPort \
           syneblock/quorum-master:quorum2.0.0 ./start_${node}.sh > sDockerHash.txt
}

function copyJavaService(){
    cd ..
    cat lib/slave/java_service.sh > ./${node}/node/java_service.sh
    chmod +x ./${node}/node/java_service.sh
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
    sleep 5
}

function main(){
    node=#nodename#
    readInputs
    copyJavaService
    startNodeforRaftPrep
    stopDocker
    startNodetemplate
	startNode
}
main
