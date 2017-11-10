#!/bin/bash
set -u
set -e

echo "[*] Cleaning up temporary data directories"
cd ..
rm -rf qdata/
rm -rf keys/

echo "[*] Configuring master node"
mkdir -p keys
mkdir -p qdata/logs
mkdir -p qdata/{keystore,geth}
touch qdata/static-nodes.json

function masterAccountAddress(){
   AccountAddress="$(geth --datadir datadir --password lib/passwords.txt account new)"
    mv datadir/keystore/* qdata/keystore/nodeAccountKey
    rm -rf datadir
}

function generateKeyPair(){
    echo "Generating public and private keys, Please enter password or leave blank"
    constellation-node --generatekeys=masterNodekey

    echo "Generating public and private backup keys for, Please enter password or leave blank"
    constellation-node --generatekeys=masterNodekeya

    mv masterNodekey*.* keys/.
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
    
    Enode=$Enode$current_ip
    Enode=$Enode$wPort
    cp nodekey ${nodename}/qdata/geth/.
    rm enode.txt    
    rm nodekey
}

# cp lib/genesis.json qdata/.
# geth --datadir qdata init genesis.json

#cp nodekey qdata/geth/
#chmod +x start_raft.sh

#cp *.conf qdata

#cp static-nodes.json qdata/.

#sudo docker run -it --name nodeCreate \
#-v $(pwd):/home/Node \
#-w /${PWD##*}/home/Node \
#-p 22000:22000 -p 22001:22001 -p 22001:22001/udp -p 22002:22002 \
#syneblock/quorum-master:quorum2.0.0 \
#./start_raft.sh

function main(){
    nodeIndex=0
    masterAccountAddress
    generateKeyPair
 
    generateEnode
}
main

