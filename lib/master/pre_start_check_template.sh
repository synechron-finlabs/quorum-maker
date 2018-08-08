#!/bin/bash

source qm.variables
source node/common.sh

function readParameters() {
    
    POSITIONAL=()
    while [[ $# -gt 0 ]]
    do
        key="$1"

        case $key in
            --ip)
            pCurrentIp="$2"
            shift # past argument
            shift # past value
            ;;
            -r|--rpc)
            rPort="$2"
            shift # past argument
            shift # past value
            ;;
            -w|--whisper)
            wPort="$2"
            shift # past argument
            shift # past value
            ;;
            -c|--constellation)
            cPort="$2"
            shift # past argument
            shift # past value
            ;;
            --raft)
            raPort="$2"
            shift # past argument
            shift # past value
            ;;
            --nm)
            tgoPort="$2"
            shift # past argument
            shift # past value
            ;;
            --ws)
            wsPort="$2"
            shift # past argument
            shift # past value
            ;;            
            *)    # unknown option
            POSITIONAL+=("$1") # save it in an array for later
            shift # past argument
            ;;
        esac
    done
    set -- "${POSITIONAL[@]}" # restore positional parameters

    if [[ -z "$pCurrentIp" && -z "$rPort" && -z "$wPort" && -z "$cPort" && -z "$raPort" && -z "$tgoPort" && -z "$wsPort" ]]; then
        return
    fi

    if [[ -z "$pCurrentIp" || -z "$rPort" || -z "$wPort" || -z "$cPort" || -z "$raPort" || -z "$tgoPort" || -z "$wsPort" ]]; then
        help
    fi

    NON_INTERACTIVE=true
}

# read inputs to create network
function readInputs(){   
    
    if [ -z "$NON_INTERACTIVE" ]; then

        getInputWithDefault 'Please enter IP Address of this node' "" pCurrentIp $RED
        
        getInputWithDefault 'Please enter RPC Port of this node' 22000 rPort $GREEN
        
        getInputWithDefault 'Please enter Network Listening Port of this node' $((rPort+1)) wPort $GREEN
        
        getInputWithDefault 'Please enter Constellation Port of this node' $((wPort+1)) cPort $GREEN
        
        getInputWithDefault 'Please enter Raft Port of this node' $((cPort+1)) raPort $PINK
        
        getInputWithDefault 'Please enter Node Manager Port of this node' $((raPort+1)) tgoPort $BLUE

        getInputWithDefault 'Please enter WS Port of this node' $((tgoPort+1)) wsPort $GREEN
            
    fi
    role="Unassigned"
	
    #append values in Setup.conf file 
    echo 'CURRENT_IP='$pCurrentIp > ./setup.conf
    echo 'RPC_PORT='$rPort >> ./setup.conf
    echo 'WHISPER_PORT='$wPort >> ./setup.conf
    echo 'CONSTELLATION_PORT='$cPort >> ./setup.conf
    echo 'RAFT_PORT='$raPort >> ./setup.conf
    echo 'THIS_NODEMANAGER_PORT='$tgoPort >>  ./setup.conf
    echo 'WS_PORT='$wsPort >>  ./setup.conf
        
    echo 'NETWORK_ID='$net >>  ./setup.conf
    echo 'RAFT_ID='1 >>  ./setup.conf
    echo 'NODENAME='$nodeName >> ./setup.conf
    echo 'ROLE='$role >> ./setup.conf
    echo 'CONTRACT_ADD=' >> ./setup.conf
    echo 'REGISTERED=' >> ./setup.conf
    echo 'MODE=ACTIVE' >> ./setup.conf
    echo 'STATE=I' >> ./setup.conf
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


# static node to create network 
function staticNode(){
    PATTERN1="s/#CURRENT_IP#/$pCurrentIp/g"
    PATTERN2="s/#W_PORT#/${wPort}/g"
    PATTERN3="s/#raftPprt#/${raPort}/g"

    sed -i "$PATTERN1" node/qdata/static-nodes.json
    sed -i "$PATTERN2" node/qdata/static-nodes.json
    sed -i "$PATTERN3" node/qdata/static-nodes.json
}

function generateConstellationConf() {
    PATTERN1="s/#CURRENT_IP#/${pCurrentIp}/g"
    PATTERN2="s/#C_PORT#/$cPort/g"
    PATTERN3="s/#mNode#/$nodeName/g"

    sed -i "$PATTERN1" node/constellation.conf
    sed -i "$PATTERN2" node/constellation.conf
    sed -i "$PATTERN3" node/constellation.conf
}

function main(){
    net=#netid#
    nodeName=#nodename#

    readParameters $@

    if [ ! -f setup.conf ]; then

        readInputs
        staticNode
        generateConstellationConf

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
main $@
