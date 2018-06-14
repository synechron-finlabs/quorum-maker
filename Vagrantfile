Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"
  config.vm.network "private_network", ip: "192.168.33.11"
  config.vm.provider "virtualbox" do |vb|
     vb.memory = "2048"
  end
   config.vm.provision "shell", inline: <<-SHELL
     apt-get update
     curl https://get.docker.com | bash
     sudo usermod -aG docker vagrant
     sudo curl -L https://github.com/docker/compose/releases/download/1.21.2/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
     sudo chmod +x /usr/local/bin/docker-compose
     sudo apt install dos2unix
     cp -r /vagrant/* /home/vagrant
     find /home/vagrant -type f -print0 | xargs -0 dos2unix
     touch /home/vagrant/.qm_export_ports
   SHELL
end
