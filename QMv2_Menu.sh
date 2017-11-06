#!/bin/bash

#Menu system for launching appropriate scripts based on user choice
flagmain=true
while  ("${flagmain}" = true) 
do
	echo -e 'i)Enter m to Create Master Node\nii)Enter j to Join Network\niii)Enter r to Remove Node\niv)Enter s to Setup Development/Test network\nv)Enter stop to return to console'
	read pro
	case $pro in
		m)
			./create_master_node.sh &
			PID1=$!
			wait $PID1
			;;
		j)
			./join_network.sh &
			PID1=$!
			wait $PID1
			;;
		r)
			./remove_node.sh &
			PID1=$!
			wait $PID1
			;; 
		s)
			./setup_network.sh &
			PID1=$!
			wait $PID1
			;;
		stop)
			flagmain=false
			;;
		*)
			echo "Please enter a valid option"
			;;
	esac
done