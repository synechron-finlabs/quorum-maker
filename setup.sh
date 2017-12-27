#!/bin/bash

#Menu system for launching appropriate scripts based on user choice

flagmain=true
while  ("${flagmain}" = true) 
do
	echo -e 'Please select an option:\n1) Create Master Node\n2) Join Network\n3) Remove Node\n4) Setup Development/Test Network\n5) Exit'
	printf 'option: '
	read option
	case $option in
		1)
			docker run -it -v $(pwd)/$line:/${PWD##*/} -w /${PWD##*/} quorum-maker2.0 lib/create_master_node.sh
			;;
		2)
			docker run -it -v $(pwd)/$line:/${PWD##*/} -w /${PWD##*/} quorum-maker2.0 lib/join_network.sh
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
done
