#!/bin/bash


function switchToRaft(){

    echo "[" > qdata/static-nodes.json

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

        enodes[j]="\"enode://"${ids[j]}"@""$(echo $line | grep -o '.*:' | cut -c17-)21000?discport=0"\"
        
        let "j++"
        
    done < <(echo $peerlist | grep -o 'remoteAddress\":\"[^\"]*')

    nodeInfo=$(curl -s -X POST --data '{"jsonrpc":"2.0","method":"admin_nodeInfo","params":[],"id":74}' localhost:22000)

    myNode=$(echo $nodeInfo | grep -o '\"id\":\"[^\"]*' | cut -c7-)
    LOCAL_NODE_IP="$(ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')"
    
    enodes[j]="\"enode://"$myNode"@"$LOCAL_NODE_IP":21000?discport=0"\"

    let "j++"


    IFS=$'\n' sorted=($(sort <<<"${enodes[*]}"))
    unset IFS

    k=0
    comma=","
    while [ $k -lt $j ]
    do
        if [[ $(( k + 1 )) == $j ]]; then
            comma=""
        fi
        echo ${sorted[k]}$comma >> qdata/static-nodes.json
        let "k++"
    done


    echo "]" >> qdata/static-nodes.json

    cp -f qdata/start_raft_node.sh start_node.sh
    
    touch .raft
}

function switchToQC(){
    cp -f qdata/start_qc_node.sh start_node.sh
    rm qdata/static-nodes.json

    rm .raft
}

function cleanDirectories(){

    echo "Cleaning directories"
    cp -r qdata/keystore .
    cp qdata/*.conf .
    cp qdata/geth/nodekey .    
    [[ -e  qdata/static-nodes.json ]] && cp qdata/static-nodes.json .
    cp -f qdata/start_qc_node.sh .
    cp -f qdata/start_raft_node.sh .
    rm -rf qdata
    mkdir qdata
    mv keystore qdata/        

    geth --datadir qdata init genesis.json
    mkdir qdata/geth
    cp nodekey qdata/geth/
    cp *.conf qdata
    [[ -e  static-nodes.json ]] && mv static-nodes.json qdata
    mv -f start_qc_node.sh qdata
    mv -f start_raft_node.sh qdata
    
    mkdir qdata/logs
    echo "Cleaning directories... Done"
}


if [ -f .raft ]; then
    switchToQC
else
    switchToRaft
fi

sleep 3

./stop.sh
cleanDirectories
