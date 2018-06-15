#!/bin/bash

#Menu system for launching appropriate scripts based on user choice
source qm.variables
source lib/common.sh

flagmain=true
echo -e $YELLOW'Please select an option: \n' \
		$GREEN'1) Create Network \n' \
		$PINK'2) Join Network \n' \
		$BLUE'3) Remove Node \n' \
		$CYAN'4) Setup Development/Test Network \n' \
		$RED'5) Exit' 

printf $WHITE'option: '$COLOR_END

read option
case $option in
	1)
		lib/create_network.sh ;;
	2)
		lib/join_network.sh ;;
	3)
		./remove_node.sh ;; 
	4)
		lib/create_dev_network.sh ;;
	5)
		flagmain=false	;;
	*)
		echo "Please enter a valid option"	;;
esac
