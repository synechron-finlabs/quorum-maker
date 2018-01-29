#!/bin/bash
 
function readInputs(){

	read -p $'\e[1;31mPlease enter main node IP Address: \e[0m' pMainIp
	read -p $'\e[1;33mPlease enter node manager port: \e[0m' mgoPort
    read -p $'\e[1;35mPlease enter this node raft port: \e[0m' raPort
    read -p $'\e[1;32mPlease enter this node Network Listening Port: \e[0m' wPort

	urlG=http://${pMainIp}:${mgoPort}/genesis
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
    Enode1=$Enode$pMainIp:$wPort$disc$raPort
    cp nodekey ${sNode}/node/qdata/geth/.
    cat lib/master/static-nodes_template.json > ${sNode}/node/qdata/static-nodes.json
    PATTERN="s|#eNode#|${Enode}|g"
    sed -i $PATTERN ${sNode}/node/qdata/static-nodes.json
    rm enode.txt
    rm nodekey
}


 #create node configuration file
 function copyConfTemplate(){
    PATTERN="s/#sNode#/${sNode}/g"
    sed $PATTERN lib/slave/template.conf > ${sNode}/node/${sNode}.conf
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
    cat lib/slave/init_template.sh > ${sNode}/init.sh
    chmod +x ${sNode}/init.sh
}

#function to create start node script without --raftJoinExisting flag
function copyStartTemplateG(){
    cat lib/slave/start_quorumG_template.sh > ${sNode}/node/start_${sNode}.sh
    PATTERN="s/#sNode#/${sNode}/g"
    sed -i $PATTERN ${sNode}/node/start_${sNode}.sh

    PATTERN2="s/#networkId#/${NETV}/g"
    sed -i $PATTERN2 ${sNode}/node/start_${sNode}.sh
    chmod +x ${sNode}/node/start_${sNode}.sh

    cat lib/slave/start_template.sh > ${sNode}/start.sh
    cat lib/slave/start_docker_template.sh > ${sNode}/start_docker.sh
    START_CMD="start_${sNode}.sh"
    PATTERN="s/#start_cmd#/${START_CMD}/g"
    sed -i $PATTERN ${sNode}/start.sh
    sed -i $PATTERN ${sNode}/start_docker.sh
    PATTERN="s/#nodename#/${sNode}/g"
    sed -i $PATTERN ${sNode}/start.sh
    sed -i $PATTERN ${sNode}/start_docker.sh
    PATTERN="s/#netv#/$NETV/g"
    sed -i $PATTERN ${sNode}/start.sh
    sed -i $PATTERN ${sNode}/start_docker.sh
    PATTERN="s/#pMainIp#/$pMainIp/g"
    sed -i $PATTERN ${sNode}/start.sh
    sed -i $PATTERN ${sNode}/start_docker.sh
    PATTERN="s/#mgoPort#/$mgoPort/g"
    sed -i $PATTERN ${sNode}/start_docker.sh
    PATTERN="s/#raftPort#/$raPort/g"
    sed -i $PATTERN ${sNode}/start_docker.sh
    PATTERN="s/#wisPort#/$wPort/g"
    sed -i $PATTERN ${sNode}/start_docker.sh
    PATTERN="s/#accountAdd#/$sAccountAddress/g"
    sed -i $PATTERN ${sNode}/start.sh
    PATTERN="s/#mConstellation#/$MCONSTV/g"
    sed -i $PATTERN ${sNode}/start.sh
    PATTERN="s|#eNode#|${Enode}|g"
    sed -i $PATTERN ${sNode}/start.sh
    PATTERN="s|#url#|${urlJ}|g"
    sed -i $PATTERN ${sNode}/start.sh

    cat lib/slave/start_quorum_template.sh > ${sNode}/node/start_${sNode}_final.sh   

    PATTERN2="s/#networkId#/${NETV}/g"
    sed -i $PATTERN2 ${sNode}/node/start_${sNode}_final.sh
    chmod +x ${sNode}/node/start_${sNode}_final.sh

    chmod +x ${sNode}/start.sh
    chmod +x ${sNode}/start_docker.sh
    chmod +x ${sNode}/node/start_${sNode}.sh
}

# Function to send post call to java endpoint getGenesis 
function goGetGenesis(){
    pending="Pending user response"
    rejected="Access denied"
    response=$(curl -X POST \
    --max-time 60 ${urlG} \
    -H "content-type: application/json" \
    -d '{
       "enode-id":"'${Enode1}'"
       "ip-address":"'${pMainIp}'"
    }')
   if [ "$response" = "$pending" ]
    then 
        echo "Previous request to Join Network is still pending. Please try later. Program exiting" 
        exit 0
    elif [ "$response" = "$rejected" ]
    then
        echo "Request to Join Network was rejected. Program exiting"
        exit 0
    elif [ "$response" = "" ]
    then
        echo "Waited too long for approval from Master node. Please try later. Program exiting"
        exit 0
    else
    echo $response > input1.json
    sed -i 's/\\//g' input1.json
    sed -i 's/"{ "config"/{ "config"/g' input1.json
    sed -i 's/}"/}/g' input1.json
    sed -i 's/,/,\n/g' input1.json
    sed -i 's/ //g' input1.json
    cat input1.json | jq '.netID' > lib/slave/net1.txt
    sed -i 's/"//g' lib/slave/net1.txt
    NETV=$(cat lib/slave/net1.txt)
    cat input1.json | jq '.["contstellation-port"]' > lib/slave/const.txt
    sed -i 's/"//g' lib/slave/const.txt
    MCONSTV=$(cat lib/slave/const.txt)
    echo 'MASTER_CONSTELLATION_PORT='$MCONSTV >>  ${sNode}/setup.conf
    genesis=$(jq '.genesis' input1.json)
    echo $genesis > ${sNode}/node/genesis.json
    rm -f input1.json
    rm -f lib/slave/net1.txt
    rm -rf lib/slave/const.txt
    fi

}

function stopDocker(){
    sleep 5
    echo $sNode > mini
    check=$(cat mini| cut -c1-9)
    docker ps | grep $check > name
    nodename=$(awk 'END {print $NF}' name)
    psId=$(docker inspect --format="{{.Id}}" $nodename)
    docker rm -f $psId
    sleep 5
}

# execute init script
function executeInit(){
    cd ${sNode}
    ./init.sh
   
}

function main(){    
    read -p $'\e[1;32mPlease enter slave node name: \e[0m' sNode 
    echo $sNode > nodeName
    rm -rf ${sNode}
    mkdir -p ${sNode}/node/keys
    mkdir -p ${sNode}/node/qdata
    mkdir -p ${sNode}/node/qdata/{keystore,geth,logs}
    readInputs
    generateEnode
    createAccount
    generateKeyPair
    createInitNodeScript
    goGetGenesis $Enode1 $urlG
    copyConfTemplate
    copyStartTemplateG
    executeInit
}
main
    
