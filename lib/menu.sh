#!/bin/bash

#Menu system for launching appropriate scripts based on user choice
source qm.variables
source lib/common.sh

function readParameters() {
    POSITIONAL=()
    while [[ $# -gt 0 ]]
    do
        key="$1"

        case $key in
            create)
            option="1"
            shift # past argument            
            ;;
            join)
            option="2"
            shift # past argument            
            ;;
			attach)
            option="3"
            shift # past argument            
            ;;
			dev)
            option="4"
            shift # past argument            
            ;;
            -h|--help)
            help
            
            ;;
            *)    # unknown option
            POSITIONAL+=("$1") # save it in an array for later
            shift # past argument
            ;;
        esac
    done
    set -- "${POSITIONAL[@]}" # restore positional parameters

	if [[ ! -z $option && $option -lt 1 || $option -gt 4 ]]; then 		
		help
	fi
	
	if [ ! -z $option ]; then 		
		NON_INTERACTIVE=true
	fi
    
}

function main() {

	readParameters $@

	if [ -z "$NON_INTERACTIVE" ]; then
		flagmain=true
		echo -e $YELLOW'Please select an option: \n' \
				$GREEN'1) Create Network \n' \
				$PINK'2) Join Network \n' \
				$BLUE'3) Attach to an existing Node \n' \
				$CYAN'4) Setup Development/Test Network \n' \
				$RED'5) Exit' 

		printf $WHITE'option: '$COLOR_END

		read option
	fi

	case $option in
		1)
			lib/create_network.sh $@;;
		2)
			lib/join_network.sh $@;;
		3)
			lib/attach_node.sh $@;; 
		4)
			lib/create_dev_network.sh $@;;
		5)
			flagmain=false	;;
		*)
			echo "Please enter a valid option"	;;
	esac
}

main $@

