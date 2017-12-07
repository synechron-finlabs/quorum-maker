#!/bin/bash
 
function readInputs(){  
    read -p $'\e[1;31mPlease enter this node\' IP Address: \e[0m' pCurrentIp
    read -p $'\e[1;32mPlease enter this node\'s RPC Port: \e[0m' rPort
    read -p $'\e[1;32mPlease enter this node\'s Network Listening Port: \e[0m' wPort
    read -p $'\e[1;32mPlease enter this node\'s Constellation Port: \e[0m' cPort
    read -p $'\e[1;32mPlease enter this node\'s raft port: \e[0m' raPort
    read -p $'\e[1;35mPlease enter main java endpoint port: \e[0m' mjPort

    #append values in Setup.conf file 
    echo 'CURRENT_IP='$pCurrentIp > ${mNode}/setup.conf
    echo 'RPC_PORT='$rPort >> ${mNode}/setup.conf
    echo 'WHISPER_PORT='$wPort >> ${mNode}/setup.conf
    echo 'CONSTELLATION_PORT='$cPort >> ${mNode}/setup.conf
    echo 'RAFT_PORT='$raPort >> ${mNode}/setup.conf
    echo 'MASTER_JAVA_PORT='$mjPort >>  ${mNode}/setup.conf

}

 #create node configuration file
 function copyConfTemplate(){
    PATTERN="s/#mNode#/${mNode}/g"
    sed $PATTERN lib/master/template.conf > ${mNode}/node/${mNode}.conf
   
    PATTERN1="s/#CURRENT_IP#/${pCurrentIp}/g"
    PATTERN2="s/#C_PORT#/${cPort}/g"

    sed -i "$PATTERN1" ${mNode}/node/${mNode}.conf
    sed -i "$PATTERN2" ${mNode}/node/${mNode}.conf
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
    cat lib/master/init_master.sh > ${mNode}/init.sh

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
    cat lib/master/start_template_master.sh > ${mNode}/node/start_${mNode}.sh
    sed -i $PATTERN ${mNode}/node/start_${mNode}.sh
    PATTERN="s/#mNode#/${mNode}/g"
    sed -i $PATTERN ${mNode}/node/start_${mNode}.sh
    PATTERN="s/#raftPort#/${raPort}/g"
    sed -i $PATTERN ${mNode}/node/start_${mNode}.sh
    chmod +x ${mNode}/node/start_${mNode}.sh
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
  
    cat lib/master/static-nodes_template.json > ${mNode}/node/qdata/static-nodes.json
    PATTERN="s|#eNode#|${Enode}|g"
    sed -i $PATTERN ${mNode}/node/qdata/static-nodes.json

    PATTERN1="s/#CURRENT_IP#/${pCurrentIp}/g"
    PATTERN2="s/#W_PORT#/${wPort}/g"
    PATTERN3="s/#raftPprt#/${raPort}/g"

    sed -i "$PATTERN1" ${mNode}/node/qdata/static-nodes.json
    sed -i "$PATTERN2" ${mNode}/node/qdata/static-nodes.json
    sed -i "$PATTERN3" ${mNode}/node/qdata/static-nodes.json

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
    PATTERN1="s|15|${NET_ID}|g"
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

function executeStart(){
    #docker command to run node inside docker
    docker run -d -it -v $(pwd):/home  -w /${PWD##*}/home/node  \
           -p $rPort:$rPort -p $wPort:$wPort -p $wPort:$wPort/udp -p $cPort:$cPort -p $raPort:$raPort -p $mjPort:$mjPort \
           -e CURRENT_NODE_IP=$pCurrentIp \
           -e R_PORT=$rPort \
           -e W_PORT=$wPort \
           -e C_PORT=$cPort \
           -e MJ_PORT=$mjPort \
           syneblock/quorum-master:quorum2.0.0 ./start_${mNode}.sh
}


function main(){    
    read -p $'\e[1;32mPlease enter master node name: \e[0m' mNode 
    rm -rf ${mNode}
    echo $mNode > nodename
    mkdir -p ${mNode}/node/keys
    mkdir -p ${mNode}/node/qdata
    mkdir -p ${mNode}/node/qdata/{keystore,geth,logs}
    readInputs
    copyConfTemplate
    generateKeyPair
    createInitNodeScript
    copyStartTemplate
    generateEnode
    createAccount
    executeInit
    executeStart
}
main