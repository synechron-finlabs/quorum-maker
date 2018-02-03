#!/bin/bash
username=$(whoami)


function copyConfTemplate(){
    
    PATTERN="s/#nodeName#/${nodeName}/g"
    nodeName1=${nodes[0]}
    PATTERN2="s/#nodeName1#/${nodeName1}/g"

    sed $PATTERN lib/qourum.conf > ${pName}/setup/${nodeName}1.conf
    sed $PATTERN2 ${pName}/setup/${nodeName}1.conf > ${pName}/setup/${nodeName}.conf
    cp ${pName}/setup/${nodeName}.conf ${pName}/${nodeName}/qdata/${nodeName}.conf
}


function createRaftDockerComposeFile(){
    
    j=0

    tmpPort=$pPort
    
    if [ -z "$tmpPort" ]; then

        tmpPort="22000"

    fi

    cat lib/common.yml > ${pName}/docker-compose.yml
    
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
        
        sed $PATTERN lib/docker_compose.yml > ${pName}/setup/raft_compose_${nodeName}.yml

        sed -i "$PATTERN2" ${pName}/setup/raft_compose_${nodeName}.yml
        sed -i "$PATTERN3" ${pName}/setup/raft_compose_${nodeName}.yml
        sed -i "$PATTERN4" ${pName}/setup/raft_compose_${nodeName}.yml
        sed -i "$PATTERN5" ${pName}/setup/raft_compose_${nodeName}.yml
        sed -i "$PATTERN6" ${pName}/setup/raft_compose_${nodeName}.yml  
        sed -i "$PATTERN7" ${pName}/setup/raft_compose_${nodeName}.yml        

        cat ${pName}/setup/raft_compose_${nodeName}.yml >> ${pName}/docker-compose.yml

        let "j++"
        let "tmpPort++"
        
        if [ $i -eq $j ]; then
            break;
        fi
    done
    
}



function copyRaftStartTemplate(){

    PATTERN="s/#nodeName#/${nodeName}/g"
    sed $PATTERN lib/start_raft.sh > ${pName}/setup/start_raft_${nodeName}.sh
    sed -i "$PATTERN2" ${pName}/setup/start_raft_${nodeName}.sh

    cp ${pName}/setup/start_raft_${nodeName}.sh ${pName}/${nodeName}/start_node.sh

    chmod +x ${pName}/${nodeName}/start_node.sh

    cp ${pName}/${nodeName}/start_node.sh ${pName}/${nodeName}/qdata/start_raft_node.sh
    
}

function executeInit(){

    cp lib/reset_chain.sh ${pName}

    chmod +x ${pName}/reset_chain.sh

    j=0
    while : ; do
        
        nodeName=${nodes[j]}
        cd ${pName}

        mkdir -p ${nodeName}/qdata
        mkdir -p ${nodeName}/qdata/{keystore,geth,logs}
        mkdir -p ${nodeName}/keys

        cp keys/${nodeName}*.key  ${nodeName}/keys
        cp keys/${nodeName}*.pub  ${nodeName}/keys 
        cp ../lib/reset_chain_node.sh ${nodeName}

        chmod +x ${nodeName}/reset_chain_node.sh

        cp setup/start_raft_${nodeName}.sh ${nodeName}/qdata/start_raft_node.sh

        chmod +x ${nodeName}/qdata/start_raft_node.sh

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
    mkdir -p $pName/${nodeName}/qdata
    mkdir -p $pName/${nodeName}/qdata/{keystore,geth,logs}
    mkdir -p $pName/${nodeName}/keys
   
    generateKeyPair
    copyConfTemplate

    nodeAccountAddress="$(geth --datadir ${pName}/datadir --password lib/passwords.txt account new)"
    re="\{([^}]+)\}"

    if [[ $nodeAccountAddress =~ $re ]]; then

        nodeAccountAddress="0x"${BASH_REMATCH[1]};
    fi

    createGenesis

    mv ${pName}/datadir/keystore/* ${pName}/${nodeName}/qdata/keystore/${nodeName}key
   
    cat accountAddress.txt > ${pName}/genesis.json
    cat lib/genesis.json >> ${pName}/genesis.json

    copyRaftStartTemplate 
    
}

function createGenesis(){

        if [ $max == 1 ]; then

		echo "{" >AccountAddress.txt
		echo ""'"alloc"'": {"  >>AccountAddress.txt
                echo '"'$nodeAccountAddress'": {' >>AccountAddress.txt
	        echo '"balance": "1000000000000000000000000000"' >>AccountAddress.txt
		echo "}}," >>AccountAddress.txt
                cat AccountAddress.txt  >accountAddress.txt

	else
		if [ $i == 0 ]; then
			echo "{" >AccountAddress.txt
		        echo ""'"alloc"'": {"  >>AccountAddress.txt
			echo  '"'$nodeAccountAddress'": {' >>AccountAddress.txt
			echo '"balance": "1000000000000000000000000000"' >>AccountAddress.txt
			echo "}," >>AccountAddress.txt

		elif [ $i -lt $max ] ;then
			echo  '"'$nodeAccountAddress'": {' >>AccountAddress.txt
			echo '"balance": "1000000000000000000000000000"' >>AccountAddress.txt
			echo "}," >>AccountAddress.txt
		fi
		sed '$ s/.$/},/' AccountAddress.txt >accountAddress.txt
                 
	fi 

}

function cleanup(){

    rm -rf ${pName}/datadir
    rm -rf ${pName}/keys
    rm -rf ${pName}/setup
    rm accountAddress.txt
    rm AccountAddress.txt
    rm enode.txt
    rm nodekey
    rm Enode.txt
    rm Address.txt
}

function generateEnode(){

    echo ""
    echo "Generating Enodes...." 
    i=0
    j=0

    while [ $i -lt $max ]
    do
  
        bootnode -genkey nodekey
    	nodekey=$(cat nodekey)
	bootnode -nodekey nodekey 2>enode.txt &
	pid=$!
	sleep 5
	kill -9 $pid
	wait $pid 2> /dev/null
	re="enode:.*@"
	enode=$(cat enode.txt)
    
        if [[ $enode =~ $re ]];then

            Enode=${BASH_REMATCH[0]};
        
        fi

        chown -R $username:$username .
        
        nodeName=${nodes[i]}
        
        cp nodekey  ${pName}/${nodeName}/qdata/geth/. 


        PATTERN="s/#docker_ip#/$((j+4))/g"
        chown -R $username:$username .
        cat lib/docker_ip.txt > ${pName}/docker_ip.txt
        sed -i $PATTERN ${pName}/docker_ip.txt

        LOCAL_NODE_IP=$(cat ${pName}/docker_ip.txt)
    

        if [ $max == 1 ] ; then

            echo "["  > Enode.txt
            echo ""'"'""$Enode$LOCAL_NODE_IP:"21000?discport=0&raftport=50400"""'"'"""," >> Enode.txt

        else

            if [ $i == 0 ]; then

	    	echo "["  > Enode.txt
            	echo ""'"'""$Enode$LOCAL_NODE_IP:"21000?discport=0&raftport=50400"""'"'"""," >> Enode.txt

            elif [ $i -lt $max ] ;then
            
                true $((raftPort++))
                echo ""'"'""$Enode$LOCAL_NODE_IP:"21000?discport=0&raftport=50400"""'"'"""," >> Enode.txt
            fi
        fi

        true $(( i++ ))
        true $((j++))
    done

    i=0

    while [ $i -lt $max ]
    do
        nodeName=${nodes[i]}
        sed '$ s/.$/]/' Enode.txt > Address.txt
        cat Address.txt > ${pName}/${nodeName}/qdata/static-nodes.json
        true $(( i++ ))
    done

}
function displayPublicAddress(){

    i=$max
    
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

    count=0;

    chown -R $username:$username .
    echo ""
    read -p $'\e[1;33mPlease enter a project name: \e[0m' pName
    read -p $'\e[1;34mPlease enter the start port number [Default:22000]: \e[0m' pPort
     
    rm -rf ${pName}
    mkdir -p ${pName}/keys
    mkdir -p ${pName}/setup
    mkdir -p ${pName}/datadir

    i=0
    
    read -p $'\e[1;32mPlease enter a node count: \e[0m' count

    max=$count
    while [ $i -lt $max ]
    do
    
        read -p $'\e[1;32mPlease enter node name: \e[0m' ${pName}[${i}] 
        eval "nodeName=${pName}[${i}]"
        nodes[i]=${!nodeName}
        createNode ${!nodeName}

        true $(( i++ ))
    done

    createRaftDockerComposeFile "${nodes[@]}" "${i}"
    generateEnode
    executeInit "${nodes[@]}" "${i}"

    echo -e '\e[1;32mSuccessfully created project:\e[0m' $pName
    
    displayPublicAddress
    cleanup    
}

main
