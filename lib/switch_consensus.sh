
#!/bin/bash

for file in */; do

    if [ ${t%?} != "bootnode" ]; then
        docker exec -it ${t%?} switch_consensus_node.sh
    fi

    if [ -f .raft ]; then

        mv docker-compose.yml .raft_docker-compose.yml
        mv .qc-docker-compose.yml docker-compose.yml

    else

        mv docker-compose.yml .qc-docker-compose.yml 
        mv .raft_docker-compose.yml docker-compose.yml

    fi



done
