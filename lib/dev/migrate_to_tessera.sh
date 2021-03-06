#!/bin/bash

tessera="java -jar /tessera/tessera-app.jar"
tessera_data_migration="java -jar /tessera/data-migration-cli.jar"
tessera_config_migration="java -Djavax.xml.bind.JAXBContextFactory=org.eclipse.persistence.jaxb.JAXBContextFactory -Djavax.xml.bind.context.factory=org.eclipse.persistence.jaxb.JAXBContextFactory -jar /tessera/config-migration-cli.jar"

OTHER_NODES_EMPTY=$(sed -n '/othernodes/p' node/#mNode#.conf)
if [[ -z "$OTHER_NODES_EMPTY" && -z "$1" ]]; then
    echo "No Peer defined: Run ./migrate_to_tessera.sh <URL> Eg. ./migrate_to_tessera.sh http://10.50.0.3:22002/"
    exit
fi

killall geth
killall constellation-node

mv /#mNode#/node/qdata/#mNode#.mv.db /#mNode#/node/qdata/#mNode#.mv.db.bak

sed -i "s|h2url|jdbc:h2:file:/#mNode#/node/qdata/#mNode#;AUTO_SERVER=TRUE|" node/tessera-migration.properties

${tessera_data_migration} -storetype dir -inputpath /#mNode#/node/qdata/storage/payloads -dbuser -dbpass -outputfile /#mNode#/node/qdata/#mNode# -exporttype JDBC -dbconfig node/tessera-migration.properties >> /dev/null 2>&1

if [ ! -f /#mNode#/node/qdata/#mNode#.mv.db ]; then
    mv /#mNode#/node/qdata/#mNode#.mv.db.bak /#mNode#/node/qdata/#mNode#.mv.db
fi

${tessera_config_migration} --tomlfile node/#mNode#.conf --outputfile node/tessera-config.json --workdir "" --socket /#mNode#.ipc  >> /dev/null 2>&1

sed -i "s|jdbc:h2:mem:tessera|jdbc:h2:file:/#mNode#/node/qdata/#mNode#;AUTO_SERVER=TRUE|" node/tessera-config.json
sed -i "s|/#mNode#/qdata/#mNode#|/#mNode#|" node/tessera-config.json
sed -i "s|/#mNode#.ipc|/#mNode#/node/qdata/#mNode#.ipc|" node/tessera-config.json

sed -i "s|\"autoCreateTables\" : false|\"autoCreateTables\" : true|" node/tessera-config.json

sed -i "s|Starting Constellation node|Starting Tessera node|" node/start_#mNode#.sh
sed -i "s|qdata/constellationLogs/constellation_|qdata/tesseraLogs/tessera_|" node/start_#mNode#.sh
sed -i "s|constellation-node #mNode#.conf|\$tessera -configfile tessera-config.json|" node/start_#mNode#.sh

if [ ! -z "$1" ]; then
    sed -i "s|\"peer\" : \[ \]|\"peer\" : \[ {\n      \"url\" : \"$1\"\n   } \]|" node/tessera-config.json     
fi

mkdir -p node/qdata/tesseraLogs

echo "Completed Tessera migration. Restart node to complete take effect."

killall NodeManager
