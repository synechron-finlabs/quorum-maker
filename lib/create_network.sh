#!/bin/bash
 
#create node configuration file
 function copyConfTemplate(){
    PATTERN="s/#mNode#/${mNode}/g"
    sed $PATTERN lib/master/template.conf > ${mNode}/node/${mNode}.conf
 }

#function to generate keyPair for node
 function generateKeyPair(){
    echo "Generating public and private keys for " ${mNode}", Please enter password or leave blank"
    echo -ne "\n" | constellation-node --generatekeys=${mNode}

    echo "Generating public and private backup keys for " ${mNode}", Please enter password or leave blank"
    echo -ne "\n" | constellation-node --generatekeys=${mNode}a

    mv ${mNode}*.*  ${mNode}/node/keys/.
    
}

#function to create node initialization script
function createInitNodeScript(){
    cat lib/master/init_template.sh > ${mNode}/init.sh
    chmod +x ${mNode}/init.sh
}

#function to create start node script with --raft flag
function copyStartTemplate(){
    NET_ID=$(awk -v min=10000 -v max=99999 -v freq=1 'BEGIN{srand(); for(i=0;i<freq;i++)print int(min+rand()*(max-min+1))}')
    PATTERN="s|#network_Id_value#|${NET_ID}|g"
    cat lib/master/start_quorum_template.sh > ${mNode}/node/start_${mNode}.sh
    sed -i $PATTERN ${mNode}/node/start_${mNode}.sh
    PATTERN="s/#mNode#/${mNode}/g"
    sed -i $PATTERN ${mNode}/node/start_${mNode}.sh
    chmod +x ${mNode}/node/start_${mNode}.sh

    cat lib/master/start_template.sh > ${mNode}/start.sh
    START_CMD="start_${mNode}.sh"
    PATTERN="s/#start_cmd#/${START_CMD}/g"
    sed -i $PATTERN ${mNode}/start.sh
    PATTERN="s/#nodename#/${mNode}/g"
    sed -i $PATTERN ${mNode}/start.sh
    PATTERN="s/#netid#/${NET_ID}/g"
    sed -i $PATTERN ${mNode}/start.sh
    chmod +x ${mNode}/start.sh
}

#function to generate enode
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
    
    cp nodekey ${mNode}/node/qdata/geth/.
    cat lib/master/static-nodes_template.json > ${mNode}/node/qdata/static-nodes.json
    PATTERN="s|#eNode#|${Enode}|g"
    sed -i $PATTERN ${mNode}/node/qdata/static-nodes.json

    rm enode.txt
    rm nodekey
}

#function to create node accout and append it into genesis.json file
function createAccount(){
    mAccountAddress="$(geth --datadir datadir --password lib/master/passwords.txt account new)"
    re="\{([^}]+)\}"
    if [[ $mAccountAddress =~ $re ]];
    then
        mAccountAddress="0x"${BASH_REMATCH[1]};
    fi
    cp datadir/keystore/* ${mNode}/node/qdata/keystore/${mNode}key
    PATTERN="s|#mNodeAddress#|${mAccountAddress}|g"
    PATTERN1="s|20|${NET_ID}|g"
    cat lib/master/genesis_template.json >> ${mNode}/node/genesis.json
    sed -i $PATTERN ${mNode}/node/genesis.json
    sed -i $PATTERN1 ${mNode}/node/genesis.json
    rm -rf datadir
}

# execute init script
function executeInit(){
    cd ${mNode}
    ./init.sh
}

function main(){    
    read -p $'\e[1;32mPlease enter master node name: \e[0m' mNode 
    rm -rf ${mNode}
    echo $mNode > nodename
    mkdir -p ${mNode}/node/keys
    mkdir -p ${mNode}/node/qdata
    mkdir -p ${mNode}/node/qdata/{keystore,geth,logs}
    copyConfTemplate
    generateKeyPair
    createInitNodeScript
    copyStartTemplate
    generateEnode
    createAccount
    executeInit   
}
main
