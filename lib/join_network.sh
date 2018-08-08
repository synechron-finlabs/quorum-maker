#!/bin/bash

source qm.variables
source lib/common.sh

function readParameters() {
    
    POSITIONAL=()
    while [[ $# -gt 0 ]]
    do
        key="$1"

        case $key in
            -n|--name)
            sNode="$2"
            shift # past argument
            shift # past value
            ;;
            --oip)
            pMainIp="$2"
            shift # past argument
            shift # past value
            ;;
            --onm)
            mgoPort="$2"
            shift # past argument
            shift # past value
            ;;
            --tip)
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

    if [[ -z "$sNode" && -z "$pMainIp" && -z "$mgoPort" && -z "$pCurrentIp" && -z "$rPort" && -z "$wPort" && -z "$cPort" && -z "$raPort" && -z "$tgoPort" && -z "$wsPort" ]]; then
        return
    fi

    if [[ -z "$sNode" || -z "$pMainIp" || -z "$mgoPort" || -z "$pCurrentIp" || -z "$rPort" || -z "$wPort" || -z "$cPort" || -z "$raPort" || -z "$tgoPort" || -z "$wsPort" ]]; then
        help
    fi

    NON_INTERACTIVE=true
}

function readInputs(){  
    
    if [ -z "$NON_INTERACTIVE" ]; then   
        getInputWithDefault 'Please enter IP Address of existing node' "" pMainIp $RED
        getInputWithDefault 'Please enter Node Manager Port of existing node' "" mgoPort $YELLOW
        getInputWithDefault 'Please enter IP Address of this node' "" pCurrentIp $RED
        getInputWithDefault 'Please enter RPC Port of this node' 22000 rPort $GREEN
        getInputWithDefault 'Please enter Network Listening Port of this node' $((rPort+1)) wPort $GREEN
        getInputWithDefault 'Please enter Constellation Port of this node' $((wPort+1)) cPort $GREEN
        getInputWithDefault 'Please enter Raft Port of this node' $((cPort+1)) raPort $PINK
        getInputWithDefault 'Please enter Node Manager Port of this node' $((raPort+1)) tgoPort $BLUE
        getInputWithDefault 'Please enter WS Port of this node' $((tgoPort+1)) wsPort $GREEN
    fi
    role="Unassigned"
    
}

#function to generate keyPair for node
 function generateKeyPair(){
    echo -ne "\n" | constellation-node --generatekeys=${sNode} 1>>/dev/null

    echo -ne "\n" | constellation-node --generatekeys=${sNode}a 1>>/dev/null

    mv ${sNode}*.*  ${sNode}/node/keys/.
    
 }

#function to create node initialization script
function createInitNodeScript(){
    cat lib/slave/init_template.sh > ${sNode}/init.sh
    chmod +x ${sNode}/init.sh
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
    Enode1=$Enode$pCurrentIp:$wPort$disc$raPort 
    echo $Enode1 > ${sNode}/node/enode.txt
    cp nodekey ${sNode}/node/qdata/geth/.
    rm enode.txt
    rm nodekey
}

#function to create node accout and append it into genesis.json file
function createAccount(){
    sAccountAddress="$(geth --datadir datadir --password lib/slave/passwords.txt account new 2>> /dev/null)"
    re="\{([^}]+)\}"
    if [[ $sAccountAddress =~ $re ]];
    then
        sAccountAddress="0x"${BASH_REMATCH[1]};
    fi
    mv datadir/keystore/* ${sNode}/node/qdata/keystore/${sNode}key
    rm -rf datadir
}

#function to create start node script without --raftJoinExisting flag
function copyScripts(){
    cp lib/slave/start_quorum_template.sh ${sNode}/node/start_${sNode}.sh
    
    cp lib/slave/start_template.sh ${sNode}/start.sh
                
    chmod +x ${sNode}/start.sh
    chmod +x ${sNode}/node/start_${sNode}.sh

    cp lib/slave/pre_start_check_template.sh ${sNode}/node/pre_start_check.sh

    cp lib/common.sh  ${sNode}/node

    cp lib/slave/constellation_template.conf ${sNode}/node/constellation.conf
}

function createSetupConf() {
    echo 'NODENAME='${sNode} > ${sNode}/setup.conf
    echo 'MASTER_IP='${pMainIp} >> ${sNode}/setup.conf
    echo 'WHISPER_PORT='${wPort} >> ${sNode}/setup.conf
    echo 'RAFT_PORT='${raPort} >> ${sNode}/setup.conf
    echo 'RPC_PORT='${rPort} >> ${sNode}/setup.conf
    echo 'CONSTELLATION_PORT='${cPort} >> ${sNode}/setup.conf
    echo 'THIS_NODEMANAGER_PORT='${tgoPort} >> ${sNode}/setup.conf
    echo 'MAIN_NODEMANAGER_PORT='${mgoPort} >> ${sNode}/setup.conf
    echo 'WS_PORT='${wsPort} >> ${sNode}/setup.conf
    echo 'CURRENT_IP='${pCurrentIp} >> ${sNode}/setup.conf
    echo 'REGISTERED=' >> ${sNode}/setup.conf
    echo 'MODE=ACTIVE' >> ${sNode}/setup.conf
    echo 'STATE=I' >> ${sNode}/setup.conf
}

function cleanup() {
    echo $sNode > .nodename
    rm -rf ${sNode}
    mkdir -p ${sNode}/node/keys
    mkdir -p ${sNode}/node/contracts
    mkdir -p ${sNode}/node/qdata
    mkdir -p ${sNode}/node/qdata/{keystore,geth,logs}
    cp qm.variables $sNode
}

function main(){    

    readParameters $@

    if [ -z "$NON_INTERACTIVE" ]; then        
        getInputWithDefault 'Please enter node name' "" sNode $GREEN
    fi
    
    cleanup
    readInputs
    generateKeyPair
    createInitNodeScript
    generateEnode
    copyScripts
    createSetupConf
    createAccount
    
}

main $@
