#!/bin/bash
jsonFile="/root/variables.json"
source /nestedVsphere8/bash/govc/load_govc_underlay.sh
govc find -json . -type n | tee getNetworks.json