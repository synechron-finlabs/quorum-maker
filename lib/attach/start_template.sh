#!/bin/bash

source qm.variables
source node/common.sh

function readParameters() {
    
    POSITIONAL=()
    while [[ $# -gt 0 ]]
    do
        key="$1"

        case $key in
            -d|--detached)
            detached="true"
            shift # past argument
            shift # past value
            ;;          
            *)    # unknown option
            POSITIONAL+=("$1") # save it in an array for later
            shift # past argument
            ;;
        esac
    done
    set -- "${POSITIONAL[@]}" # restore positional parameters

}

# docker command to join th network 
function startNode(){
    
    docker kill $NODENAME 2> /dev/null && docker rm $NODENAME 2> /dev/null
    
    docker run $DOCKER_FLAG --rm --name $NODENAME \
           -v $(pwd):/home \
           -v $(pwd)/node/contracts:/root/quorum-maker/contracts \
           -w /home/node  \
           -p $THIS_NODEMANAGER_PORT:$THIS_NODEMANAGER_PORT\
           -e CURRENT_NODE_IP=$CURRENT_IP \
           -e R_PORT=$RPC_PORT \
           -e NM_PORT=$THIS_NODEMANAGER_PORT \
           $dockerImage ./start_$NODENAME.sh
}

function main(){
    source setup.conf

    readParameters $@

    if [[ -z "$detached" ]]; then 
	    DOCKER_FLAG="-it"
    else
	    DOCKER_FLAG="-d"
    fi 	

    startNode
}
main $@
