#!/bin/bash
set -u
set -e

echo "[*] Cleaning up temporary data directories"
#cp qdata/geth/nodekey .
rm -rf qdata/

echo "[*] Configuring node1 node"
mkdir -p qdata/logs
mkdir -p qdata/keystore

if [ -f "keys/UTC--2017-11-08T09-21-22.516558667Z--e836eed1dcead764ff3311876d9382779dbd0342" ]
then
    cp keys/UTC--2017-11-08T09-21-22.516558667Z--e836eed1dcead764ff3311876d9382779dbd0342 qdata/keystore
fi

geth --datadir qdata init genesis.json

cp nodekey qdata/geth/
chmod +x start_raft.sh

cp *.conf qdata

cp static-nodes.json qdata/.

sudo docker run -it --name #nodename# \
-v $(pwd):/home/Node \
-w /${PWD##*}/home/Node \
-p 22000:22000 -p 22001:22001 -p 22001:22001/udp -p 22002:22002 \
syneblock/quorum-master:quorum2.0.0 \
./start_raft.sh
