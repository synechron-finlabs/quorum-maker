#!/bin/bash
set -x
source node/common.sh
# create setup configurations
function createSetupConf(){  

    #append values in setup.conf file
    echo 'CURRENT_IP='$pCurrentIp > ./setup.conf
    echo 'RPC_PORT='$rPort >> ./setup.conf
    echo 'WHISPER_PORT='$wPort >> ./setup.conf
    echo 'CONSTELLATION_PORT='$cPort >> ./setup.conf 
    echo 'RAFT_PORT='$raPort >> ./setup.conf
    echo 'THIS_NODEMANAGER_PORT='$tgoPort >> ./setup.conf
    echo 'MASTER_IP='$pMainIp >> ./setup.conf
    echo 'NODEMANAGER_PORT='$mgoPort >>  ./setup.conf
    echo 'NODENAME='$node >> ./setup.conf
    echo 'ROLE='$role >> ./setup.conf
    echo 'REGISTERED=' >> ./setup.conf
    
   	
}

function readFromFile(){
    var="$(grep -F -m 1 'NODENAME=' $1)"; var="${var#*=}"
    node=$var

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

    var="$(grep -F -m 1 'NODENAME=' $1)"; var="${var#*=}"
    node=$var

    var="$(grep -F -m 1 'PUBKEY=' $1)"; var="${var#*=}"
    publickey=$var

    var="$(grep -F -m 1 'NETWORK_ID=' $1)"; var="${var#*=}"
    networkId=$var

    
        
}

# create node configuration
function nodeConf(){
    cd node
    

    PATTERN1="s/#CURRENT_IP#/$pCurrentIp/g"
    PATTERN2="s/#C_PORT#/$cPort/g"
    PATTERN3="s/#MAIN_NODE_IP#/$mainIp/g"
    PATTERN4="s/#M_C_PORT#/${mconstv}/g"

    sed -i "$PATTERN1" ${node}.conf
    sed -i "$PATTERN2" ${node}.conf
    sed -i "$PATTERN3" ${node}.conf
    sed -i "$PATTERN4" ${node}.conf

    cd ..
    
}

function createEnode(){
    enode=$(cat node/enode1.txt)
}

# Function to send post call to go endpoint joinNode 
function goJoinNode(){
    echo "Waiting for approval from "${pMainIp}
    
    url=http://${mainIp}:${mgoPort}/peer

    response=$(curl -X POST \
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
function goGetGenesis(){
    pending="Pending user response"
    rejected="Access denied"
    timeout="Response Timed Out"
    urlG=http://${mainIp}:${mgoPort}/genesis

    response=$(curl -X POST \
    --max-time 310 ${urlG} \
    -H "content-type: application/json" \
    -d '{
       "enode-id":"'${enode}'",
       "ip-address":"'${pCurrentIp}'",
       "nodename":"'${node}'"
    }')

    echo "master response" $response

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

# execute init script
function executeInit(){
    PATTERN="s/#networkId#/${netvalue}/g"
    sed -i $PATTERN node/start_${node}.sh
    #PATTERN="s/#mConstellation#/${mconstv}/g"
    #sed -i $PATTERN ${sNode}/start.sh
    
    docker run -it --rm -v $(pwd):/home  -w /${PWD##*}/home  \
          $dockerImage ./init.sh
}

# copy node Service File to run service inside docker
function copyGoService(){
    
    cat ../lib/slave/nodemanager_template.sh > node/nodemanager.sh
    PATTERN="s/#nrpcPort#/${rPort}/g"
    sed -i $PATTERN node/nodemanager.sh
    PATTERN="s/#servicePort#/${tgoPort}/g"
    sed -i $PATTERN node/nodemanager.sh
    
    chmod +x node/nodemanager.sh
    
}

# docker command to join th network 
function startNode(){
    docker run -it --rm --name $node -v $(pwd):/home  -w /${PWD##*}/home/node  \
           -p $rPort:$rPort -p $wPort:$wPort -p $wPort:$wPort/udp -p $cPort:$cPort -p $raPort:$raPort -p $tgoPort:$tgoPort\
           -e CURRENT_NODE_IP=$pCurrentIp \
           -e R_PORT=$rPort \
           -e W_PORT=$wPort \
           -e C_PORT=$cPort \
           -e RA_PORT=$raPort \
           $dockerImage ./#start_cmd#
}

function main(){
    

    readFromFile setup.conf
    createEnode

    if [ -z $networkId ]; then
        goGetGenesis
        executeInit
        
        nodeConf
        
        goJoinNode
        copyGoService
        publickey=$(cat node/keys/$node.pub)
        echo 'PUBKEY='$publickey >> setup.conf
        echo 'ROLE=' >> setup.conf
    fi    

    
    uiUrl="http://localhost:"$tgoPort"/"

    echo -e '****************************************************************************************************************'

    echo -e '\e[1;32mSuccessfully created and started \e[0m'$node
    echo -e '\e[1;32mYou can send transactions to \e[0m'$pCurrentIp:$rPort
    echo -e '\e[1;32mFor private transactions, use \e[0m'$publickey
    echo -e '\e[1;32mFor accessing Quorum Maker UI, please open the following from a web browser \e[0m'$uiUrl
    echo -e '\e[1;32mTo join this node from a different host, please run Quorum Maker and choose option to run Join Network\e[0m'
    echo -e '\e[1;32mWhen asked, enter \e[0m'$pCurrentIp '\e[1;32mfor Existing Node IP and \e[0m'$tgoPort '\e[1;32mfor Node Manager port\e[0m'

    echo -e '****************************************************************************************************************'

    startNode
}
main
