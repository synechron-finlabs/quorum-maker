#!/bin/bash

#Menu system for launching appropriate scripts based on user choice
DOCKERIMAGE=syneblock/quorum-master:quorum2.0.0
export DOCKERIMAGE
	flagmain=true
	echo -e "\e[1;93mPlease select an option:\e[1;32m\n1) Create Network\e[1;35m\n2) Join Network\e[1;94m\n3) Remove Node\e[1;96m\n4) Setup Development/Test Network\e[1;39m\n5) Exit"
	printf 'option: '
	read option
	case $option in
		1)
			docker run -it -v $(pwd)/$line:/${PWD##*/} -w /${PWD##*/} $DOCKERIMAGE lib/create_network.sh
			createNodeName=$(cat nodename)
			cd $createNodeName
			sudo ./start.sh
			;;
		2)
			docker run -it -v $(pwd)/$line:/${PWD##*/} -w /${PWD##*/} $DOCKERIMAGE lib/join_network.sh
			JoinNodeName=$(cat nodeName)
			cd $JoinNodeName
			sudo ./start_docker.sh
			rm -f ../nodeName
			rm -f ../nodename
			;;
		3)
			./remove_node.sh
			;; 
		4)
			./setup_network.sh
			;;
		5)
			flagmain=false
			;;
		*)
			echo "Please enter a valid option"
			;;
	esac
