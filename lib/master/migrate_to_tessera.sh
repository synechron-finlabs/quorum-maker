#!/bin/bash

tessera="java -jar /tessera/tessera-app.jar"
tessera_data_migration="java -jar /tessera/data-migration-cli.jar"
tessera_config_migration="java -jar /tessera/config-migration-cli.jar"

OTHER_NODES_EMPTY=$(sed -n '/othernodes/p' #mNode#.conf)
if [[ -z "$OTHER_NODES_EMPTY" && -z "$1" ]]; then
    echo "No Peer defined: Run ./migrate_to_tessera.sh <URL> Eg. ./migrate_to_tessera.sh http://10.50.0.3:22002/"
    exit
fi

killall geth
killall constellation-node

${tessera_data_migration} -storetype dir -inputpath qdata/storage/payloads -dbuser -dbpass -outputfile qdata/#mNode# -exporttype h2 >> /dev/null 2>&1

${tessera_config_migration} --tomlfile="#mNode#.conf" --outputfile tessera-config.json --workdir= >> /dev/null 2>&1

sed -i "s|jdbc:h2:mem:tessera|jdbc:h2:file:/home/node/qdata/#mNode#;AUTO_SERVER=TRUE|" tessera-config.json
sed -i "s|/home/node/qdata/home|/home|" tessera-config.json
sed -i "s|/.*.ipc|/home/node/qdata/#mNode#.ipc|" tessera-config.json

LOCAL_NODE_IP="$(ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')"

sed  -i "s|\"hostName\".*,|\"hostName\" : \"http://$LOCAL_NODE_IP\",|" tessera-config.json

sed -i "s|Starting Constellation node|Starting Tessera node|" start_#mNode#.sh
sed -i "s|qdata/constellationLogs/constellation_|qdata/tesseraLogs/tessera_|" start_#mNode#.sh
sed -i "s|constellation-node.*conf|\$tessera -configfile tessera-config.json|" start_#mNode#.sh

if [ ! -z "$1" ]; then
    sed -i "s|\"peer\" : \[ \]|\"peer\" : \[ {\n      \"url\" : \"$1\"\n   } \]|" tessera-config.json     
fi

mkdir -p qdata/tesseraLogs

echo "Completed Tessera migration. Restart node to complete take effect."