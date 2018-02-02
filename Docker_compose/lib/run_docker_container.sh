#!/bin/bash

docker run -it -v $(pwd)/$line:/${PWD##*/}  -w /${PWD##*/} syneblock/quorum-maker:2.0 bash
