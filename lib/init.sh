#!/bin/bash

# echo "[*] Cleaning up temporary data directories for slave node"
cp qdata/keystore .
cp qdata/geth/nodekey .
rm -rf qdata
mkdir -p qdata/logs

echo "[*] Configuring slave node"
mkdir -p qdata/{keystore,geth}
cp keystore qdata/keystore
cp nodekey qdata/geth/nodekey
geth --datadir node/qdata init genesis.json
