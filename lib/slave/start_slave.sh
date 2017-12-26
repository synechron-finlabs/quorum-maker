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
    MAINIP=#pMainIp#
    mConstV=#mConstellation#

    PATTERN1="s/#CURRENT_IP#/${pCurrentIp}/g"
    PATTERN2="s/#C_PORT#/${cPort}/g"
    PATTERN3="s/#MAIN_NODE_IP#/$MAINIP/g"
    PATTERN4="s/#M_C_PORT#/${mConstV}/g"

    sed -i "$PATTERN1" node/${node}.conf
    sed -i "$PATTERN2" node/${node}.conf
    sed -i "$PATTERN3" node/${node}.conf
    sed -i "$PATTERN4" node/${node}.conf
}

function createEnode(){
    enode1=#eNode#
    disc='?discport=0&raftport='
    enode=$enode1$pCurrentIp:$wPort$disc$raPort
}

function startNode(){

#docker command to up the slave node
    docker run -d -it -v $(pwd):/home  -w /${PWD##*}/home/node  \
           -p $rPort:$rPort -p $wPort:$wPort -p $wPort:$wPort/udp -p $cPort:$cPort -p $raPort:$raPort -p $tjPort:8080\
           -e CURRENT_NODE_IP=$pCurrentIp \
           -e R_PORT=$rPort \
           -e W_PORT=$wPort \
           -e C_PORT=$cPort \
           -e RA_PORT=$raPort \
           syneblock/quorum-master:quorum2.0.0 ./#start_cmd# > sDockerHash.txt
}

# Function to send post call to java endpoint joinNode 
function javaJoinNode(){
    echo "in javajoinnode...."
    enode1=#eNode#
    add=#accountAdd#
    sleep 10
    response=$(curl -X POST \
    $2 \
    -H "content-type: application/json" \
    -d '{
       "enode":"'$1'"
    }')

    echo $response > input.json
    cat input.json | jq '.raftID' > raft.txt
    sed -i 's/"//g' raft.txt
    RAFTV=$(cat raft.txt)
    raftID=$(grep -F -m 1 'raftID' input.json)
    raftIDV=$(echo $raftID | tr -dc '0-9')
    rm -f input.json
    rm -f raft.txt    

}



function stopDocker(){
    dockerH=$(cat sDockerHash.txt)
    echo $dockerH
    sudo docker rm -f $dockerH
    sleep 5
}

function startNodetemplate(){
    
    net=#netv#
    rm -rf node/start_${node}.sh
    cd ..
    cat lib/slave/java_service.sh > ./${node}/node/java_service.sh
    chmod +x ./${node}/node/java_service.sh
    cat lib/slave/start_template_slave.sh > ./${node}/node/start_${node}.sh
    PATTERN="s/#sNode#/$node/g"
    sed -i $PATTERN ./${node}/node/start_${node}.sh
    PATTERN1="s/#raftId#/$raftIDV/g"
    sed -i $PATTERN1 ./${node}/node/start_${node}.sh
    PATTERN2="s/#networkId#/$net/g"
    sed -i $PATTERN2 ./${node}/node/start_${node}.sh
    PATTERN="s/#raftPort#/${raPort}/g"
    sed -i $PATTERN ./${node}/node/start_${node}.sh
   
    chmod +x ./${node}/node/start_${node}.sh
    cd ${node}

}

function javaService(){
	dockerH=$(cat sDockerHash.txt)
	echo $dockerH
	rm -f sDockerHash.txt
	sudo docker exec -d -it $dockerH bash ./java_service.sh
	sleep 10 
	rm -f node/java_service.sh
}


function main(){
        node=#nodename#

        
        readInputs

	staticNode
	nodeConf
        createEnode
        startNode
        javaJoinNode $enode $url
        stopDocker
        startNodetemplate
	startNode
        javaService
}
main
