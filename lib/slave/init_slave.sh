#!/bin/bash

# echo "[*] Cleaning up temporary data directories for slave node"
cp -r node/qdata/keystore .
cp node/qdata/geth/nodekey .
rm -rf node/qdata
mkdir -p node/qdata/logs

# echo "[*] Configuring slave node"
mkdir -p node/qdata/{keystore,geth}
mv keystore node/qdata/
mv nodekey node/qdata/geth/
cd node/
geth --datadir qdata init genesis.json
