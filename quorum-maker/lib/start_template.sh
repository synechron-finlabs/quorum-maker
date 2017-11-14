echo 'CURRENT_IP='$pCurrentIp >  ../nodeSetup.conf
echo 'RPC_PORT='$rPort >>  ../nodeSetup.conf
echo 'WHISPER_PORT='$wPort >>  ../nodeSetup.conf
echo 'CONSTELLATION_PORT='$cPort >>  ../nodeSetup.conf
echo 'MASTER_JAVA_PORT='$mjPort >>  ../nodeSetup.conf

GLOBAL_ARGS="--raft --networkid $NETID --rpc --rpcaddr 0.0.0.0 --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum"

echo "[*] Starting Constellation node" > qdata/logs/constellation_#mNode#.log

cp qdata/#mNode#.conf .

PATTERN="s/#CURRENT_IP#/${pCurrentIp}/g"
PATTERN2="s/#C_PORT#/${cPort}/g"

sed -i "$PATTERN" #mNode#.conf
sed -i "$PATTERN2" #mNode#.conf

constellation-node #mNode#.conf 2>> qdata/logs/constellation_#mNode#.log &
sleep 1

echo "[*] Starting #mNode# node" >> qdata/logs/#mNode#.log
echo "[*] geth --verbosity 6 --datadir qdata" $GLOBAL_ARGS" --raftport 50401 --rpcport "$rPort "--port "$W_PORT "--nat extip:"$pCurrentIp>> qdata/logs/#mNode#.log

PRIVATE_CONFIG=#mNode#.conf geth --verbosity 6 --datadir qdata $GLOBAL_ARGS --raftport 50401 --rpcport $R_PORT --port $W_PORT --nat extip:$pCurrentIp 2>>qdata/logs/#mNode#.log 

