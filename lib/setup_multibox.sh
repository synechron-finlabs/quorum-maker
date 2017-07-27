#!/bin/bash

function createStartNodeScript(){
    cat lib/start_node.sh > ${pName}/$nodeName/start.sh

    START_CMD="start_$nodeName.sh"

    PATTERN="s/#start_cmd#/${START_CMD}/g"
    sed -i $PATTERN ${pName}/${nodeName}/start.sh

    chmod +x ${pName}/${nodeName}/start.sh

}

function createBootnode(){

    bootnode -genkey bootnode.key 2> enode.txt &
    bnPid=$!
    sleep 2
    kill -9 $bnPid
    wait $bnPid 2> /dev/null

    re="enode:.*@"

    enode=$(cat enode.txt)

    if [[ $enode =~ $re ]];
    then
        bootnodeEnode=${BASH_REMATCH[0]};
        bootnodeHex=$(cat bootnode.key)

    fi

    rm enode.txt
    rm bootnode.key

}

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

    sed $PATTERN lib/template.conf > ${pName}/setup/${nodeName}.conf

    otherNodeUrl=""

    nodeName1=${nodes[0]}
    
    if [ "$nodeName" = "$nodeName1" ]; then
        echo "otherNodeUrls = []" >> ${pName}/setup/${nodeName}.conf
    else
        echo "otherNodeUrls = [\"http://#MAIN_NODE_IP#:#M_C_PORT#/\"]" >> ${pName}/setup/${nodeName}.conf
    fi

}

function executeInit(){
    j=0
    while : ; do
        
        nodeName=${nodes[j]}
        cd ${pName}

        mkdir -p ${nodeName}/qdata/logs
        mkdir -p ${nodeName}/qdata/keystore
        mkdir -p ${nodeName}/keys

        cp keys/${nodeName}*.key  ${nodeName}/keys
        cp keys/${nodeName}*.pub  ${nodeName}/keys
        
        if [ -f "keys/${nodeName}BM" ]
        then
            cp keys/${nodeName}BM  ${nodeName}/qdata/keystore/${nodeName}BM
            
        fi

        if [ -f "keys/${nodeName}V" ]
        then
            cp keys/${nodeName}V ${nodeName}/qdata/keystore/${nodeName}V
        fi

        geth --datadir ${nodeName}/qdata init genesis.json

        cp setup/${nodeName}.conf ${nodeName}/qdata/${nodeName}.conf

        cp setup/start_${nodeName}.sh ${nodeName}/start_${nodeName}.sh

        chmod +x ${nodeName}/start_${nodeName}.sh

        mkdir node
        mv -f $nodeName/* node/
        mv -f node $nodeName/
        mv $nodeName/node/start.sh $nodeName/

        nodeName1=${nodes[0]}
        if [ "$nodeName" = "$nodeName1" ]; then

            PATTERN="s/#COMMENT_IF_MASTER#/#/g"
            sed -i $PATTERN ${nodeName}/start.sh

            PATTERN="s/#COMMENT_IF_SLAVE#//g"
            sed -i $PATTERN ${nodeName}/start.sh

        else
            PATTERN="s/#COMMENT_IF_MASTER#//g"
            sed -i $PATTERN ${nodeName}/start.sh

            PATTERN="s/#COMMENT_IF_SLAVE#/#/g"
            sed -i $PATTERN ${nodeName}/start.sh

        fi


        zip -r $nodeName.zip $nodeName

        rm -rf $nodeName
        
        cd ..

        let "j++"
        
        if [ $i -eq $j ]; then
            break;
        fi
    done
}

function copyStartTemplate(){

    cat lib/start_template_common.sh > ${pName}/setup/start_${nodeName}.sh
    
    nodeName1=${nodes[0]}
    if [ "$nodeName" = "$nodeName1" ]; then
        cat lib/start_bootnode.sh >> ${pName}/setup/start_${nodeName}.sh

        PATTERN="s/#bootnode_keyhex#/${bootnodeHex}/g"
        sed -i $PATTERN ${pName}/setup/start_${nodeName}.sh

    fi

    cat lib/start_template.sh >> ${pName}/setup/start_${nodeName}.sh

    PATTERN="s|#bootnode_enode#|${bootnodeEnode}|g"
    sed -i $PATTERN ${pName}/setup/start_${nodeName}.sh

    PATTERN="s/#nodeName#/${nodeName}/g"
    sed -i $PATTERN ${pName}/setup/start_${nodeName}.sh

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

}

function generateKeyPair(){
    echo "Generating public and private keys for " ${nodeName}", Please enter password or leave blank"
    constellation-node --generatekeys=${nodeName}

    echo "Generating public and private backup keys for " ${nodeName}", Please enter password or leave blank"
    constellation-node --generatekeys=${nodeName}a

    mv ${nodeName}*.* ${pName}/keys

    mkdir -p ${pName}/$nodeName/keys
    cp ${pName}/keys/${nodeName}*.key  ${pName}/${nodeName}/keys
    cp ${pName}/keys/${nodeName}*.pub  ${pName}/${nodeName}/keys


}

function createNode(){
    nodeName=$1

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
        * ) ;;
    esac

    copyStartTemplate
    createStartNodeScript
}

function writeGenesisConfig(){
    echo "{" > ${pName}/quorum-config.json
    echo "    \"threshold\":$voterIndex," >> ${pName}/quorum-config.json
    echo "    \"makers\": [" >> ${pName}/quorum-config.json

    j=0
    comma=","
    while [ $j -lt $blockMakerIndex ]
    do
        let k="(( $j + 1 ))"
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

function main(){

    read -p $'\e[1;33mPlease enter a project name: \e[0m' pName
    
    rm -rf ${pName}
    mkdir -p ${pName}/keys
    mkdir -p ${pName}/setup
    mkdir -p ${pName}/datadir

    singleBlockMakerSelected=""
    multipleBlockMakerCreated=""

    i=0
    blockMakerIndex=0
    voterIndex=0

    createBootnode
    
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
            * ) break;;
        esac

    done

    generateGenesis

    executeInit "${nodes[@]}" "${i}"
    
    echo -e '\e[1;32mSuccessfully created project:\e[0m' $pName

    displayPublicAddress

    cleanup
}

main
