#!/bin/bash

#Menu system for launching appropriate scripts based on user choice
source qm.variables

docker run -it --rm -v $(pwd)/$line:/${PWD##*/} -w /${PWD##*/} $dockerImage lib/menu.sh

if [ -f .nodename ]; then
	nodename=$(cat .nodename)
	rm -f .nodename
	cd $nodename	
	sudo ./start.sh	
fi
