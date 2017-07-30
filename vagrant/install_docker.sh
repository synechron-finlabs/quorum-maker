echo "Installing Docker"
wget -qO - https://apt.dockerproject.org/gpg | sudo apt-key add -
add-apt-repository "deb https://apt.dockerproject.org/repo/ ubuntu-$(lsb_release -cs) main"
apt-get update
apt-get -y install docker-engine
service docker restart
sleep 5
echo "Docker Installed Succesfully"

echo "Installing Quorum Image"

service docker restart
sleep 5
sudo docker pull dhyanraj/quorum

