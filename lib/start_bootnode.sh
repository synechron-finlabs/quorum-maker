BOOTNODE_KEYHEX=#bootnode_keyhex#

mkdir -p qdata/logs
LOCAL_NODE_IP="$(ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')"

echo "[*] Starting bootnode"
bootnode --nodekeyhex "$BOOTNODE_KEYHEX" --addr="$LOCAL_NODE_IP:$B_PORT" 2>>qdata/logs/bootnode.log &
echo "wait for bootnode to start..."
sleep 6
echo "Bootnode started"

BOOTNODE_PORT=$B_PORT
MAIN_NODE_IP=$CURRENT_NODE_IP
