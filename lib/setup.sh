#!/bin/bash
echo "1.Want to use docker_compose"
echo "2.Want to create new project"
echo "3.Want to use existing project"
read -p $'\e[1;36mPlease enter your choice \e[0m' opt
#opt=$
case $opt in
        1)
                echo "Using docker compose..."
		lib/setup_docker_compose.sh
                ;;
        2)
                echo "Creating New Projetc..."
		lib/setup_multibox.sh
                ;;
        3)
                echo "Using existing project..."
		lib/addNode.sh
                ;;
esac
