#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

for file in */; do

    if [ ${file%?} != "bootnode" ]; then
        docker exec -itd ${file%?} ./switch_consensus_node.sh
    fi

done

if [ -f .raft ]; then
    mv docker-compose.yml .raft_docker-compose.yml && mv .qc-docker-compose.yml docker-compose.yml
    rm .raft
    echo "Switched to Quorum Chain Consensus. Please restart containers"
else
    mv docker-compose.yml .qc-docker-compose.yml && mv .raft_docker-compose.yml docker-compose.yml
    touch .raft
    echo "Switched to Raft Consensus. Please restart containers"
fi


