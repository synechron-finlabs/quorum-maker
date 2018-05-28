#!/bin/bash

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
    
   	url=http://${pMainIp}:${mgoPort}/peer
}

function readFromFile(){
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

    var="$(grep -F -m 1 'NODEMANAGER_PORT=' $1)"; var="${var#*=}"
    mgoPort=$var

    var="$(grep -F -m 1 'NODENAME=' $1)"; var="${var#*=}"
    node=$var

    var="$(grep -F -m 1 'PUBKEY=' $1)"; var="${var#*=}"
    publickey=$var

    var="$(grep -F -m 1 'ROLE=' $1)"; var="${var#*=}"
    role=$var
}

# create node configuration
function nodeConf(){
    cd node
    mConstV=#mConstellation#

    PATTERN1="s/#CURRENT_IP#/$pCurrentIp/g"
    PATTERN2="s/#C_PORT#/$cPort/g"
    PATTERN3="s/#MAIN_NODE_IP#/$pMainIp/g"
    PATTERN4="s/#M_C_PORT#/${mConstV}/g"

    sed -i "$PATTERN1" ${node}.conf
    sed -i "$PATTERN2" ${node}.conf
    sed -i "$PATTERN3" ${node}.conf
    sed -i "$PATTERN4" ${node}.conf
    
}

function createEnode(){
    enode=$(cat enode1.txt)
}

# Function to send post call to go endpoint joinNode 
function goJoinNode(){
    echo "Waiting for approval from "${pMainIp}
    sleep 10
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
updateProperty ../setup.conf CONTRACT_ADD $contractAdd

PATTERN="s/#raftId#/$RAFTV/g"
sed -i $PATTERN start_${node}.sh
rm -f input.txt
rm -f enode1.txt
cd ..
}

# copy node Service File to run service inside docker
function copyGoService(){
    cd ..
    cat lib/slave/nodemanager_template.sh > #nodename#/node/nodemanager.sh
    PATTERN="s/#nrpcPort#/${rPort}/g"
    sed -i $PATTERN #nodename#/node/nodemanager.sh
    PATTERN="s/#servicePort#/${tgoPort}/g"
    sed -i $PATTERN #nodename#/node/nodemanager.sh
    
    chmod +x #nodename#/node/nodemanager.sh
    cd #nodename#
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
    
    node=#nodename#
    pMainIp=#pmainip#
    pCurrentIp=#pCurrentIp#
    rPort=#rpcPort#
    cPort=#constPort#
    tgoPort=#tgoPort#
    wPort=#wisport#
    raPort=#raftPort#
    mgoPort=#mgoPort#
    role=#role#
    createSetupConf
	nodeConf
    createEnode
    goJoinNode
    copyGoService
    publickey=$(cat node/keys/$node.pub)
    echo 'PUBKEY='$publickey >> ./setup.conf
    uiUrl="http://localhost:"$mgoPort"/"

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
