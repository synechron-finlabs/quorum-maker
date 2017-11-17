#!/bin/bash
 
 #create node configuration file
 function copyConfTemplate(){
     PATTERN="s/#mNode#/${mNode}/g"
     sed $PATTERN lib/template.conf > ${mNode}/node/${mNode}.conf
     PATTERN="/"
     otherNodeUrl=""
     mNode1=${nodes[0]}

 }

#function to generate keyPair for node
 function generateKeyPair(){
    echo "Generating public and private keys for " ${mNode}", Please enter password or leave blank"
    constellation-node --generatekeys=${mNode}

    echo "Generating public and private backup keys for " ${mNode}", Please enter password or leave blank"
    constellation-node --generatekeys=${mNode}a

    mv ${mNode}*.*  ${mNode}/node/keys/.
    
 }

#function to create node initialization script
function createInitNodeScript(){
    cat lib/init.sh > ${mNode}/init.sh

    START_CMD="start_$mNode.sh"

    PATTERN="s/#start_cmd#/${START_CMD}/g"
    sed -i $PATTERN ${mNode}/init.sh

    PATTERN="s/#mNode#/${mNode}/g"
    sed -i $PATTERN ${mNode}/init.sh

    chmod +x ${mNode}/init.sh
}

#function to create start node script with --raft flag
function copyStartTemplate(){
    NET_ID=$(awk -v min=10000 -v max=99999 -v freq=1 'BEGIN{srand(); for(i=0;i<freq;i++)print int(min+rand()*(max-min+1))}')
    PATTERN="s|#network_Id_value#|${NET_ID}|g"
    cat lib/start_template_common.sh > ${mNode}/node/start_${mNode}.sh
    sed -i $PATTERN ${mNode}/node/start_${mNode}.sh
    cat lib/start_template.sh >> ${mNode}/node/start_${mNode}.sh
    PATTERN="s/#mNode#/${mNode}/g"
    sed -i $PATTERN ${mNode}/node/start_${mNode}.sh
    chmod +x ${mNode}/node/start_${mNode}.sh

     PATTERN1="s|15|${NET_ID}|g"
     cat lib/genesis_template.json >> ${mNode}/node/genesis.json
     sed -i $PATTERN1 ${mNode}/node/genesis.json
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
    
    cp nodekey ${mNode}/node/qdata/geth/.

    PATTERN="s|#eNode#|${Enode}|g"
    cat lib/static-nodes_template.json > ${mNode}/node/qdata/static-nodes.json
    sed -i $PATTERN ${mNode}/node/qdata/static-nodes.json

    rm enode.txt
    rm nodekey
}

#function to create node accout and append it into genesis.json file
function createAccount(){
    mAccountAddress="$(geth --datadir datadir --password lib/passwords.txt account new)"
    re="\{([^}]+)\}"
    if [[ $mAccountAddress =~ $re ]];
    then
        mAccountAddress="0x"${BASH_REMATCH[1]};
    fi
    mv datadir/keystore/* ${mNode}/node/qdata/keystore/${mNode}key
    rm -rf datadir

    PATTERN="s|#mNodeAddress#|${mAccountAddress}|g"
    PATTERN1="s|15|${NET_ID}|g"
    cat lib/genesis_template.json >> ${mNode}/node/genesis.json
    sed -i $PATTERN ${mNode}/node/genesis.json
    sed -i $PATTERN1 ${mNode}/node/genesis.json

    cd ${mNode}/node
    geth --datadir qdata init genesis.json
}

function main(){    
    read -p $'\e[1;32mPlease enter master node name: \e[0m' mNode 
    rm -rf ${mNode}
    mkdir -p ${mNode}/node/keys
    mkdir -p ${mNode}/node/qdata
    mkdir -p ${mNode}/node/qdata/{keystore,geth,logs}
    copyConfTemplate
    generateKeyPair
    createInitNodeScript
    copyStartTemplate
    generateEnode
    createAccount
    
}
main
