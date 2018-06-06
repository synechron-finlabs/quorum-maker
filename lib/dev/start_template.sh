#!/bin/bash

function main(){
    
    nodeName=$(basename `pwd`)

     publickey=$(cat node/keys/$nodeName.pub)
     
     echo 'PUBKEY='$publickey
     
     cd node
     ./start_$nodeName.sh
}
main
