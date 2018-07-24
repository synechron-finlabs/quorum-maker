#!/bin/bash

source node/common.sh

# Function to send post call to go endpoint joinNode 
function updateNmcAddress(){
        
    url=http://${MASTER_IP}:${MAIN_NODEMANAGER_PORT}/peer

    response=$(curl -s -X POST \
    --max-time 310 ${url} \
    -H "content-type: application/json" \
    -d '{
       "enode-id":"'${enode}'",
       "ip-address":"'${CURRENT_IP}'"
    }') 
    response=$(echo $response | tr -d \")
    echo $response > input.txt
    RAFTV=$(awk -F':' '{ print $1 }' input.txt)

    contractAdd=$(awk -F':' '{ print $2 }' input.txt)
    updateProperty setup.conf CONTRACT_ADD $contractAdd

    PATTERN="s/#raftId#/$RAFTV/g"
    sed -i $PATTERN node/start_${NODENAME}.sh

    echo 'RAFT_ID='$RAFTV >> setup.conf
    rm -f input.txt
        
}

# Function to send post call to java endpoint getGenesis 
function requestGenesis(){
    pending="Pending user response"
    rejected="Access denied"
    timeout="Response Timed Out"
    urlG=http://${MASTER_IP}:${MAIN_NODEMANAGER_PORT}/genesis

    echo -e $RED'\nJoin Request sent to '$MASTER_IP'. Waiting for approval...'$COLOR_END

    response=$(curl -s -X POST \
    --max-time 310 ${urlG} \
    -H "content-type: application/json" \
    -d '{
       "enode-id":"'${enode}'",
       "ip-address":"'${CURRENT_IP}'",
       "nodename":"'${NODENAME}'"
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
	declare -A replyMap
	while IFS="=" read -r key value
	do
    	replyMap[$key]="$value"
	done < <(jq -r "to_entries|map(\"\(.key)=\(.value|tostring)\")|.[]" input1.json)
	echo 'MASTER_CONSTELLATION_PORT='${replyMap[contstellation-port]} >>  setup.conf
	echo 'NETWORK_ID='${replyMap[netID]} >>  setup.conf
	echo ${replyMap[genesis]}  > node/genesis.json
        rm -f input1.json
    fi
}

function generateConstellationConf() {
    PATTERN1="s/#CURRENT_IP#/${CURRENT_IP}/g"
    PATTERN2="s/#C_PORT#/$CONSTELLATION_PORT/g"
    PATTERN3="s/#mNode#/$NODENAME/g"
    PATTERN4="s/#MASTER_IP#/$MASTER_IP/g"
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
    sed -i $PATTERN node/start_${NODENAME}.sh
        
    ./init.sh
}

function main(){
    

    source setup.conf
    
    if [ -z $NETWORK_ID ]; then
        enode=$(cat node/enode.txt)
        requestGenesis
        executeInit
        updateNmcAddress
        generateConstellationConf

        publickey=$(cat node/keys/$NODENAME.pub)
        echo 'PUBKEY='$publickey >> setup.conf
        role="Unassigned"
        echo 'ROLE='$role >> setup.conf

        uiUrl="http://localhost:"$THIS_NODEMANAGER_PORT"/"

        echo -e '****************************************************************************************************************'

        echo -e '\e[1;32mSuccessfully created and started \e[0m'$NODENAME
        echo -e '\e[1;32mYou can send transactions to \e[0m'$CURRENT_IP:$RPC_PORT
        echo -e '\e[1;32mFor private transactions, use \e[0m'$publickey
        echo -e '\e[1;32mFor accessing Quorum Maker UI, please open the following from a web browser \e[0m'$uiUrl
        echo -e '\e[1;32mTo join this node from a different host, please run Quorum Maker and choose option to run Join Network\e[0m'
        echo -e '\e[1;32mWhen asked, enter \e[0m'$CURRENT_IP '\e[1;32mfor Existing Node IP and \e[0m'$THIS_NODEMANAGER_PORT '\e[1;32mfor Node Manager port\e[0m'

        echo -e '****************************************************************************************************************'

    fi    

}
main
