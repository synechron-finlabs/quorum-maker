#!/bin/bash
 
function readInputs(){  
    read -p $'\e[1;31mPlease enter this node IP Address: \e[0m' pCurrentIp
    read -p $'\e[1;32mPlease enter this node RPC Port: \e[0m' rPort
    read -p $'\e[1;32mPlease enter this node Network Listening Port: \e[0m' wPort
    read -p $'\e[1;32mPlease enter this node Constellation Port: \e[0m' cPort
    read -p $'\e[1;35mPlease enter this node raft port: \e[0m' raPort
    read -p $'\e[1;33mPlease enter this node java endpoint Port: \e[0m' tjPort  
    
    #append values in setup.conf file 
    echo 'CURRENT_IP='$pCurrentIp >> ./setup.conf
    echo 'RPC_PORT='$rPort >> ./setup.conf
    echo 'WHISPER_PORT='$wPort >> ./setup.conf
    echo 'CONSTELLATION_PORT='$cPort >> ./setup.conf
    echo 'RAFT_PORT='$raPort >> ./setup.conf
    echo 'THIS_NODE_MASTER_JAVA_PORT='$tjPort >> ./setup.conf
    
    url=http://#pMainIp#:#mjavaPort#/joinNetwork
}

function staticNode(){
    PATTERN1="s/#CURRENT_IP#/${pCurrentIp}/g"
    PATTERN2="s/#W_PORT#/${wPort}/g"
    PATTERN3="s/#raftPprt#/${raPort}/g"

    sed -i "$PATTERN1" node/qdata/static-nodes.json
    sed -i "$PATTERN2" node/qdata/static-nodes.json
    sed -i "$PATTERN3" node/qdata/static-nodes.json
}


function startNodetemplate(){
    rm -rf node/start_#nodename#.sh
    NODE=#nodename#
    NET=#netv#

    cat lib/slave/start_template_slave.sh > ./${sNode}/node/start_#nodename#.sh
    PATTERN="s/#sNode#/$NODE/g"
    sed -i $PATTERN ./${sNode}/node/start_#nodename#.sh
    PATTERN1="s/#raftId#/$raftIDV/g"
    sed -i $PATTERN1 ./${sNode}/node/start_#nodename#.sh
    PATTERN2="s/#networkId#/$NET/g"
    sed -i $PATTERN2 ./${sNode}/node/start_#nodename#.sh
    PATTERN="s/#raftPort#/${raPort}/g"
    sed -i $PATTERN ./${sNode}/node/start_#nodename#.sh
   
    chmod +x ./${sNode}/node/start_#nodename#.sh

}


function nodeConf(){
    MAINIP=#pMainIp#
    MCONSTV=#mConstellation#

    PATTERN1="s/#CURRENT_IP#/${pCurrentIp}/g"
    PATTERN2="s/#C_PORT#/${cPort}/g"
    PATTERN3="s/#MAIN_NODE_IP#/$MAINIP/g"
    PATTERN4="s/#M_C_PORT#/${MCONSTV}/g"

    sed -i "$PATTERN1" node/#nodename#.conf
    sed -i "$PATTERN2" node/#nodename#.conf
    sed -i "$PATTERN3" node/#nodename#.conf
    sed -i "$PATTERN4" node/#nodename#.conf
}

function createEnode(){
    echo "createEnode function "
    enode1=#eNode#
    disc='?discport=0&raftport='
    echo "raPort" $raPort
    enode=$enode1$pCurrentIp:$wPort$disc$raPort
    echo "enode...."$enode
}

# Function to send post call to java endpoint joinNode 
function javaJoinNode(){
    echo "in javajoinnode...."
    enode1=#eNode#
    add=#accountAdd#
    cd ..
    sleep 10
    response=$(curl -X POST \
    $2 \
    -H "content-type: application/json" \
    -d '{
       "enode":"'$1'",
       "accountAddress":"'$2'"
    }')

    echo $response > input.json
    cat input.json | jq '.raftID' > raft.txt
    sed -i 's/"//g' raft.txt
    RAFTV=$(cat raft.txt)
    raftID=$(grep -F -m 1 'raftID' input.json)
    raftIDV=$(echo $raftID | tr -dc '0-9')

    #rm -f input.json
    #rm -f raft.txt    

}

function startNode(){

    cd ${sNode}
#docker command to run node inside docker
    docker run -d -it -v $(pwd):/home  -w /${PWD##*}/home/node  \
           -p $rPort:$rPort -p $wPort:$wPort -p $wPort:$wPort/udp -p $cPort:$cPort -p $raPort:$raPort -p $tjPort:8080\
           -e CURRENT_NODE_IP=$pCurrentIp \
           -e R_PORT=$rPort \
           -e W_PORT=$wPort \
           -e C_PORT=$cPort \
           -e RA_PORT=$raPort \
           syneblock/quorum-master:quorum2.0.0 ./#start_cmd# > sDockerHash.txt
}

function stopDocker(){
    dockerH=$(cat ${sNode}/sDockerHash.txt)
    echo $dockerH
    sudo docker rm -f $dockerH
    sleep 5
}

function main(){

        sNode=$(cat ../nodeName.txt)
	readInputs
	staticNode
	nodeConf
        createEnode
        startNode
        javaJoinNode $enode $add $url
	echo $url
	echo $enode
	echo $add
        stopDocker
        startNodetemplate
	startNode
}
main
