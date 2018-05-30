#!/bin/bash

source lib/common.sh

function readInputs(){  
    read -p $'\e[1;31mPlease enter IP Address of existing node: \e[0m' pMainIp
	read -p $'\e[1;33mPlease enter Node Manager Port of existing node: \e[0m' mgoPort
    read -p $'\e[1;31mPlease enter IP Address of this node: \e[0m' pCurrentIp
    getInputWithDefault 'Please enter RPC Port of this node' 21999 rPort $GREEN
    getInputWithDefault 'Please enter Network Listening Port of this node' rPort wPort $GREEN
    getInputWithDefault 'Please enter Constellation Port of this node' wPort cPort $GREEN
    getInputWithDefault 'Please enter Raft Port of this node' cPort raPort $PINK
    getInputWithDefault 'Please enter Node Manager Port of this node' raPort tgoPort $BLUE
    
    role="Unassigned"

    urlG=http://${pMainIp}:${mgoPort}/genesis
}
 
 #create node configuration file
 function copyConfTemplate(){
    PATTERN="s/#sNode#/${sNode}/g"
    sed $PATTERN lib/slave/template.conf > ${sNode}/node/${sNode}.conf
 }

#function to generate keyPair for node
 function generateKeyPair(){
    echo "Generating public and private keys for " ${sNode}", Please enter password or leave blank"
    echo -ne "\n" | constellation-node --generatekeys=${sNode}

    echo "Generating public and private backup keys for " ${sNode}", Please enter password or leave blank"
    echo -ne "\n" | constellation-node --generatekeys=${sNode}a

    mv ${sNode}*.*  ${sNode}/node/keys/.
    
 }

#function to create node initialization script
function createInitNodeScript(){
    cat lib/slave/init_template.sh > ${sNode}/init.sh
    chmod +x ${sNode}/init.sh
}

#function to generate enode and create static-nodes.json file
function generateEnode(){
    bootnode -genkey nodekey
    nodekey=$(cat nodekey)
    bootnode -nodekey nodekey 2>enode.txt &
    pid=$!
    sleep 5
    kill -9 $pid
    wait $pid 2> /dev/null
    re="enode:.*@"
    enode=$(cat enode.txt)
    
    if [[ $enode =~ $re ]];
        then
        Enode=${BASH_REMATCH[0]};
    fi
    disc='?discport=0&raftport='
    Enode1=$Enode$pCurrentIp:$wPort$disc$raPort 
    echo $Enode1 > ${sNode}/node/enode1.txt
    cp nodekey ${sNode}/node/qdata/geth/.
    rm enode.txt
    rm nodekey
}

#function to create node accout and append it into genesis.json file
function createAccount(){
    sAccountAddress="$(geth --datadir datadir --password lib/slave/passwords.txt account new)"
    re="\{([^}]+)\}"
    if [[ $sAccountAddress =~ $re ]];
    then
        sAccountAddress="0x"${BASH_REMATCH[1]};
    fi
    mv datadir/keystore/* ${sNode}/node/qdata/keystore/${sNode}key
    rm -rf datadir
}

#function to create start node script without --raftJoinExisting flag
function copyStartTemplate(){
    cat lib/slave/start_quorum_template.sh > ${sNode}/node/start_${sNode}.sh
    PATTERN="s/#sNode#/${sNode}/g"
    sed -i $PATTERN ${sNode}/node/start_${sNode}.sh
    PATTERN="s/r_Port/${rPort}/g"
    sed -i $PATTERN ${sNode}/node/start_${sNode}.sh
    PATTERN="s/w_Port/${wPort}/g"
    sed -i $PATTERN ${sNode}/node/start_${sNode}.sh
    PATTERN="s/nodeIp/${pCurrentIp}/g"
    sed -i $PATTERN ${sNode}/node/start_${sNode}.sh
    PATTERN="s/ra_Port/${raPort}/g"
    sed -i $PATTERN ${sNode}/node/start_${sNode}.sh
    PATTERN="s/nm_Port/${tgoPort}/g"
    sed -i $PATTERN ${sNode}/node/start_${sNode}.sh

    cat lib/slave/start_template.sh > ${sNode}/start.sh
    START_CMD="start_${sNode}.sh"
    PATTERN="s/#start_cmd#/${START_CMD}/g"
    sed -i $PATTERN ${sNode}/start.sh
    PATTERN="s/#nodename#/${sNode}/g"
    sed -i $PATTERN ${sNode}/start.sh
    PATTERN="s/#pmainip#/${pMainIp}/g"
    sed -i $PATTERN ${sNode}/start.sh
    PATTERN="s/#wisport#/${wPort}/g"
    sed -i $PATTERN ${sNode}/start.sh
    PATTERN="s/#raftPort#/${raPort}/g"
    sed -i $PATTERN ${sNode}/start.sh
    PATTERN="s/#rpcPort#/${rPort}/g"
    sed -i $PATTERN ${sNode}/start.sh
    PATTERN="s/#constPort#/${cPort}/g"
    sed -i $PATTERN ${sNode}/start.sh
    PATTERN="s/#tgoPort#/${tgoPort}/g"
    sed -i $PATTERN ${sNode}/start.sh
    PATTERN="s/#mgoPort#/${mgoPort}/g"
    sed -i $PATTERN ${sNode}/start.sh
    PATTERN="s/#pCurrentIp#/${pCurrentIp}/g"
    sed -i $PATTERN ${sNode}/start.sh
    PATTERN="s/#role#/${role}/g"
    sed -i $PATTERN ${sNode}/start.sh
    chmod +x ${sNode}/start.sh
    chmod +x ${sNode}/node/start_${sNode}.sh

    cp lib/common.sh  ${sNode}/node
}

# Function to send post call to java endpoint getGenesis 
function goGetGenesis(){
    pending="Pending user response"
    rejected="Access denied"
    timeout="Response Timed Out"
    response=$(curl -X POST \
    --max-time 310 ${urlG} \
    -H "content-type: application/json" \
    -d '{
       "enode-id":"'${Enode1}'",
       "ip-address":"'${pCurrentIp}'",
       "nodename":"'${sNode}'"
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
    cat input1.json | jq '.["contstellation-port"]' > const.txt
    sed -i 's/"//g' const.txt
    mconstv=$(cat const.txt)
    echo 'MASTER_CONSTELLATION_PORT='$mconstv >>  ${sNode}/setup.conf
    genesis=$(jq '.genesis' input1.json)
    echo $genesis > ${sNode}/node/genesis.json
    rm -f input1.json
    rm -f const.txt
    rm -f net1.txt
    fi
}

# execute init script
function executeInit(){
    PATTERN="s/#networkId#/${netvalue}/g"
    sed -i $PATTERN ${sNode}/node/start_${sNode}.sh
    PATTERN="s/#mConstellation#/${mconstv}/g"
    sed -i $PATTERN ${sNode}/start.sh
    cd ${sNode}
    ./init.sh
}

function main(){    
    read -p $'\e[1;32mPlease enter node name: \e[0m' sNode 
    echo $sNode > nodeName
    rm -rf ${sNode}
    mkdir -p ${sNode}/node/keys
    mkdir -p ${sNode}/node/qdata
    mkdir -p ${sNode}/node/qdata/{keystore,geth,logs}
    readInputs
    copyConfTemplate
    generateKeyPair
    createInitNodeScript
    generateEnode
    copyStartTemplate
    createAccount
    goGetGenesis
    executeInit
}
main
    
