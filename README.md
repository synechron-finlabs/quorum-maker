# Quorum Maker

J.P Morgan Quorum nodes can be setup with different roles such as block maker, voter and observer. Manually editing the configuration files and creating the node is a tedious and error prone process. Quorum Maker can create several nodes of various configurations dynamically with no or limited user input. This provides a wizard like interface with a series of questions to guide the user to create nodes. Quorum Maker provides scripts to run Quorum on separate Linux boxes or Docker image to run them on separate containers on a single box. It also provides Vagrant scripts to spin up Ubuntu instances on Windows/Mac. 

![Screenshot](https://github.com/dhyansraj/quorum-maker/blob/master/img/screenshot.png)

Using of Quorum Maker is a two step process;

 - Creating the node configurations
 - Setting up nodes on different machines or containers

> Note: The steps below are for Ubuntu 16.04. If you are using a Windows/Mac, please scroll bottom for the instructions to spin up an Ubuntu 16.04 with Vagrant and VirtualBox. After connecting the vagrant box, please follow below instructions.

# Creating the node configuration
*In the first step, all node configurations will be created on one box. Later these files can be copied to respective boxes/containers.*

Run `./setup.sh` to start the configuration wizard. The script will ask a series of questions to guide through the node configuration.

> Note: Please use bash script variable naming conventions to name the project and nodes. E.g. avoid starting the names with digits or using hyphen `-` to separate words.

 1. **Project Name**
	 Give a name to the project like five_nodes, sample_project etc.
 2. **Node name**
     Name the first node and this question would repeat as many nodes as you create. Please make sure to give unique names to nodes.     
 3. **Private Keys**
     Ethereum requires private and public keys for accounts. This step will prompt for passwords for securing the keys. This is optional, but strongly recommended in production usage.
 4. **Block Maker Node**
     Answer yes if you wish to make this node a block maker or No otherwise. Please make sure to have at least one block maker in the setup.
 5. **Only Block Maker**
 Quorum uses random time outs between block makers to avoid conflicts in block creation. If there is only one block maker in the network, timeout can be avoided and block can be immediately created. 
 6. **Voter Node**
 Answer yes if you wish to make this node a voter or No otherwise. Please make sure to have at least one voter in the setup.
 7. **Add more Nodes**
 As many nodes required can be configured by repeating the above steps by answering Yes to this question. Once answered No to this, the script will exit and a directory with the project name will be created on the current directory. 

The directory generated with the project name has all the configuration files required to spin up the nodes. Please copy this entire directory to all boxes/containers and follow the second step to run the nodes.

#Setting up nodes on different machines or containers
  
After copying the project directory to each boxes/containers, one more step is required to setup the node completely before running them. Since each box/container has different IP address, the start scripts needs to updated to reflect this. Also Quorum uses a bootnode to setup peers, so each node should know the bootnode IP. 

Quorum Maker provides script for updating these details and no manual editing is required. 

 1. Quorum Maker assumes that the bootnode runs on the first node configured in the above step. So from a terminal on the first box/container run `./start_bootnode.sh`
 2. Run `./init_<firstNodeName>.sh`  The project directory will have several `init_xxxx.sh` scripts.These scripts should be run from their respective box/container to update the IP addresses correctly. On the first box/container init script doesnt require any parameter, but all other boxes/containers, they require first node's IP address as the additional parameter. Eg. `./init_second_node.sh 192.17.0.1`
 3. Run `./start_xxxx.sh`After running the init script, a start script will be created automatically. Run this script on respective nodes to bring up the Quorum nodes.
 

> Tip: Check the logs in qdata/logs on each box/container to make sure everything OK. If you encounter an error `geth.ipc not found` or similar, please try to run `./stop.sh` and run the start script. If you are running the stop script on first box/container, make sure to start the bootnode as stop script brings down that as well.

4. Login to the Geth console of each node and send transactions as per Quorum guidelines.

#Running multiple nodes on same box#

Quorum Maker provides a script to start a docker image from the project directory. This uses a docker image called `dhyanraj/quorum` that has all the configurations required to run Quorum nodes. Run this script as many times to spin up multiple docker containers with Quorum support. Once inside the Docker container, follow the steps above to configure and start multiple Quorum nodes.
> Tip: Docker can expose a port inside the container to the host box. Use -p hostport:containerport in the docker command. E.g. `docker run -p 9000:9000 -it dhyanraj/quorum bash`

#Windows/Mac Support#

Quorum Maker provides Vagrant box for running Quorum on Windows/Mac. Running `vagrant up` will provision a vagrant box with support for Ubuntu 16.04, Docker and Quorum. 

> Tip: Please use Git Bash to run vagrant commands on Windows. Also try to run Git Bash as Administrator to avoid privilege issues. 

> Tip: Vagrant can expose ports to host computer. Please update the Vagrantfile in the Quorum Maker as per your port requirements.
E.g.  
`Vagrant.configure("2") do |config|`  
  `config.vm.network "forwarded_port", guest: 80, host: 8080`  
`end`
