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
			./create_master_node.sh
			;;
		2)
			./join_network.sh
			;;
		3)
			./lib/remove_node.sh
			;; 
		4)
			./lib/setup_network.sh
			;;
		5)
			flagmain=false
			;;
		*)
			echo "Please enter a valid option"
			;;
	esac
done
