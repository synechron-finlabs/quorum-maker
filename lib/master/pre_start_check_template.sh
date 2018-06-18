#!/bin/bash

source qm.variables
source node/common.sh

# read inputs to create network
function readInputs(){   
    
    getInputWithDefault 'Please enter IP Address of this node' "" pCurrentIp $RED
    
    getInputWithDefault 'Please enter RPC Port of this node' 22000 rPort $GREEN
    
    getInputWithDefault 'Please enter Network Listening Port of this node' $((rPort+1)) wPort $GREEN
    
    getInputWithDefault 'Please enter Constellation Port of this node' $((wPort+1)) cPort $GREEN
    
    getInputWithDefault 'Please enter Raft Port of this node' $((cPort+1)) raPort $PINK
    
    getInputWithDefault 'Please enter Node Manager Port of this node' $((raPort+1)) tgoPort $BLUE
    
    
    role="Unassigned"
	
    #append values in Setup.conf file 
    echo 'CURRENT_IP='$pCurrentIp > ./setup.conf
    echo 'RPC_PORT='$rPort >> ./setup.conf
    echo 'WHISPER_PORT='$wPort >> ./setup.conf
    echo 'CONSTELLATION_PORT='$cPort >> ./setup.conf
    echo 'RAFT_PORT='$raPort >> ./setup.conf
    echo 'THIS_NODEMANAGER_PORT='$tgoPort >>  ./setup.conf
    
    echo 'NETWORK_ID='$net >>  ./setup.conf
    echo 'RAFT_ID='1 >>  ./setup.conf
    echo 'NODENAME='$nodeName >> ./setup.conf
    echo 'ROLE='$role >> ./setup.conf
    echo 'CONTRACT_ADD=' >> ./setup.conf
    echo 'REGISTERED=' >> ./setup.conf
    PATTERN="s/r_Port/${rPort}/g"
    sed -i $PATTERN node/start_${nodeName}.sh
    PATTERN="s/w_Port/${wPort}/g"
    sed -i $PATTERN node/start_${nodeName}.sh
    PATTERN="s/nodeIp/${pCurrentIp}/g"
    sed -i $PATTERN node/start_${nodeName}.sh
    PATTERN="s/ra_Port/${raPort}/g"
    sed -i $PATTERN node/start_${nodeName}.sh
    PATTERN="s/nm_Port/${tgoPort}/g"
    sed -i $PATTERN node/start_${nodeName}.sh
}

# if setup.conf available read from file to create a network
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
    
    var="$(grep -F -m 1 'NODENAME=' $1)"; var="${var#*=}"
    nodeName=$var

    var="$(grep -F -m 1 'PUBKEY=' $1)"; var="${var#*=}"
    publickey=$var

    var="$(grep -F -m 1 'ROLE=' $1)"; var="${var#*=}"
    role=$var

    var="$(grep -F -m 1 'NETWORK_ID=' $1)"; var="${var#*=}"
    networkId=$var
}

# static node to create network 
function staticNode(){
    PATTERN1="s/#CURRENT_IP#/${pCurrentIp}/g"
    PATTERN2="s/#W_PORT#/${wPort}/g"
    PATTERN3="s/#raftPprt#/${raPort}/g"

    sed -i "$PATTERN1" node/qdata/static-nodes.json
    sed -i "$PATTERN2" node/qdata/static-nodes.json
    sed -i "$PATTERN3" node/qdata/static-nodes.json
}

# create node configuration
function nodeConf(){
    PATTERN1="s/#CURRENT_IP#/${pCurrentIp}/g"
    PATTERN2="s/#C_PORT#/${cPort}/g"

    sed -i "$PATTERN1" node/#nodename#.conf
    sed -i "$PATTERN2" node/#nodename#.conf
}

function main(){
    net=#netid#
    nodeName=#nodename#

    if [ ! -f setup.conf ]; then

        readInputs
        staticNode
        nodeConf

        publickey=$(cat node/keys/$nodeName.pub)
        uiUrl="http://localhost:"$tgoPort"/"
        echo 'PUBKEY='$publickey >> ./setup.conf

        echo -e '****************************************************************************************************************'

        echo -e '\e[1;32mSuccessfully created and started \e[0m'$nodeName
        echo -e '\e[1;32mYou can send transactions to \e[0m'$pCurrentIp:$rPort
        echo -e '\e[1;32mFor private transactions, use \e[0m'$publickey
        echo -e '\e[1;32mFor accessing Quorum Maker UI, please open the following from a web browser \e[0m'$uiUrl
        echo -e '\e[1;32mTo join this node from a different host, please run Quorum Maker and choose option to run Join Network\e[0m'
        echo -e '\e[1;32mWhen asked, enter \e[0m'$pCurrentIp '\e[1;32mfor Existing Node IP and \e[0m'$tgoPort '\e[1;32mfor Node Manager Port\e[0m'

        echo -e '****************************************************************************************************************'
        
    fi
    
}
main
