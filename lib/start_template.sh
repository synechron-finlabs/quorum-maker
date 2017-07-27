BOOTNODE_ENODE=#bootnode_enode#[$MAIN_NODE_IP]:$BOOTNODE_PORT

GLOBAL_ARGS="--bootnodes $BOOTNODE_ENODE --networkid $NETID --rpc --rpcaddr 0.0.0.0 --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum"

echo "[*] Starting Constellation node"

cp qdata/#nodeName#.conf .

PATTERN="s/#CURRENT_NODE_IP#/${CURRENT_NODE_IP}/g"
PATTERN2="s/#MAIN_NODE_IP#/${MAIN_NODE_IP}/g"
PATTERN3="s/#C_PORT#/${C_PORT}/g"
PATTERN4="s/#M_C_PORT#/${MAIN_C_PORT}/g"

sed -i "$PATTERN" #nodeName#.conf
sed -i "$PATTERN2" #nodeName#.conf
sed -i "$PATTERN3" #nodeName#.conf
sed -i "$PATTERN4" #nodeName#.conf


constellation-node #nodeName#.conf 2> qdata/logs/constellation_#nodeName#.log &
sleep 1

echo "[*] Starting #nodeName# node"
PRIVATE_CONFIG=#nodeName#.conf geth --verbosity 6 --datadir qdata $GLOBAL_ARGS --rpcport $R_PORT --port $W_PORT #blockMakerPattern# #voterPattern# --minblocktime 2 --maxblocktime 5 --nat extip:$CURRENT_NODE_IP 2>qdata/logs/#nodeName#.log 

