#!/bin/bash

function createBlockMaker(){

    if [ -z "$multipleBlockMakerCreated" ]; then
        read -p $'\e[1;31mIs this the only block maker ? [y/N]: \e[0m' yn
        case $yn in
            [Yy]* )
                singleBlockMakerSelected="yes"
                singleBlockMakerPattern=" --singleblockmaker";;
            * ) ;;
        esac

    fi

    multipleBlockMakerCreated="yes"

    blockMakerAddress="$(geth --datadir ${pName}/datadir --password lib/passwords.txt account new)"
    
    re="\{([^}]+)\}"
    if [[ $blockMakerAddress =~ $re ]];
    then
        blockMakerAddress="0x"${BASH_REMATCH[1]};

        blockMakers[$blockMakerIndex]=$blockMakerAddress
        let "blockMakerIndex++"

    fi

    mv ${pName}/datadir/keystore/* ${pName}/keys/${nodeName}BM
    
}

function createVoter(){

    voterAddress="$(geth --datadir ${pName}/datadir --password lib/passwords.txt account new)"

    re="\{([^}]+)\}"
    if [[ $voterAddress =~ $re ]];
    then
        voterAddress="0x"${BASH_REMATCH[1]};

        voters[$voterIndex]=$voterAddress
        let "voterIndex++"
    fi
    
    mv ${pName}/datadir/keystore/* ${pName}/keys/${nodeName}V

}

function copyConfTemplate(){
    PATTERN="s/#nodeName#/${nodeName}/g"
    nodeName1=${nodes[0]}
    PATTERN2="s/#nodeName1#/${nodeName1}/g"

    sed $PATTERN lib/template_docker.conf > ${pName}/setup/${nodeName}1.conf
    sed $PATTERN2 ${pName}/setup/${nodeName}1.conf > ${pName}/setup/${nodeName}.conf
}

function createDockerComposeFile(){
    j=0

    tmpPort=$pPort
    
    if [ -z "$tmpPort" ]; then

        tmpPort="22000"

    fi

    while : ; do
        
        nodeName=${nodes[j]}
        nodeName1=${nodes[0]}
    
        PATTERN5="s/#nodeName1#/${nodeName1}/g"   
        PATTERN="s/#nodeName#/${nodeName}/g"
        PATTERN2="s/#nodeport#/${tmpPort}/g"
        PATTERN3="s/#pName#/${pName}/g"
        PWD="$(pwd)"
        PATTERN4="s:#PWD#:${PWD}:g"
        PATTERN6="s/#docker_ip#/$((j+4))/g"

        sed $PATTERN lib/template.yml > ${pName}/setup/compose_${nodeName}.yml

        sed -i "$PATTERN2" ${pName}/setup/compose_${nodeName}.yml
        sed -i "$PATTERN3" ${pName}/setup/compose_${nodeName}.yml
        sed -i "$PATTERN4" ${pName}/setup/compose_${nodeName}.yml
        sed -i "$PATTERN5" ${pName}/setup/compose_${nodeName}.yml
        sed -i "$PATTERN6" ${pName}/setup/compose_${nodeName}.yml        

        cat ${pName}/setup/compose_${nodeName}.yml >> ${pName}/docker-compose.yml


        let "j++"
        let "tmpPort++"
        
        if [ $i -eq $j ]; then
            break;
        fi
    done
    
}

function createRaftDockerComposeFile(){
    j=0

    tmpPort=$pPort
    
    if [ -z "$tmpPort" ]; then

        tmpPort="22000"

    fi

    cat lib/common.yml > ${pName}/.raft_docker-compose.yml
    
    while : ; do
        
        nodeName=${nodes[j]}
        nodeName1=${nodes[0]}
    
        PATTERN5="s/#nodeName1#/${nodeName1}/g"   
        PATTERN="s/#nodeName#/${nodeName}/g"
        PATTERN2="s/#nodeport#/${tmpPort}/g"
        PATTERN3="s/#pName#/${pName}/g"
        PATTERN6="s/#docker_ip#/$((j+4))/g"
        PWD="$(pwd)"
        PATTERN4="s:#PWD#:${PWD}:g"
        
        sed $PATTERN lib/raft_template.yml > ${pName}/setup/raft_compose_${nodeName}.yml

        sed -i "$PATTERN2" ${pName}/setup/raft_compose_${nodeName}.yml
        sed -i "$PATTERN3" ${pName}/setup/raft_compose_${nodeName}.yml
        sed -i "$PATTERN4" ${pName}/setup/raft_compose_${nodeName}.yml
        sed -i "$PATTERN5" ${pName}/setup/raft_compose_${nodeName}.yml
        sed -i "$PATTERN6" ${pName}/setup/raft_compose_${nodeName}.yml        

        cat ${pName}/setup/raft_compose_${nodeName}.yml >> ${pName}/.raft_docker-compose.yml

        let "j++"
        let "tmpPort++"
        
        if [ $i -eq $j ]; then
            break;
        fi
    done
    
}


function copyStartTemplate(){

    PATTERN="s/#nodeName#/${nodeName}/g"
    
    sed $PATTERN lib/start_docker_template.sh > ${pName}/setup/start_${nodeName}.sh
    

    nodeName1=${nodes[0]}
    PATTERN2="s/#nodeName1#/${nodeName1}/g"

    blockMakerPattern=""
    if [ ! -z "$blockMakerAddress" ]; then
        blockMakerPattern="--blockmakeraccount \""$blockMakerAddress"\" --blockmakerpassword \"\" $singleBlockMakerPattern" 
    fi

    PATTERN="s/#blockMakerPattern#/${blockMakerPattern}/g"

    sed -i "$PATTERN" ${pName}/setup/start_${nodeName}.sh
    
    voterPattern=""

    if [ ! -z "$voterAddress" ]; then
        voterPattern="--voteaccount \""$voterAddress"\" --votepassword \"\""
    fi

    PATTERN="s/#voterPattern#/${voterPattern}/g"

    sed -i "$PATTERN" ${pName}/setup/start_${nodeName}.sh
    sed -i "$PATTERN2" ${pName}/setup/start_${nodeName}.sh

    if [ "$nodeName1" = "$nodeName" ]; then
        PATTERN="s/#delay#/2/g"
        sed -i "$PATTERN" ${pName}/setup/start_${nodeName}.sh
    else
        PATTERN="s/#delay#/10/g"
        sed -i "$PATTERN" ${pName}/setup/start_${nodeName}.sh
    fi

    cp ${pName}/setup/start_${nodeName}.sh ${pName}/${nodeName}/start_node.sh
    chmod +x ${pName}/${nodeName}/start_node.sh
    cp ${pName}/${nodeName}/start_node.sh ${pName}/${nodeName}/qdata/start_qc_node.sh
    

    cp lib/stop.sh ${pName}/${nodeName}/stop.sh
    
    chmod +x ${pName}/${nodeName}/stop.sh
}

function copyRaftStartTemplate(){

    PATTERN="s/#nodeName#/${nodeName}/g"
    sed $PATTERN lib/start_raft_docker_template.sh > ${pName}/setup/start_raft_${nodeName}.sh
    
    sed -i "$PATTERN2" ${pName}/setup/start_raft_${nodeName}.sh

}

function executeInit(){

    cp lib/switch_consensus.sh ${pName}
    chmod +x ${pName}/switch_consensus.sh

    cp lib/reset_chain.sh ${pName}
    chmod +x ${pName}/reset_chain.sh

    j=0
    while : ; do
        
        nodeName=${nodes[j]}
        cd ${pName}

        mkdir -p ${nodeName}/qdata/logs
        mkdir -p ${nodeName}/qdata/keystore
        mkdir -p ${nodeName}/keys

        cp keys/${nodeName}*.key  ${nodeName}/keys
        cp keys/${nodeName}*.pub  ${nodeName}/keys

        cp ../lib/switch_consensus_node.sh ${nodeName}
        chmod +x ${nodeName}/switch_consensus_node.sh

        cp ../lib/reset_chain_node.sh ${nodeName}
        chmod +x ${nodeName}/reset_chain_node.sh

        cp setup/start_raft_${nodeName}.sh ${nodeName}/qdata/start_raft_node.sh
        chmod +x ${nodeName}/qdata/start_raft_node.sh
        
        
        if [ -f "keys/${nodeName}BM" ]
        then
            cp keys/${nodeName}BM  ${nodeName}/qdata/keystore/${nodeName}BM
            
        fi

        if [ -f "keys/${nodeName}V" ]
        then
            cp keys/${nodeName}V ${nodeName}/qdata/keystore/${nodeName}V
        fi

        geth --datadir ${nodeName}/qdata init genesis.json
        cp genesis.json ${nodeName}/genesis.json

        cp setup/${nodeName}.conf ${nodeName}/${nodeName}.conf
        cp setup/${nodeName}.conf ${nodeName}/qdata/${nodeName}.conf
        
        cd ..

        let "j++"
        
        if [ $i -eq $j ]; then
            break;
        fi
    done
}

function generateKeyPair(){
    echo "Generating public and private keys for " ${nodeName}", Please enter password or leave blank"
    constellation-node --generatekeys=${nodeName}

    echo "Generating public and private backup keys for " ${nodeName}", Please enter password or leave blank"
    constellation-node --generatekeys=${nodeName}a

    mv ${nodeName}*.* ${pName}/keys

}

function createNode(){
    nodeName=$1

    mkdir -p $pName/$nodeName

    mkdir -p $pName/${nodeName}/qdata/logs
    mkdir -p $pName/${nodeName}/qdata/keystore
    mkdir -p $pName/${nodeName}/keys

    blockMakerAddress=""
    voterAddress=""
    singleBlockMakerPattern=""

    generateKeyPair
    copyConfTemplate

    if [ -z "$singleBlockMakerSelected" ]; then
        read -p $'\e[1;36mIs this a Block Maker Node? [y/N]: \e[0m' yn
        case $yn in
            [Yy]* )
                createBlockMaker ${nodeName}
                ;;
            * ) ;;
        esac

    fi

    read -p $'\e[1;34mIs this a Voter Node? [y/N]: \e[0m' yn
    case $yn in
        [Yy]* )
            createVoter ${nodeName}
            ;;
        [Nn]* ) ;;
        * ) ;;
    esac

    copyStartTemplate
    copyRaftStartTemplate
    
}

function writeGenesisConfig(){
    echo "{" > ${pName}/quorum-config.json
    echo "    \"threshold\":$voterIndex," >> ${pName}/quorum-config.json
    echo "    \"makers\": [" >> ${pName}/quorum-config.json
    
    j=0
    comma=","
    while [ $j -lt $blockMakerIndex ]
    do
        let k="(( $j + 1))"
        if [ $k -eq $blockMakerIndex ];
        then comma=""
        fi

        echo     \"${blockMakers[$j]}\"$comma >> ${pName}/quorum-config.json
        let "j++"
    done
    echo "    ]," >> ${pName}/quorum-config.json

    j=0
    comma=","
    echo "    \"voters\": [" >> ${pName}/quorum-config.json
    while [ $j -lt $voterIndex ]
    do
        let k="(( $j + 1 ))"
        if [ $k -eq $voterIndex ];
        then comma=""
        fi

        echo     \"${voters[$j]}\"$comma >> ${pName}/quorum-config.json
        let "j++"
    done
    echo "    ]" >> ${pName}/quorum-config.json

    echo "}" >> ${pName}/quorum-config.json

}

function generateGenesis(){
    writeGenesisConfig
    
    cd ${pName}
    quorum-genesis

    cd ..
    rm -f ${pName}/quorum-config.json
    rm -rf quorum-genesis
    
    mv ${pName}/quorum-genesis.json ${pName}/genesis.json
}

function cleanup(){
    rm -rf ${pName}/datadir
    rm -rf ${pName}/keys
    rm -rf ${pName}/setup
    rm -f ${pName}/genesis.json
    
}

function displayPublicAddress(){

    if [ $i -ge 1 ]; then
        echo "Please use following public address for private transactions between nodes"
        echo "--------------------------------------------------------------------------"
        j=0
        while [ $j -lt $i ]
        do
            
            eval "a=${pName}[${j}]"
            echo ${!a} $(cat $pName/keys/${!a}.pub)
            let "j++"
        done
        echo "--------------------------------------------------------------------------"
    else
        echo "No nodes were created"

    fi
    
}

function createBootnodeYml(){

    mkdir -p ${pName}/bootnode/qdata/logs

    cp lib/start_docker_bootnode.sh ${pName}/bootnode/start_bootnode.sh

    cat lib/common.yml > ${pName}/docker-compose.yml

    cat lib/bootnode.yml >> ${pName}/docker-compose.yml

    PATTERN="s/#pName#/${pName}/g"
    sed -i $PATTERN ${pName}/docker-compose.yml

    PWD="$(pwd)"
    PATTERN="s:#PWD#:${PWD}:g"
    sed -i $PATTERN ${pName}/docker-compose.yml

}


function main(){

    read -p $'\e[1;33mPlease enter a project name: \e[0m' pName
    read -p $'\e[1;34mPlease enter the start port number [Default:22000]: \e[0m' pPort

    rm -rf ${pName}
    mkdir -p ${pName}/keys
    mkdir -p ${pName}/setup
    mkdir -p ${pName}/datadir

    singleBlockMakerPattern=""
    singleBlockMakerSelected=""
    
    i=0
    blockMakerIndex=0
    voterIndex=0
    

    while : ; do

        read -p $'\e[1;32mPlease enter node name: \e[0m' ${pName}[${i}] 
        eval "nodeName=${pName}[${i}]"
        nodes[i]=${!nodeName}
        
        createNode ${!nodeName}

        let "i++"

        read -p $'\e[1;35mDo you wish to add more nodes? [y/N]: \e[0m' yn
        case $yn in
            [Yy]* )
                continue;;
            * ) break ;;
        esac
    done
    
    createBootnodeYml
    createDockerComposeFile "${nodes[@]}" "${i}"
    createRaftDockerComposeFile "${nodes[@]}" "${i}"
    generateGenesis
    executeInit "${nodes[@]}" "${i}"

    echo -e '\e[1;32mSuccessfully created project:\e[0m' $pName

    displayPublicAddress
    cleanup    
}

main
