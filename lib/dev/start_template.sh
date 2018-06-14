#!/bin/bash
function waitForMaster(){
    while : ; do
        file=$(sed  '/=$/d' /master/setup.conf)
        var="$(echo "$file" | tr ' ' '\n' | grep -F -m 1 'CONTRACT_ADD=' $1)"; var="${var#*=}"
        address=$var

        if [ -z "$address" ]; then
            echo "Waiting for Node 1 to deploy NetworkManager contract..."
            sleep 5
        else
            echo "CONTRACT_ADD=$address" >> /home/setup.conf
            break
        fi
                
    done
}
function main(){
    
    nodeName=$(basename `pwd`)

    publickey=$(cat node/keys/$nodeName.pub)
         
    cd node
    ./start_$nodeName.sh

    file=$(sed  '/=$/d' /home/setup.conf)
    var="$(echo "$file" | tr ' ' '\n' | grep -F -m 1 'RAFT_ID=' $1)"; var="${var#*=}"
    raft_id=$var   

    var="$(echo "$file" | tr ' ' '\n' | grep -F -m 1 'CONTRACT_ADD=' $1)"; var="${var#*=}"
    address=$var   
    

    if [ "$raft_id" -gt 1 ] && [ -z "$address" ] ; then
        waitForMaster
    fi

    cd /root/quorum-maker/
    ./start_nodemanager.sh 22000 22004
}
main
