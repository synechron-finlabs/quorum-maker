#!/bin/bash

docker run -it -v $(pwd)/$line:/${PWD##*/}  -w /${PWD##*/} syneblock/quorum bash
