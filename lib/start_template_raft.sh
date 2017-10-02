echo 'CURRENT_IP='$CURRENT_NODE_IP > ../setup.conf
echo 'RPC_PORT='$R_PORT >> ../setup.conf
echo 'WHISPER_PORT='$W_PORT >> ../setup.conf
echo 'CONSTELLATION_PORT='$C_PORT >> ../setup.conf
echo 'MASTER_IP='$MAIN_NODE_IP >> ../setup.conf
echo 'MASTER_CONSTELLATION_PORT='$MAIN_C_PORT >> ../setup.conf

GLOBAL_ARGS="--networkid $NETID --rpc --rpcaddr 0.0.0.0 --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum"

echo "[*] Starting Constellation node" > qdata/logs/#nodeName#.log

cp qdata/#nodeName#.conf .

PATTERN="s/#CURRENT_NODE_IP#/${CURRENT_NODE_IP}/g"
PATTERN2="s/#MAIN_NODE_IP#/${MAIN_NODE_IP}/g"
PATTERN3="s/#C_PORT#/${C_PORT}/g"
PATTERN4="s/#M_C_PORT#/${MAIN_C_PORT}/g"

sed -i "$PATTERN" #nodeName#.conf
sed -i "$PATTERN2" #nodeName#.conf
sed -i "$PATTERN3" #nodeName#.conf
sed -i "$PATTERN4" #nodeName#.conf


constellation-node #nodeName#.conf 2>> qdata/logs/#nodeName#.log &
sleep 1

echo "[*] Starting #nodeName# node" >> qdata/logs/constellation_#nodeName#.log

PRIVATE_CONFIG=#nodeName#.conf geth --verbosity 6 --datadir qdata $GLOBAL_ARGS --rpcport $R_PORT --port $W_PORT --raft --nat extip:$CURRENT_NODE_IP 2>>qdata/logs/#nodeName#.log 

