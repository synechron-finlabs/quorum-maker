#!/bin/bash
set -u
set -e
NETID=87234
BOOTNODE_KEYHEX=77bd02ffa26e3fb8f324bda24ae588066f1873d95680104de5bc2db9e7b2e510

echo "[*] Starting bootnode"
bootnode --nodekeyhex "$BOOTNODE_KEYHEX" --addr="$BOOTNODE_IP:33445" 2>qdata/logs/bootnode.log

