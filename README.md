# Quorum Maker V2.0

Synechron's Quorum Maker is a tool that allows users to spin up the nodes that are needed to build a Quorum network. Manually editing configuration files and creating nodes can be a tedious and error-prone process. Quorum Maker can create several nodes of various configurations dynamically with limited user input. This provides a wizard-like interface with a series of questions to guide the user when creating nodes. Quorum Maker can create nodes to run with docker-compose (Raft consensus/Quorum 2.0.0) for easy use in development environments or nodes to be distributed on separate Linux boxes or cloud instances for a production environment (Raft consensus/Quorum 2.0.2)

# Quorum Maker provides following benefits:
  -	An easy interface to create and manage Quorum Network
  -	A modern UI to monitor and manager Quorum Network
  -	A Network Map Service to be used for identifying nodes and self-publishing roles.  
  -	Block and Transaction Explorer
  -	Smart Contract Deployment
  -	Email Notifications
## Summary of features across different versions of Quorum Maker

| Features | V 1.0 | V 2.0 |
| ------ | ------ |-----|
| Create Network | Yes | No |
|Join Network | No | Yes|
|Delete Nodes	 	  | Yes | Yes |
|Quick Setup with Docker	 	  | Yes | Yes |
|Quick network with Docker Compose	 	  | Yes | Yes |
|Quorum Chain Consensus	 	  | Yes | Yes |
|Raft Consensus	 	  | Yes | Yes |
|Istanbul PBFT Consensus	 	  | Yes | Yes |
|Network Map Service  	 	  | Yes | Yes |
|Node Monitoring	 	  | Yes | Yes |
|Web UI	 	  | Yes | Yes |
|Block Explorer	 	  | Yes | Yes |
|Transaction Explorer	 	  | Yes | Yes |
|Email Notification	 	  | Yes | Yes |
|Restful API	 	  | Yes | Yes |
|Smart Contract Deployer	 	  | Yes | Yes |

# Quickstart

The first step to use Quorum Maker is to clone the source code from GitHub. 

```
$ git clone git@github.com:synechron-finlabs/quorum-maker.git 
```

Once the repository is successfully cloned, run setup.sh script. There are no pre-requisites for running Quorum Maker other than Ubuntu 16.04 or later. This script will automatically download and install required software, including docker if not found. 

## Creating a Network

```
$ cd quorum-maker
$ ./setup.sh
```

After few of the required docker images are downloaded, Quorum Maker will present with few questions to complete the node setup. 

`Please select an option:`
`1) Create Network`
`2) Join Network`
`3) Remove Node`
`4) Setup Development/Test Network`
`5) Exit`
`option:` 1

`Please enter node name:` Org1

`Please enter IP Address of this node:` 10.0.2.15
`Please enter RPC Port of this node[Default:22000]:`
`Please enter Network Listening Port of this node[Default:22001]:`
`Please enter Constellation Port of this node[Default:22002]:`
`Please enter Raft Port of this node[Default:22003]:`
`Please enter Node Manager Port of this node[Default:22004]:`

This completes the creator node startup procedure. Under the hood it uses the user provided parameters to start geth and constellation inside the docker container and also starts the NodeManager service. Quorum Maker has created a directory with name you supplied for node name. This directory has the script to start the node and other files required. You can stop the node any time using `Ctrl + C`, and restart using runing `sudo ./start.sh` from the node directory (Eg. `Org1`). 

## Joining a Network
Once a node a created, you can create and join more nodes to form a Quourm Network. Ideally subsequent nodes should be created on other computers. If you are creating another node on the same computer, please make sure to use different ports. In this case you can use the same Quorum Maker clone, since it creates separate directories for each node.


```
$ cd quorum-maker
$ ./setup.sh
```

After few of the required docker images are downloaded, Quorum Maker will present with few questions to complete the node setup. 

`Please select an option:`
`1) Create Network`
`2) Join Network`
`3) Remove Node`
`4) Setup Development/Test Network`
`5) Exit`
`option:` 2

`Please enter node name:` Org2

`Please enter IP Address of existing node:` 10.0.2.15
`Please enter Node Manager Port of existing node:` 22004         
`Please enter IP Address of this node:` 14.0.2.30
`Please enter RPC Port of this node[Default:22000]:`24000
`Please enter Network Listening Port of this node[Default:24001]:`
`Please enter Constellation Port of this node[Default:24002]:`
`Please enter Raft Port of this node[Default:24003]:`
`Please enter Node Manager Port of this node[Default:24004]:`

At this point, a directory with the node name is created and most of the files are created. But to join the exisisting network, this node requires the Genesis file specific to the network. Quorum Maker will contact the existing node and request permission to join and send Genesis. An administrator of that node will get a notification for the join request and needs to approve it. 

> Note: The joining node will wait 5 minutes for the approval. If the request is not approved within that time, the Quorum Maker will quit. But the administrator the other node can approve the request any time. Once the request is approved, the node can be restarted by executing `sudo ./start.sh` from the directory created and the setup will be resumed. 

## Approve/Reject Network
-	Once a join request has been sent by a node willing to join a network to one of the existing network participants, this node has the option to approve/reject this join request
-	If the join request is accepted, the main node's constellation port, genesis file and network ID is returned to the joiner. If the join request is rejected, the joiner's setup script exits

## Node Explorer
Quorum Maker provides a web interface to monitor the network. You can explore the blocks getting created and the transactions in them. Node admin can watch the performance of their node as well peek into othe connected nodes. 

Administrators can view geth and constellation logs from Quorum Maker. 
## Monitoring and Email Notification
1.	There is an active monitoring system which checks whether the node is up every 30 seconds. If it fails to get the expected response which indicates that the node is functional, it waits for another 30 seconds and performs the health check again. If the check fails again then the user is notified
2.	The user is sent an email notification indicating that the node has gone down. The node admin has to preconfigure the notification procedure by providing the following details
a.	SMTP Sever Host
b.	Port
c.	Username
d.	Password

## Contract Deployment

Smart contracts can be deployed from Quorum Maker. Uses can choose solidity files (Even multiple contracts !) and deploy them publicaly or privetly.  

1.	Multiple contracts can be uploaded via the Compile and Deploy Tab
2.	The source .sol files are compiled using solc and subsequently deployed 
3.	The deployment is done either publicly or privately
4.	In case of private deployment the public keys of the concerned parties are sent from UI
5.	The list of network participants and their corresponding public keys are fetched using a REST API call 
6.	Error messages that occur from compilation failures are also displayed on UI
All the deployed contracts are easily accessible from the UI in the format contractAddress_contractName and contain the corresponding ABI, Bytecode and JSON

# Node Manager API

Quorum Maker provides APIs that internally uses, but useful for application development. 

|URI|Method|Description|
|--|--|--|
|/block|GET|This endpoint returns a list of latest n blocks if the query string parameter number is equal to n. If the query string parameter reference is provided with query string parameter number equal to n, then n blocks starting before (reference – 1) is returned|
|/block/{block_no}|GET|This endpoint returns the details of a particular block based on block number|
|/txn |GET |This endpoint returns a list of latest n transactions if the query string parameter number is equal to n|
|/txn/{txn_hash}|GET|This endpoint gets the transaction details of a transaction based on hash. If txn_hash is sent as "pending" it returns a list of all pending transactions|
|/txnsearch/{txn_hash}|GET|This endpoint returns details of a particular transaction based on transaction hash alongside its corresponding block details for displaying the corresponding block information of the queried transaction on UI|
|/latestBlock|GET|This endpoint the latest block number and the difference between present time and the time of creation of the block|
|/peer|GET|This endpoint returns a combination of admin.nodeInfo and certain other details such as current node name, node count, active status, IP, RPC port, raft role, raft ID, blocknumber, pending transaction count as well as the genesis file|
|/peer/{peer_id}|GET|This endpoint returns the information gleaned from admin.peers but filtered by enode-id of a particular peer for displaying the pop up from the node table|
|/nodeList|GET|This endpoint returns the node name, role, public key and enode of all participants in the network by querying the Network Manager contract|
|/pubkeys|GET|This endpoint returns a list of network participants and their corresponding public keys for populating the contract deployment tab's network participants list|
|/deployContract|POST|Multiple contracts can be uploaded via multipart file upload through this endpoint. The source .sol files are compiled using solc and subsequently deployed. The deployment is done either publicly or privately. In case of private deployment the public keys of the concerned parties are sent from UI. The list of network participants and their corresponding public keys are fetched using a REST API call. Error messages that occur from compilation failures are also displayed on UI. All the deployed contracts are easily accessible from the UI in the format|

### Work In Progress

 - Support for Istanbul PBFT
 - Support for creating network using docker-compose for development/experimental purpose
 - HTTPS support
 - Password for private keys




