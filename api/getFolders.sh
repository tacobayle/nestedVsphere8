#!/bin/bash
jsonFile="/root/variables.json"
source /nestedVsphere8/bash/govc/load_govc_underlay.sh
echo $(govc find -json . -type f) | tee getFolders.json