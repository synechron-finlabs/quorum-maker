#!/bin/bash
set -u
set -e

echo "[*] Cleaning up temporary data directories"
rm -rf #pName#/qdata/constellation_#nodeName#
rm -rf #pName#/qdata/#nodeName#
rm -f #pName#/qdata/logs/#nodeName#.log
rm -f #pName#/qdata/logs/constellation_#nodeName#.log
rm -f #pName#/start_#nodeName#.sh
rm -f #pName#/#nodeName#.conf

echo "[*] Configuring #nodeName# node"
mkdir -p #pName#/qdata/logs
mkdir -p #pName#/qdata/#nodeName#/keystore
if [ -f "keys/#nodeName#BM" ]
then
    cp keys/#nodeName#BM #pName#/qdata/#nodeName#/keystore
fi

if [ -f "keys/#nodeName#V" ]
then
    cp keys/#nodeName#V #pName#/qdata/#nodeName#/keystore
fi
geth --datadir #pName#/#nodeName# init genesis.json

echo "[*] Updating configuration files"
cp #pName#/setup/start_#nodeName#.sh #pName#/start_#nodeName#.sh
cp #pName#/setup/#nodeName#.conf #nodeName#.conf

#THIS_IP="$(ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')"
THIS_IP=#CORE_BOOTNODE_IP#
PATTERN="s/##nodeName#_ip#/$THIS_IP/g"

sed -i $PATTERN #pName#/start_#nodeName#.sh
sed -i $PATTERN #pName#/setup/#nodeName#.conf

chmod +x #pName#/start_#nodeName#.sh

