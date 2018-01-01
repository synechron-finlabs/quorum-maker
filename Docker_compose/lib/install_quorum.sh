#!/bin/bash

set -eu -o pipefail


echo "Installing Quorum"
	

# install build deps
sudo add-apt-repository ppa:ethereum/ethereum
sudo apt-get update
sudo apt-get install -y build-essential unzip libdb-dev libsodium-dev zlib1g-dev libtinfo-dev solc sysvbanner wrk

# install constellation
wget -q https://github.com/jpmorganchase/constellation/releases/download/v0.0.1-alpha/ubuntu1604.zip
unzip ubuntu1604.zip
sudo cp ubuntu1604/constellation-node /usr/local/bin && sudo chmod 0755 /usr/local/bin/constellation-node
sudo cp ubuntu1604/constellation-enclave-keygen /usr/local/bin && sudo chmod 0755 /usr/local/bin/constellation-enclave-keygen
rm -rf ubuntu1604.zip ubuntu1604

if [ -z "$(which go)" ]; then

    if [ ! -d "/usr/local/go" ]; then
	# install golang
	GOREL=go1.7.3.linux-amd64.tar.gz
	wget -q https://storage.googleapis.com/golang/$GOREL
	tar xfz $GOREL
	sudo mv go /usr/local/go
	rm -f $GOREL
    fi
    
    PATH=$PATH:/usr/local/go/bin
    echo 'PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc

fi

# make/install quorum
git clone https://github.com/jpmorganchase/quorum.git
pushd quorum >/dev/null
git checkout tags/v1.2.0
make all
sudo cp build/bin/geth /usr/local/bin
sudo cp build/bin/bootnode /usr/local/bin
popd >/dev/null

echo "Quorum Installed Successfully"
	
