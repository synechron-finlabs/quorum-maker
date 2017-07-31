# Quorum Maker

J.P Morgan Quorum nodes can be setup with different roles such as block maker, voter and observer. Manually editing the configuration files and creating the node is a tedious and error prone process. Quorum Maker can create several nodes of various configurations dynamically with no or limited user input. This provides a wizard like interface with a series of questions to guide the user to create nodes. Quorum Maker can created nodes to run with docker-compose for easy use in development environment or nodes to be distributed on separate Linux boxes or cloud instances for production like environment. It also provides Vagrant scripts to spin up Ubuntu instances on Windows/Mac. 


Using of Quorum Maker is a two step process;

 - Creating the node configurations
 - Setting up nodes on different machines or containers

> Note: Quorum Maker is tested only on Ubuntu 16.04 and 17.04. Other Debian variants may work with slight changes to script. If you are using a Windows/Mac, please scroll bottom for the instructions to spin up an Ubuntu 16.04 with Vagrant and VirtualBox. After connecting the vagrant box, please follow below instructions.

# Creating the node configuration for Development use
*The only prerequisite for Quorum Maker is Ubuntu 16.04. The script can automatically install docker and docker-compose if not available. Rest of the tools required to run quorum maker is available in the docker image*

![Screenshot](https://github.com/synechron-finlabs/quorum-maker/blob/development/img/screenshot_dev.png) 

Run `./setup.sh` to start the configuration wizard. The script will ask a series of questions to guide through the node configuration.

> Note: Please use bash script variable naming conventions to name the project and nodes. E.g. avoid starting the names with digits or using hyphen `-` to separate words.

 1. **Docker-Compose Support**
     Answer yes or y to create nodes to be created to work with docker-compose. This is easiest way to setup nodes if you are  experimenting with Quorum or planning to use Quorum only for local development. 
 2. **Project Name**
     Give a name to the project like five_nodes, sample_project etc.
 3. **Start Port Number**
     This is the RPC port to send transactions. Each node you would create will have a port sequentially incremented, starting with number provided to this question. Eg. first node will have 22000, second will have 22001 and so on. 
 4. **Node name**
     Name the first node and this question would repeat as many nodes as you create. Please make sure to give unique names to nodes.     
 5. **Private Keys**
     Ethereum requires private and public keys for accounts. This step will prompt for passwords for securing the keys. This is optional, but strongly recommended in production usage.
 6. **Block Maker Node**
     Answer yes if you wish to make this node a block maker or No otherwise. Please make sure to have at least one block maker in the setup.
 7. **Only Block Maker**
 Quorum uses random time outs between block makers to avoid conflicts in block creation. If there is only one block maker in the network, timeout can be avoided and block can be immediately created. 
 8. **Voter Node**
 Answer yes if you wish to make this node a voter or No otherwise. Please make sure to have at least one voter in the setup.
 9. **Add more Nodes**
 As many nodes required can be configured by repeating the above steps by answering Yes to this question. Once answered No to this, the script will exit and a directory with the project name will be created on the current directory. 

# Running the nodes for Development
The directory generated with the project name has a docker-compose.yml and all the configuration files required to spin up the nodes. 

![Screenshot](https://github.com/synechron-finlabs/quorum-maker/blob/development/img/screenshot_dev_output.png) 

1. Run `docker-compose up` to start the nodes.
2. You will see status as each node starts up. The first one to start is the boot node and the rest of the nodes follows.
3. Once you see all `Starting <node name>`, the network is ready to be used. As of now, there wouldn't be status saying all nodes are up. 
4. The RPC ports are exposed to your host machine. You can send transactions to each node using Web3 or other Qourum supported clients at `http://localhost:<port>/`. Ports are consecutively assigned to each nodes. Use the port starting with the one answered in the question 3 during the node creation. 
5. Use the constallation keys listed during node creation for privateFor transactions.
6. If you wish to connect to any node, run `docker exec -it <node name> bash` and run `geth attach qdata/geth.ipc`
7. The logs can be found on `<node name>/qdata/logs` directory.
8. Press `Ctrl C` to stop the network and `docker-compose down` to remove containers.

# Raft Consensus Support

Raft is the new consensus from Quorum and is supported in Qourum Maker. After the starting the network with `docker-compose up`, open a new terminal and change to the project directory. Run `sudo ./switch_consensus.sh`. This will automatically change the `--raft` flag and generate `static-nodes.json` by connecting to each node and fetching the endoe information. Restart the network by `Ctrl + C` and `docker-compose up`.

# Creating the node configuration for multi box or cloud use
*The only prerequisite for Quorum Maker is Ubuntu 16.04. The script can automatically install docker and docker-compose if not available. Rest of the tools required to run quorum maker is available in the docker image*

![Screenshot](https://github.com/synechron-finlabs/quorum-maker/blob/development/img/screenshot_prod.png) 

Run `./setup.sh` to start the configuration wizard. The script will ask a series of questions to guide through the node configuration.

> Note: Please use bash script variable naming conventions to name the project and nodes. E.g. avoid starting the names with digits or using hyphen `-` to separate words.

 1. **Docker-Compose Support**
     Answer no or n to create nodes to be created production like environment. This is easiest way to setup nodes if you want to deploy nodes to multiple boxes or cloud instances. 
 2. **Project Name**
     Give a name to the project like five_nodes, sample_project etc.
 3. **Node name**
     Name the first node and this question would repeat as many nodes as you create. Please make sure to give unique names to nodes.     
 4. **Private Keys**
     Ethereum requires private and public keys for accounts. This step will prompt for passwords for securing the keys. This is optional, but strongly recommended in production usage.
 5. **Block Maker Node**
     Answer yes if you wish to make this node a block maker or No otherwise. Please make sure to have at least one block maker in the setup.
 6. **Only Block Maker**
 Quorum uses random time outs between block makers to avoid conflicts in block creation. If there is only one block maker in the network, timeout can be avoided and block can be immediately created. 
 7. **Voter Node**
 Answer yes if you wish to make this node a voter or No otherwise. Please make sure to have at least one voter in the setup.
 8. **Add more Nodes**
 As many nodes required can be configured by repeating the above steps by answering Yes to this question. Once answered No to this, the script will exit and a directory with the project name will be created on the current directory. 

# Running the nodes for Production like environments
The directory generated with the project name has all the nodes zipped to separate files. Distribute these to target boxes or cloud instances and unzip them to be used. 
![Screenshot](https://github.com/synechron-finlabs/quorum-maker/blob/development/img/screenshot_prod_output.png) 

> Note: Target boxes or cloud instances should be running on Ubuntu 16.04 or higher. 
> Important Note: The first node created is the master node in the network with bootnode and master constallation node. This needs to be started before ohter nodes.

**Running master node**

![Screenshot](https://github.com/synechron-finlabs/quorum-maker/blob/development/img/screenshot_prod_start_master.png) 

1. Unzip the node
2. Run `./start.sh`
3. Enter this node's IP. Use the external IP of this box or instance, if the nodes are in different network.
4. Enter this node's RPC Port. 
5. Enter this node's Network Listening Port.
6. Enter this node's Constellation Port.
7. Enter Bootnode Port.
8. The node will be started and a docker container hash will be returned. 

**Running other nodes**

![Screenshot](https://github.com/synechron-finlabs/quorum-maker/blob/development/img/screenshot_prod_start_slave.png) 

1. Unzip the node
2. Run `./start.sh`
3. Enter this node's IP. Use the external IP of this box or instance, if the nodes are in different network.
4. Enter this node's RPC Port. 
5. Enter this node's Network Listening Port.
6. Enter this node's Constellation Port.
7. Enter main node IP Address. This is the IP of the master node started in the previous section.
8. Enter bootnode port. This is the port of the Bootnode started in the previous section.
9. Enter main constellation node port. This is the port of the constallation node started in the previous section.
8. The node will be started and a docker container hash will be returned. 

**Special Feature**

The parameters entered while starting the nodes are automatically saved to a configuration file. So second time onwards no parameters are required to be entered. The default configuration file is setup.conf. Following is a sample setup.conf

```
CURRENT_IP=52.134.197.136
RPC_PORT=3007
WHISPER_PORT=3451
CONSTELLATION_PORT=3892
BOOTNODE_PORT=1089
MASTER_IP=14.204.225.0
MASTER_CONSTELLATION_PORT=1047
```

**Post startup**

1. Run `docker ps` and make the instances are up. Check the logs and make sure startup went well. 
2. The logs can be found on `<node name>/qdata/logs` directory.
3. Make sure the nodes are connected each other successfully. Run `docker exec -it <container id> bash` and Run `geth attach qdata\geth.ipc` to connect to geth client. Run `admin.peers` inside geth console and make sure all the nodes are listed.
4. The RPC ports are exposed to your host machine. You can send transactions to each node using Web3 or other Qourum supported clients at `http://localhost:<port>/`. Use the port starting with the one answered in the question 4 during the node startup. 
5. Use the constallation keys listed during node creation for privateFor transactions. Diana become a programmer


# Windows/Mac Support

Quorum Maker provides Vagrant box for running Quorum on Windows/Mac. Running `vagrant up` will provision a vagrant box with support for Ubuntu 16.04, Docker and Quorum. 

> Tip: Please use Git Bash to run vagrant commands on Windows. Also try to run Git Bash as Administrator to avoid privilege issues. 

> Tip: Vagrant can expose ports to host computer. Please update the Vagrantfile in the Quorum Maker as per your port requirements.
E.g.  
`Vagrant.configure("2") do |config|`  
  `config.vm.network "forwarded_port", guest: 80, host: 8080`  
`end`
