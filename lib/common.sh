
RED=$'\e[1;31m'
GREEN=$'\e[1;32m'
YELLOW=$'\e[1;33m'
BLUE=$'\e[1;34m'
PINK=$'\e[1;35m'
CYAN=$'\e[1;96m'
WHITE=$'\e[1;39m'
COLOR_END=$'\e[0m'

function getInputWithDefault() {
    local msg=$1
    local __defaultValue=$2
    local __resultvar=$3
    local __clr=$4
    
    if [ -z "$__clr" ]; then

        __clr=$RED

    fi

    if [ -z "$__defaultValue" ]; then

       read -p $__clr"$msg: "$COLOR_END __newValue
    else
        read -p $__clr"$msg""[Default:"$__defaultValue"]:"$COLOR_END __newValue
    fi
    
    
    if [ -z "$__newValue" ]; then

        __newValue=$__defaultValue

    fi

    eval $__resultvar="'$__newValue'"
}

function updateProperty() {
    local file=$1
    local key=$2
    local value=$3
  
    if grep -q $key= $file; then        
        sed -i "s/$key=.*/$key=$value/g" $file
    else
        echo "" >> $file
        echo $key=$value >> $file
    fi
    sed -i '/^$/d' $file
}

function displayProgress(){
    local __TOTAL=$1
    local __CURRENT=$2

    let __PER=$__CURRENT*100/$__TOTAL
    
    local __PROG=""

    local __j=0
    while : ; do  

        if [ $__j -lt $__PER ]; then
            __PROG+="#"
        else
            __PROG+=" "
        fi

        if [ $__j -eq 100 ]; then
            break;
        fi
        let "__j+=2"
    done

    echo -ne ' ['${YELLOW}"${__PROG}"${COLOR_END}']'$GREEN'('$__PER'%)'${COLOR_END}'\r'

    if [ $__TOTAL -eq $__CURRENT ]; then
            echo ""
            break;
    fi

}

function help(){
    echo ""
    echo -e $WHITE'Usage ./setup.sh [COMMAND] [OPTIONS]'$COLOR_END
    echo ""
    echo "Utility to setup Quorum Network"
    echo ""
    echo "Commands:"
    echo -e $GREEN'create'$COLOR_END    "   Create a new Node. The node hosts Quorum, Constellation and Node Manager"
    echo -e $PINK'join'$COLOR_END       "     Create a node and Join to existing Network"
    echo -e $BLUE'attach'$COLOR_END     "   Attach to an existing Quorum Node. The node created hosts only Node Manager"
    echo -e $CYAN'dev'$COLOR_END        "      Create a development/test network with multiple nodes"
    echo ""
    echo "Options:"
    echo ""
    echo "For create command:"
    echo "  -n, --name              Name of the node to be created"
    echo "  --ip                    IP address of this node (IP of the host machine)"
    echo "  -r, --rpc               RPC port of this node"
    echo "  -w, --whisper           Discovery port of this node"
    echo "  -c, --constellation     Constellation port of this node"
    echo "  --raft                  Raft port of this node"
    echo "  --nm                    Node Manager port of this node"
    echo "  --ws                    Web Socket port of this node"
    echo ""
    echo "E.g."
    echo "./setup.sh create -n master --ip 10.0.2.15 -r 22000 -w 22001 -c 22002 --raft 22003 --nm 22004 --ws 22005"
    echo ""
    echo "For join command:"
    echo "  "
    echo "  -n, --name              Name of the node to be created"
    echo "  --oip                   IP address of the other node (IP of the existing node)"
    echo "  --onm                   Node Manager port of the other node"
    echo "  --tip                   IP address of this node (IP of the host machine)"
    echo "  -r, --rpc               RPC port of this node"
    echo "  -w, --whisper           Discovery port of this node"
    echo "  -c, --constellation     Constellation port of this node"
    echo "  --raft                  Raft port of this node"
    echo "  --nm                    Node Manager port of this node"
    echo "  --ws                    Web Socket port of this node"
    echo ""
    echo "E.g."
    echo "./setup.sh join -n slave1 --oip 10.0.2.15 --onm 22004 --tip 10.0.2.15 -r 23000 -w 23001 -c 23002 --raft 23003 --nm 23004 --ws 23005"
    echo ""
    echo "For attach command:"
    echo "  -n, --name              Name of the node to be created"
    echo "  --ip                    IP address of existing Quorum"
    echo "  --pk                    Public Key of existing Constellation"
    echo "  -r, --rpc               RPC port of the existing Quorum"   
    echo "  -w, --whisper           Discovery port of this node" 
    echo "  -c, --constellation     Constellation port existing node"
    echo "  --raft                  Raft port of existing node"
    echo "  --nm                    Node Manager port of this node (New Node Manager will be created by this command)"
    echo "  --active                Active attachment mode"
    echo "  --passive               Passive attachment mode"
    echo ""
    echo "E.g."
    echo "./setup.sh attach -n slave1 --ip 10.0.2.15 --pk BULeR8JyUWhiuuCMU/HLA0Q5pzkYT+cHII3ZKBey3Bo= -r 22000 --whisper 21000 --constellation 9001 --raft 50401 --nm 11004 --active"
    echo ""
    echo "For dev command:"
    echo "  -p, --project           Project Name"
    echo "  -n, --nodecount         Number of nodes to be created"
    echo ""
    echo "E.g."
    echo "./setup.sh dev -p TestNetwork -n 3"
    echo ""
    echo "-h, --help              Display this help and exit"

    exit
}

pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}
