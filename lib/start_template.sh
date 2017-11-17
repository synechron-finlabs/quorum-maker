#append values in Setup.conf file 
echo 'CURRENT_IP='$CURRENT_NODE_IP > ../setup.conf
echo 'RPC_PORT='$R_PORT >> ../setup.conf
echo 'WHISPER_PORT='$W_PORT >> ../setup.conf
echo 'CONSTELLATION_PORT='$C_PORT >> ../setup.conf
echo 'MASTER_IP='$MAIN_IP >> ../setup.conf
echo 'MASTER_JAVA_PORT='$MJ_PORT >>  ../setup.conf

GLOBAL_ARGS="--raft --nodiscover --networkid $NETID --rpc --rpcaddr 0.0.0.0 --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum"

echo "[*] Starting Constellation node" > qdata/logs/constellation_#sNode#.log

#replace PATTERN in node.conf file
PATTERN="s/#CURRENT_IP#/${CURRENT_NODE_IP}/g"
PATTERN2="s/#C_PORT#/${C_PORT}/g"

sed -i "$PATTERN" #sNode#.conf
sed -i "$PATTERN2" #sNode#.conf

#replace PATTERN in static-nodes.json file
PATTERN3="s/#CURRENT_IP#/${CURRENT_NODE_IP}/g"
PATTERN4="s/#W_PORT#/${W_PORT}/g"

sed -i "$PATTERN3" qdata/static-nodes.json
sed -i "$PATTERN4" qdata/static-nodes.json

constellation-node #sNode#.conf 2>> qdata/logs/constellation_#sNode#.log &
sleep 1

echo "[*] Starting #sNode# node" >> qdata/logs/#sNode#.log
echo "[*] geth --verbosity 6 --datadir qdata" $GLOBAL_ARGS" --raftport 50401 --rpcport "$R_PORT "--port "$W_PORT "--nat extip:"$CURRENT_NODE_IP>> qdata/logs/#sNode#.log

PRIVATE_CONFIG=#sNode#.conf geth --verbosity 6 --datadir qdata $GLOBAL_ARGS --raftport 50401 --rpcport $R_PORT --port $W_PORT --nat extip:$CURRENT_NODE_IP 2>>qdata/logs/#sNode#.log 

