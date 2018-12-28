#!/bin/bash



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

./stop.sh
cleanDirectories
