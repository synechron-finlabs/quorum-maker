#!/bin/bash

source qm.variables
source lib/common.sh

function readInputs(){  
    
    getInputWithDefault 'Please enter the IP Address of Geth' "" pCurrentIp $RED
    getInputWithDefault 'Please enter the Public Key of Constellation' "" publickey $BLUE
    getInputWithDefault 'Please enter the RPC Port of Geth' 22000 rPort $GREEN
    getInputWithDefault 'Please enter the Network Listening Port of Geth' $((rPort+1)) wPort $GREEN
    getInputWithDefault 'Please enter the Constellation Port' $((wPort+1)) cPort $GREEN
    getInputWithDefault 'Please enter the Raft Port' $((cPort+1)) raPort $PINK
    getInputWithDefault 'Please enter the Node Manager Port of this node' $((raPort+1)) tgoPort $BLUE
    getInputWithDefault 'Please enter the Attachment Mode of this node (1 for active and 2 for passive)' 1 mode $CYAN
    if [ "$mode" = "1" ]
    then 
	mode="ACTIVENI"
    else
	mode="PASSIVE"
    fi 			    
}

#function to create start node script without --raftJoinExisting flag
function createStartNodeScript(){
    
    cp lib/attach/start_quorum_template.sh ${sNode}/node/start_${sNode}.sh
    cp lib/attach/start_template.sh ${sNode}/start.sh
                
    chmod +x ${sNode}/start.sh
    chmod +x ${sNode}/node/start_${sNode}.sh
    
    cp lib/common.sh  ${sNode}/node
}

function createSetupScript() {
    echo 'NODENAME='${sNode} > ${sNode}/setup.conf
    echo 'WHISPER_PORT='${wPort} >> ${sNode}/setup.conf
    echo 'RAFT_PORT='${raPort} >> ${sNode}/setup.conf
    echo 'RPC_PORT='${rPort} >> ${sNode}/setup.conf
    echo 'CONSTELLATION_PORT='${cPort} >> ${sNode}/setup.conf
    echo 'THIS_NODEMANAGER_PORT='${tgoPort} >> ${sNode}/setup.conf
    echo 'CURRENT_IP='${pCurrentIp} >> ${sNode}/setup.conf
    echo 'PUBKEY='${publickey} >> ${sNode}/setup.conf
    echo 'REGISTERED=' >> ${sNode}/setup.conf
    echo 'CONTRACT_ADD=' >> ${sNode}/setup.conf    
    echo 'MODE='${mode} >> ${sNode}/setup.conf
    echo 'ROLE=Unassigned' >> ${sNode}/setup.conf
    echo 'RAFT_ID=0' >> ${sNode}/setup.conf
    echo 'STATE=NI' >> ${sNode}/setup.conf
}

function cleanup() {
    echo $sNode > .nodename
    rm -rf ${sNode}
    
    mkdir -p ${sNode}/node/contracts

    #cp lib/attach/genesis_template.json ${sNode}/node/genesis.json
    
    cp qm.variables $sNode
}

function main(){    
    getInputWithDefault 'Please enter node name' "" sNode $GREEN
    
    cleanup
    readInputs
    createStartNodeScript
    createSetupScript
        
}

main
