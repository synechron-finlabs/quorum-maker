#!/bin/bash

 function copyConfTemplate(){
     PATTERN="s/#mNode#/${mNode}/g"
     sed $PATTERN lib/template.conf > ${mNode}/node/${mNode}.conf
     PATTERN="/"
     otherNodeUrl=""
     mNode1=${nodes[0]}

    PATTERN="s/#cport#/${cPort}/g"
    sed -i $PATTERN ${mNode}/node/${mNode}.conf
 }

 function generateKeyPair(){
    echo "Generating public and private keys for " ${mNode}", Please enter password or leave blank"
    constellation-node --generatekeys=${mNode}

    echo "Generating public and private backup keys for " ${mNode}", Please enter password or leave blank"
    constellation-node --generatekeys=${mNode}a

    mv ${mNode}*.*  ${mNode}/node/keys/.
 }


function createInitNodeScript(){
    cat lib/init.sh > ${mNode}/init.sh

    START_CMD="start_$mNode.sh"

    PATTERN="s/#start_cmd#/${START_CMD}/g"
    sed -i $PATTERN ${mNode}/init.sh

    chmod +x ${mNode}/init.sh
}

function copyStartTemplate(){
    NET_ID=$(awk -v min=10000 -v max=99999 -v freq=1 'BEGIN{srand(); for(i=0;i<freq;i++)print int(min+rand()*(max-min+1))}')
    PATTERN="s|#network_Id_value#|${NET_ID}|g"
    cat lib/start_template_common.sh > ${mNode}/node/start_${mNode}.sh
    sed -i $PATTERN ${mNode}/node/start_${mNode}.sh
    cat lib/start_template.sh >> ${mNode}/node/start_${mNode}.sh
    PATTERN="s/#mNode#/${mNode}/g"
    sed -i $PATTERN ${mNode}/node/start_${mNode}.sh
}

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
    rm enode.txt
    rm nodekey
}


function createAccount(){
    mAccountAddress="$(geth --datadir datadir --password lib/passwords.txt account new)"
    re="\{([^}]+)\}"
    if [[ $mAccountAddress =~ $re ]];
    then
        mAccountAddress="0x"${BASH_REMATCH[1]};

        mMakers[$mNodeIndex]=$mAccountAddress
        let "mNodeIndex++"
    fi
    mv datadir/keystore/* ${mNode}/node/qdata/keystore/${mNode}key
    rm -rf datadir

}

# function writeGenesisConfig(){
#     git clone https://github.com/davebryson/quorum-genesis.git
#     cd quorum-genesis
#     echo "{" > ${mNode}/quorum-config.json
#     echo "    \"threshold\":$voterIndex," >> ${mNode}/quorum-config.json
#     echo "    \"makers\": [" >> ${mNode}/quorum-config.json

#     j=0
#     comma=","
#     while [ $j -lt $mNodeIndex ]
#     do
#         let k="(( $j + 1 ))"
#         if [ $k -eq $mNodeIndex ];
#         then comma=""
#         fi

#         echo     \"${mMakers[$j]}\"$comma >> ${mNode}/quorum-config.json
#         let "j++"
#     done
#     echo "    ]," >> ${mNode}/quorum-config.json
#     cp quorum-config.json ./${mNode}/.

# }

# function generateGenesis(){
#     writeGenesisConfig
#     #cp quorum-config.json ./${mNode}/.
#     cd ${mNode}
#     npm init
#     npm install -g
#     quorum-genesis
#     cd ..
#     rm -f ${mNode}/quorum-config.json
#     rm -rf quorum-genesis
    
#     mv ${mNode}/quorum-genesis.json ${mNode}/genesis.json
# }

function main(){    
    read -p $'\e[1;32mPlease enter master node name: \e[0m' mNode 
    rm -rf ${mNode}
    mkdir -p ${mNode}/node/keys
    mkdir -p ${mNode}/node/qdata
    mkdir -p ${mNode}/node/qdata/{keystore,geth,logs}
    copyConfTemplate
    generateKeyPair
    createInitNodeScript
    copyStartTemplate
    createAccount
    #generateGenesis
    generateEnode
}
main
