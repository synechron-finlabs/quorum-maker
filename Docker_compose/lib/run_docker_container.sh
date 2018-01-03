#!/bin/bash

docker run -it -v $(pwd)/$line:/${PWD##*/}  -w /${PWD##*/} syneblock/quorum-master:quorum2.0.0 bash
