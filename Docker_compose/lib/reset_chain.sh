#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

for file in */; do

    if [ ${file%?} != "bootnode" ]; then
        docker exec -itd ${file%?} ./reset_chain_node.sh
    fi

done

echo "Chain Data Reset. Please restart containers"



