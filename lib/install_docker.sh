echo "Installing Docker"

sudo apt-get update

sudo apt-get install \
     apt-transport-https \
     ca-certificates \
     curl \
     software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository \
     "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
         $(lsb_release -cs) \
         stable"

sudo apt-get update

sudo apt-get install docker-ce

echo "Docker Installed Succesfully"

echo "Installing Quorum Image"

service docker restart
sleep 5
sudo docker pull syneblock/quorum

