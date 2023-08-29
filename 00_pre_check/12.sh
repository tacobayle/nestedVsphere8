#!/bin/bash
#
jsonFile="/root/variables.json"
localJsonFile="/nestedVsphere8/12_tkgm/variables.json"

#
IFS=$'\n'
#
echo ""
echo "==> Downloading TKGm binary file"
local_file="/root/$(basename $(jq -c -r .tkg.tanzu_bin_location $jsonFile))"
if [ -s "$(echo $local_file)" ]; then echo "   +++ TKG tanzu bin file $local_file is not empty" ; else curl -s -o ${local_file} $(jq -c -r .tkg.tanzu_bin_location $jsonFile) ; fi
if [ -s "$(echo $local_file)" ]; then echo "   +++ TKG tanzu bin file $local_file is not empty" ; else echo "   +++ TKG tanzu bin $local_file is empty" ; exit 255 ; fi

local_file="/root/$(basename $(jq -c -r .tkg.k8s_bin_location $jsonFile))"
if [ -s "$(echo $local_file)" ]; then echo "   +++ TKG kubectl file $local_file is not empty" ; else curl -s -o ${local_file} $(jq -c -r .tkg.k8s_bin_location $jsonFile) ; fi
if [ -s "$(echo $local_file)" ]; then echo "   +++ TKG kubectl file $local_file is not empty" ; else echo "   +++ TKG kubectl file $local_file is empty" ; exit 255 ; fi

local_file="/root/$(basename $(jq -c -r .tkg.ova_location $jsonFile))"
if [ -s "$(echo $local_file)" ]; then echo "   +++ Tanzu ova file $local_file is not empty" ; else curl -s -o ${local_file} $(jq -c -r .tkg.ova_location $jsonFile) ; fi
if [ -s "$(echo $local_file)" ]; then echo "   +++ Tanzu ova file $local_file is not empty" ; else echo "   +++ Tanzu ova file $local_file is empty" ; exit 255 ; fi