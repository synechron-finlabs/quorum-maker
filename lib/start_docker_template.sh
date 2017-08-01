#!/bin/bash
set -u
set -e

CORE_NODE_IP="$(dig +short $CORE_NODE_IP)"
CORE_BOOTNODE_IP="$(dig +short $CORE_BOOTNODE)"
NETID=87234
sleep #delay#
CORE_MASTERNODE_IP="$(dig +short $CORE_MASTERNODE_IP)"

BOOTNODE_ENODE=enode://6433e8fb82c4638a8a6d499d40eb7d8158883219600bfd49acb968e3a37ccced04c964fa87b3a78a2da1b71dc1b90275f4d055720bb67fad4a118a56925125dc@[$CORE_BOOTNODE_IP]:33445

GLOBAL_ARGS="--verbosity 6 --bootnodes $BOOTNODE_ENODE --networkid $NETID --rpc --rpcaddr 0.0.0.0 --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum"

cp qdata/#nodeName#.conf .

PATTERN="s/CORE_NODE_IP/${CORE_NODE_IP}/g"
PATTERN2="s/CORE_MASTERNODE_IP/${CORE_MASTERNODE_IP}/g"

sed -i "$PATTERN" #nodeName#.conf
sed -i "$PATTERN2" #nodeName#.conf

echo "[*] Starting Constellation on #nodeName#"
constellation-node #nodeName#.conf 2> qdata/logs/constellation_#nodeName#.log &
sleep 1
echo "[*] Started Constellation on #nodeName#"

echo "[*] Starting Quorum on #nodeName#"
PRIVATE_CONFIG=#nodeName#.conf geth --datadir qdata $GLOBAL_ARGS --rpcport 22000 --port 21000 #blockMakerPattern# #voterPattern# --minblocktime 2 --maxblocktime 5 2>qdata/logs/#nodeName#.log &
echo "[*] Started Quorum on #nodeName#"

while true 
do 
 sleep 5
done

