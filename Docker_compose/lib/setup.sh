#!/bin/bash


read -p $'\e[1;36mWould you like to use this with raft_docker-compose support? [y/N] \e[0m' yn

case $yn in
    [Yy]* )
	lib/raft_docker_compose.sh
	;;
    * )
	lib/setup_multibox.sh
	;;
esac

