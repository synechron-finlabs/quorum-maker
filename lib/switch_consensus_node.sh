#!/bin/bash

function switchToRaft(){
    peerlist=$(curl -s -X POST --data '{"jsonrpc":"2.0","method":"admin_peers","params":[],"id":74}' localhost:22000)

    i=0

    while read -r line ; do

        ids[i]="$(echo $line | cut -c7-)"
        let "i++"
        
    done < <(echo $peerlist | grep -o '\"id\":\"[^\"]*')

    j=0
    comma=","

    echo "[" > qdata/static-nodes.json
    while read -r line ; do

        echo "\"enode://"${ids[j]}"@""$(echo $line | cut -c17-)"\", >> qdata/static-nodes.json
        let "j++"
        
    done < <(echo $peerlist | grep -o 'remoteAddress\":\"[^\"]*')

    nodeInfo=$(curl -s -X POST --data '{"jsonrpc":"2.0","method":"admin_nodeInfo","params":[],"id":74}' localhost:22000)

    myNode=$(echo $nodeInfo | grep -o '\"enode\":\"[^\"]*' | cut -c10-)

    echo \"$myNode\" >> qdata/static-nodes.json

    echo "]" >> qdata/static-nodes.json

    mv start_node.sh qdata
    cp qdata/start_raft_node.sh start_node.sh
    
    touch .raft
}

function switchToQC(){
    mv qdata/start_node.sh .
    rm qdata/static-nodes.json

    rm .raft
}


if [ -f .raft ]; then
    switchToQC
else
    switchToRaft
fi


