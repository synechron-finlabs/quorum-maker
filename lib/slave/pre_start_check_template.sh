#!/bin/bash

source node/common.sh
    
function readFromFile(){
    var="$(grep -F -m 1 'NODENAME=' $1)"; var="${var#*=}"
    nodeName=$var

    var="$(grep -F -m 1 'CURRENT_IP=' $1)"; var="${var#*=}"
    pCurrentIp=$var

    var="$(grep -F -m 1 'RPC_PORT=' $1)"; var="${var#*=}"
    rPort=$var
    
    var="$(grep -F -m 1 'WHISPER_PORT=' $1)"; var="${var#*=}"
    wPort=$var
    
    var="$(grep -F -m 1 'CONSTELLATION_PORT=' $1)"; var="${var#*=}"
    cPort=$var
    
    var="$(grep -F -m 1 'RAFT_PORT=' $1)"; var="${var#*=}"
    raPort=$var
    
    var="$(grep -F -m 1 'THIS_NODEMANAGER_PORT=' $1)"; var="${var#*=}"
    tgoPort=$var

    var="$(grep -F -m 1 'MASTER_IP=' $1)"; var="${var#*=}"
    mainIp=$var

    var="$(grep -F -m 1 'MAIN_NODEMANAGER_PORT=' $1)"; var="${var#*=}"
    mgoPort=$var

    var="$(grep -F -m 1 'PUBKEY=' $1)"; var="${var#*=}"
    publickey=$var

    var="$(grep -F -m 1 'NETWORK_ID=' $1)"; var="${var#*=}"
    networkId=$var

    
        
}

# Function to send post call to go endpoint joinNode 
function updateNmcAddress(){
        
    url=http://${mainIp}:${mgoPort}/peer

    response=$(curl -s -X POST \
    --max-time 310 ${url} \
    -H "content-type: application/json" \
    -d '{
       "enode-id":"'${enode}'",
       "ip-address":"'${pCurrentIp}'"
    }') 
    response=$(echo $response | tr -d \")
    echo $response > input.txt
    RAFTV=$(awk -F':' '{ print $1 }' input.txt)

    contractAdd=$(awk -F':' '{ print $2 }' input.txt)
    updateProperty setup.conf CONTRACT_ADD $contractAdd

    PATTERN="s/#raftId#/$RAFTV/g"
    sed -i $PATTERN node/start_${node}.sh

    echo 'RAFT_ID='$RAFTV >> setup.conf
    rm -f input.txt
        
}

# Function to send post call to java endpoint getGenesis 
function requestGenesis(){
    pending="Pending user response"
    rejected="Access denied"
    timeout="Response Timed Out"
    urlG=http://${mainIp}:${mgoPort}/genesis

    echo -e $RED'\nJoin Request sent to '$mainIp'. Waiting for approval...'$COLOR_END

    response=$(curl -s -X POST \
    --max-time 310 ${urlG} \
    -H "content-type: application/json" \
    -d '{
       "enode-id":"'${enode}'",
       "ip-address":"'${pCurrentIp}'",
       "nodename":"'${node}'"
    }')

    if [ "$response" = "$pending" ]
    then 
        echo "Previous request for Joining Network is still pending. Please try later. Program exiting" 
        exit
    elif [ "$response" = "$rejected" ]
    then
        echo "Request to Join Network was rejected. Program exiting"
        exit
    elif [ "$response" = "$timeout" ]
    then
        echo "Waited too long for approval from Master node. Please try later. Program exiting"
        exit
    elif [ "$response" = "" ]
    then
        echo "Unknown Error. Please check log. Program exiting"
        exit
    else
        echo $response > input1.json
        sed -i 's/\\//g' input1.json
        sed -i 's/"{ "config"/{ "config"/g' input1.json
        sed -i 's/}"/}/g' input1.json
        sed -i 's/,/,\n/g' input1.json
        sed -i 's/ //g' input1.json
        cat input1.json | jq '.netID' > net1.txt
        sed -i 's/"//g' net1.txt
        netvalue=$(cat net1.txt)
        echo 'NETWORK_ID='$netvalue >>  setup.conf

        cat input1.json | jq '.["contstellation-port"]' > const.txt
        sed -i 's/"//g' const.txt
        mconstv=$(cat const.txt)
        echo 'MASTER_CONSTELLATION_PORT='$mconstv >>  setup.conf
        genesis=$(jq '.genesis' input1.json)
        echo $genesis > node/genesis.json
        rm -f input1.json
        rm -f const.txt
        rm -f net1.txt
    fi
}

function generateConstellationConf() {
    PATTERN1="s/#CURRENT_IP#/${pCurrentIp}/g"
    PATTERN2="s/#C_PORT#/$cPort/g"
    PATTERN3="s/#mNode#/$nodeName/g"
    PATTERN4="s/#MASTER_IP#/$mainIp/g"
    PATTERN5="s/#MASTER_CONSTELLATION_PORT#/$mconstv/g"

    sed -i "$PATTERN1" node/constellation.conf
    sed -i "$PATTERN2" node/constellation.conf
    sed -i "$PATTERN3" node/constellation.conf
    sed -i "$PATTERN4" node/constellation.conf
    sed -i "$PATTERN5" node/constellation.conf
}

# execute init script
function executeInit(){
    PATTERN="s/#networkId#/${netvalue}/g"
    sed -i $PATTERN node/start_${nodeName}.sh
        
    ./init.sh
}

function main(){
    

    readFromFile setup.conf
    
    if [ -z $networkId ]; then
        enode=$(cat node/enode.txt)
        requestGenesis
        executeInit
        updateNmcAddress
        generateConstellationConf

        publickey=$(cat node/keys/$nodeName.pub)
        echo 'PUBKEY='$publickey >> setup.conf
        role="Unassigned"
        echo 'ROLE='$role >> setup.conf

        uiUrl="http://localhost:"$tgoPort"/"

        echo -e '****************************************************************************************************************'

        echo -e '\e[1;32mSuccessfully created and started \e[0m'$nodeName
        echo -e '\e[1;32mYou can send transactions to \e[0m'$pCurrentIp:$rPort
        echo -e '\e[1;32mFor private transactions, use \e[0m'$publickey
        echo -e '\e[1;32mFor accessing Quorum Maker UI, please open the following from a web browser \e[0m'$uiUrl
        echo -e '\e[1;32mTo join this node from a different host, please run Quorum Maker and choose option to run Join Network\e[0m'
        echo -e '\e[1;32mWhen asked, enter \e[0m'$pCurrentIp '\e[1;32mfor Existing Node IP and \e[0m'$tgoPort '\e[1;32mfor Node Manager port\e[0m'

        echo -e '****************************************************************************************************************'

    fi    

}
main
