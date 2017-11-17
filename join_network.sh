#!/bin/bash
 
 #create node configuration file
 function copyConfTemplate(){
     PATTERN="s/#sNode#/${sNode}/g"
     sed $PATTERN lib/template.conf > ${sNode}/node/${sNode}.conf
     PATTERN="/"
     otherNodeUrl=""
     sNode1=${nodes[0]}

 }

#function to generate keyPair for node
 function generateKeyPair(){
    echo "Generating public and private keys for " ${sNode}", Please enter password or leave blank"
    constellation-node --generatekeys=${sNode}

    echo "Generating public and private backup keys for " ${sNode}", Please enter password or leave blank"
    constellation-node --generatekeys=${sNode}a

    mv ${sNode}*.*  ${sNode}/node/keys/.
    
 }

#function to create node initialization script
function createInitNodeScript(){
    cat lib/init.sh > ${sNode}/init.sh

    START_CMD="start_$sNode.sh"

    PATTERN="s/#start_cmd#/${START_CMD}/g"
    sed -i $PATTERN ${sNode}/init.sh

    PATTERN="s/#sNode#/${sNode}/g"
    sed -i $PATTERN ${sNode}/init.sh

    chmod +x ${sNode}/init.sh
}

#function to create start node script with --raft flag
function copyStartTemplate(){
    NET_ID=$(awk -v min=10000 -v max=99999 -v freq=1 'BEGIN{srand(); for(i=0;i<freq;i++)print int(min+rand()*(max-min+1))}')
    PATTERN="s|#network_Id_value#|${NET_ID}|g"
    cat lib/start_template_common.sh > ${sNode}/node/start_${sNode}.sh
    sed -i $PATTERN ${sNode}/node/start_${sNode}.sh
    cat lib/start_template.sh >> ${sNode}/node/start_${sNode}.sh
    PATTERN="s/#sNode#/${sNode}/g"
    sed -i $PATTERN ${sNode}/node/start_${sNode}.sh
    chmod +x ${sNode}/node/start_${sNode}.sh
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
    
    cp nodekey ${sNode}/node/qdata/geth/.

    PATTERN="s|#eNode#|${Enode}|g"
    cat lib/static-nodes_template.json > ${sNode}/node/qdata/static-nodes.json
    sed -i $PATTERN ${sNode}/node/qdata/static-nodes.json

    rm enode.txt
    rm nodekey
}

#function to create node accout and append it into genesis.json file
function createAccount(){
    sAccountAddress="$(geth --datadir datadir --password lib/passwords.txt account new)"
    re="\{([^}]+)\}"
    if [[ $sAccountAddress =~ $re ]];
    then
        sAccountAddress="0x"${BASH_REMATCH[1]};
    fi
    mv datadir/keystore/* ${sNode}/node/qdata/keystore/${sNode}key
    rm -rf datadir

    PATTERN="s|#sNodeAddress#|${sAccountAddress}|g"
    PATTERN1="s|15|${NET_ID}|g"
    cat lib/genesis_template.json > ${sNode}/node/genesis.json
    sed -i $PATTERN ${sNode}/node/genesis.json
    sed -i $PATTERN1 ${sNode}/node/genesis.json

    cd ${sNode}/node
    geth --datadir qdata init genesis.json
}

# #Function to send post call to java endpoint joinNode 
# function javaJoinNode(){
    
#     response=$(curl -X PORT -i \
#     $7 \
#     -H "content-type: application/json" \
#     -d '{
#        "enode":"$1",
#        "accountAddress":$2,
#        "master_ip":$3,
#        "master_java_port":$6
#     }')  
    
#     echo "$response" > input.json
    
#     raftID=$(grep -F -m 1 'raftID' input.json)
#     raftID=$(echo $raftID | tr -dc '0-9')
#     genesis=$(jq '.genesis' input.json)
#     echo "$genesis" > genesis.json
#     rm -rf input.json
#     executeInit  
# }

function main(){    
    read -p $'\e[1;32mPlease enter slave node name: \e[0m' sNode 
    rm -rf ${sNode}
    mkdir -p ${sNode}/node/keys
    mkdir -p ${sNode}/node/qdata
    mkdir -p ${sNode}/node/qdata/{keystore,geth,logs}
    copyConfTemplate
    generateKeyPair
    createInitNodeScript
    copyStartTemplate
    generateEnode
    createAccount
    #javaJoinNode $Enode $accountAddress $master_ip $mjPort $url
    
}
main