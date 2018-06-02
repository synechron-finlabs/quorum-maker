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
    echo $Enode1 > ${sNode}/node/enode.txt
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
function createStartNodeScript(){
    cp lib/slave/start_quorum_template.sh ${sNode}/node/start_${sNode}.sh
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
    

    cp lib/slave/start_template.sh ${sNode}/start.sh
    START_CMD="start_${sNode}.sh"
    PATTERN="s/#start_cmd#/${START_CMD}/g"
    sed -i $PATTERN ${sNode}/start.sh
            
    chmod +x ${sNode}/start.sh
    chmod +x ${sNode}/node/start_${sNode}.sh

    cp lib/slave/pre_start_check.sh ${sNode}/node/pre_start_check.sh

    cp lib/common.sh  ${sNode}/node
}

function createSetupScript() {
    echo 'NODENAME='${sNode} > ${sNode}/setup.conf
    echo 'MASTER_IP='${pMainIp} >> ${sNode}/setup.conf
    echo 'WHISPER_PORT='${wPort} >> ${sNode}/setup.conf
    echo 'RAFT_PORT='${raPort} >> ${sNode}/setup.conf
    echo 'RPC_PORT='${rPort} >> ${sNode}/setup.conf
    echo 'CONSTELLATION_PORT='${cPort} >> ${sNode}/setup.conf
    echo 'THIS_NODEMANAGER_PORT='${tgoPort} >> ${sNode}/setup.conf
    echo 'MAIN_NODEMANAGER_PORT='${mgoPort} >> ${sNode}/setup.conf
    echo 'CURRENT_IP='${pCurrentIp} >> ${sNode}/setup.conf
    echo 'REGISTERED=' >> ${sNode}/setup.conf
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
    createStartNodeScript
    createSetupScript
    createAccount
    
}

main