#!/bin/bash
function staticNode(){
    echo "in static node"
    PATTERN1="s/#CURRENT_IP#/${CURRENT_NODE_IP}/g"
    PATTERN2="s/#W_PORT#/${W_PORT}/g"
    PATTERN3="s/#raftPprt#/${RA_PORT}/g"

    sed -i "$PATTERN1" /home/node/qdata/static-nodes.json
    sed -i "$PATTERN2" /home/node/qdata/static-nodes.json
    sed -i "$PATTERN3" /home/node/qdata/static-nodes.json
}

function nodeConf(){
    echo "in nodeconf"
    MAINIP=#pMainIp#
    mConstV=#mConstellation#

    PATTERN1="s/#CURRENT_IP#/${CURRENT_NODE_IP}/g"
    PATTERN2="s/#C_PORT#/${C_PORT}/g"
    PATTERN3="s/#MAIN_NODE_IP#/$MAINIP/g"
    PATTERN4="s/#M_C_PORT#/${mConstV}/g"

    sed -i "$PATTERN1" /home/node/${node}.conf
    sed -i "$PATTERN2" /home/node/${node}.conf
    sed -i "$PATTERN3" /home/node/${node}.conf
    sed -i "$PATTERN4" /home/node/${node}.conf
}

function createEnode(){
    echo "in create enode"
    enode1=#eNode#
    disc='?discport=0&raftport='
    enode=$enode1$CURRENT_NODE_IP:$W_PORT$disc$RA_PORT
}

function startNode(){
    echo "start node"
    ./#start_cmd#
}

# Function to send post call to java endpoint joinNode 
function javaJoinNode(){
    echo "Fetching RaftId..."
    #enode1=#eNode#
    #add=#accountAdd#
    sleep 10
    #response=$(curl -X POST \
    curl -X POST \
    ${url} \
    -H "content-type: application/json" \
    -d '{
       "enode":"'${enode}'"
    }' > input.json
    #}')

    #echo $response > input.json
    cat input.json | jq '.raftID' > raft.txt
    sed -i 's/"//g' raft.txt
    RAFTV=$(cat raft.txt)
    raftID=$(grep -F -m 1 'raftID' input.json)
    raftIDV=$(echo $raftID | tr -dc '0-9')
    
    rm -f start_${node}.sh
    mv start_${node}_final.sh start_${node}.sh
    echo "moved final raft start.sh"
    PATTERN1="s/#raftId#/$raftIDV/g"
    sed -i $PATTERN1 start_${node}.sh
    PATTERN="s/#sNode#/${node}/g"
    sed -i $PATTERN start_${node}.sh
    rm -f input.json
    rm -f raft.txt    

}

function javaService(){
	./java_service.sh
	sleep 10 
	rm -f java_service.sh
}

function main(){
    node=#nodename#
    url=#url#
    echo ${node}
    echo ${url}
    cd node
	staticNode
	nodeConf
    createEnode
    startNode
    javaJoinNode $enode $url
    javaService
}
main
