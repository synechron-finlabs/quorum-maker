#!/bin/bash
 
function readInputs(){  
    read -p $'\e[1;31mPlease enter this node IP Address: \e[0m' pCurrentIp
    read -p $'\e[1;32mPlease enter this node RPC Port: \e[0m' rPort
    read -p $'\e[1;32mPlease enter this node Network Listening Port: \e[0m' wPort
    read -p $'\e[1;32mPlease enter this node Constellation Port: \e[0m' cPort
    read -p $'\e[1;35mPlease enter this node raft port: \e[0m' raPort
    read -p $'\e[1;33mPlease enter main node IP Address: \e[0m' pMainIp
    read -p $'\e[1;33mPlease enter this node java endpoint Port: \e[0m' tjPort  
    read -p $'\e[1;35mPlease enter main java endpoint port: \e[0m' mjPort

    url=http://${pMainIp}:${mjPort}/joinNetwork
    urlG=http://${pMainIp}:${mjPort}/sendGenesis

    #append values in setup.conf file 
    echo 'CURRENT_IP='$pCurrentIp > ${sNode}/setup.conf
    echo 'RPC_PORT='$rPort >> ${sNode}/setup.conf
    echo 'WHISPER_PORT='$wPort >> ${sNode}/setup.conf
    echo 'CONSTELLATION_PORT='$cPort >> ${sNode}/setup.conf
    echo 'RAFT_PORT='$raPort >> ${sNode}/setup.conf
    echo 'MASTER_IP='$pMainIp >> ${sNode}/setup.conf
    echo 'THIS_NODE_MASTER_JAVA_PORT='$tjPort >> ${sNode}/setup.conf
    echo 'MASTER_JAVA_PORT='$mjPort >>  ${sNode}/setup.conf
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

    Enode1=$Enode$pCurrentIp
    disc='?discport=0&'
    port=raftport=$raPort
    EnodeV=$Enode1:$wPort$disc$port
    cp nodekey ${sNode}/node/qdata/geth/.

    cat lib/master/static-nodes_template.json > ${sNode}/node/qdata/static-nodes.json
    PATTERN="s|#eNode#|${Enode}|g"
    sed -i $PATTERN ${sNode}/node/qdata/static-nodes.json

    PATTERN1="s/#CURRENT_IP#/${pCurrentIp}/g"
    PATTERN2="s/#W_PORT#/${wPort}/g"
    PATTERN3="s/#raftPprt#/${raPort}/g"

    sed -i "$PATTERN1" ${sNode}/node/qdata/static-nodes.json
    sed -i "$PATTERN2" ${sNode}/node/qdata/static-nodes.json
    sed -i "$PATTERN3" ${sNode}/node/qdata/static-nodes.json
    rm enode.txt
    rm nodekey
}


 #create node configuration file
 function copyConfTemplate(){
    PATTERN="s/#sNode#/${sNode}/g"
    sed $PATTERN lib/slave/template.conf > ${sNode}/node/${sNode}.conf

    PATTERN1="s/#CURRENT_IP#/${pCurrentIp}/g"
    PATTERN2="s/#C_PORT#/${cPort}/g"

    sed -i "$PATTERN1" ${sNode}/node/${sNode}.conf
    sed -i "$PATTERN2" ${sNode}/node/${sNode}.conf
    PATTERN="/"
    otherNodeUrl=""
    sNode1=${nodes[0]}
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
    cat lib/slave/init_slave.sh > ${sNode}/init.sh

    START_CMD="start_$sNode.sh"

    PATTERN="s/#start_cmd#/${START_CMD}/g"
    sed -i $PATTERN ${sNode}/init.sh

    PATTERN="s/#sNode#/${sNode}/g"
    sed -i $PATTERN ${sNode}/init.sh

    chmod +x ${sNode}/init.sh
}




# Function to send post call to java endpoint getGenesis 
function javaGetGenesis(){
    response=$(curl -X GET $1)
    echo $response > input1.json
    sed -i 's/\\//g' input1.json
    sed -i 's/"{ "config"/{ "config"/g' input1.json
    sed -i 's/"timestamp" : "0x00"}"/"timestamp" : "0x00"}/g' input1.json
    sed -i 's/,/,\n/g' input1.json
    cat input1.json | jq '.netId' > lib/slave/net1.txt
    sed -i 's/"//g' lib/slave/net1.txt
    NETV=$(cat lib/slave/net1.txt)
    genesis=$(jq '.genesis' input1.json)
    echo $genesis > ${sNode}/node/genesis.json
    #rm -rf input1.json
    

}



# Function to send post call to java endpoint joinNode 
function javaJoinNode(){
    response=$(curl -X POST \
    $3 \
    -H "content-type: application/json" \
    -d '{
       "enode":"'$1'",
       "accountAddress":"'$2'"
    }')

    echo $response > input.json
    sed -i 's/\\//g' input.json
    sed -i 's/"{ "config"/{ "config"/g' input.json
    sed -i 's/"timestamp" : "0x00"}"/"timestamp" : "0x00"}/g' input.json
    sed -i 's/,/,\n/g' input.json
    cat input.json | jq '.raftID' > lib/slave/raft.txt
    #cat input.json | jq '.netId' > lib/slave/net.txt
    sed -i 's/"//g' lib/slave/raft.txt
    #sed -i 's/"//g' lib/slave/net.txt
    RAFTV=$(cat lib/slave/raft.txt)
    #NETV=$(cat lib/slave/net.txt)
    raftID=$(grep -F -m 1 'raftID' input.json)
    raftIDV=$(echo $raftID | tr -dc '0-9')
    #genesis=$(jq '.genesis' input.json)
    #echo $genesis > ${sNode}/node/genesis.json
    #rm -rf input.json
    #rm -rf lib/slave/raft.txt
    #rm -rf lib/slave/net.txt    

}

# function to create start node script without --raftJoinExisting flag
function copyStartTemplateG(){
    cat lib/slave/start_template_slaveG.sh > ${sNode}/node/start_${sNode}.sh
    PATTERN="s/#sNode#/${sNode}/g"
    sed -i $PATTERN ${sNode}/node/start_${sNode}.sh
    PATTERN1="s/#raftId#/$RAFTV/g"
    sed -i $PATTERN1 ${sNode}/node/start_${sNode}.sh
    PATTERN2="s/#networkId#/$NETV/g"
    sed -i $PATTERN2 ${sNode}/node/start_${sNode}.sh
    chmod +x ${sNode}/node/start_${sNode}.sh
}




# function to create start node script with --raft flag
function copyStartTemplate(){
    rm -rf ${sNode}/node/start_${sNode}.sh
    cat lib/slave/start_template_slave.sh > ${sNode}/node/start_${sNode}.sh
    PATTERN="s/#sNode#/${sNode}/g"
    sed -i $PATTERN ${sNode}/node/start_${sNode}.sh
    PATTERN1="s/#raftId#/$RAFTV/g"
    sed -i $PATTERN1 ${sNode}/node/start_${sNode}.sh
    PATTERN2="s/#networkId#/$NETV/g"
    sed -i $PATTERN2 ${sNode}/node/start_${sNode}.sh
    chmod +x ${sNode}/node/start_${sNode}.sh
}


# execute init script
function executeInit(){
    cd ${sNode}
    ./init.sh
   
}



function executeStart(){
    #docker command to run node inside docker
    docker run -d -it -v $(pwd):/home  -w /${PWD##*}/home/node  \
           -p $rPort:$rPort -p $wPort:$wPort -p $wPort:$wPort/udp -p $cPort:$cPort -p $raPort:$raPort -p $tjPort:$tjPort\
           -e CURRENT_NODE_IP=$pCurrentIp \
           -e R_PORT=$rPort \
           -e W_PORT=$wPort \
           -e C_PORT=$cPort \
           -e RA_PORT=$raPort \
           syneblock/quorum-master:quorum2.0.0 ./start_${sNode}.sh
}


function stopDocker(){
    sleep 10
    echo $sNode > mini
    check=$(cat mini| cut -c1-5)
    sudo docker ps | grep $check > name
    nodename=$(awk 'END {print $NF}' name)
    psId=$(sudo docker inspect --format="{{.Id}}" $nodename)
    sudo docker rm -f $psId
    sleep 5
}


function main(){    
    read -p $'\e[1;32mPlease enter slave node name: \e[0m' sNode 
    rm -rf ${sNode}
    mkdir -p ${sNode}/node/keys
    mkdir -p ${sNode}/node/qdata
    mkdir -p ${sNode}/node/qdata/{keystore,geth,logs}
    readInputs
    generateEnode
    copyConfTemplate
    createAccount
    generateKeyPair
    createInitNodeScript
    javaGetGenesis $urlG
    copyStartTemplateG
    executeInit
    executeStart
    cd ..
    javaJoinNode $EnodeV $sAccountAddress $url
    stopDocker
    copyStartTemplate
    cd ${sNode}
    executeStart
}

main
    
