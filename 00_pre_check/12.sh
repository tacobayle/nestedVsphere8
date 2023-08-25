#!/bin/bash
#
jsonFile="/root/variables.json"
localJsonFile="/nestedVsphere8/12_tkgm/variables.json"

#
IFS=$'\n'
#
echo ""
echo "==> Downloading TKGm binary file"
if [ -s "$(jq -c -r .tkg.tanzu_bin_location $localJsonFile)" ]; then echo "   +++ TKG tanzu bin file $(jq -c -r .tkg.tanzu_bin_location $localJsonFile) is not empty" ; else curl -s -o $(echo "/root/$(basename $(jq -c -r .tkg.tanzu_bin_location $localJsonFile))") $(jq -c -r .tkg.tanzu_bin_location $jsonFile) ; fi
if [ -s "$(jq -c -r .tkg.tanzu_bin_location $localJsonFile)" ]; then echo "   +++ TKG tanzu bin file $(jq -c -r .tkg.tanzu_bin_location $localJsonFile) is not empty" ; else echo "   +++ TKG tanzu bin $(jq -c -r .tkg.tanzu_bin_location $localJsonFile) is empty" ; exit 255 ; fi

if [ -s "$(jq -c -r .tkg.k8s_bin_location $localJsonFile)" ]; then echo "   +++ TKG kubectl file $(jq -c -r .tkg.k8s_bin_location $localJsonFile) is not empty" ; else curl -s -o $(echo "/root/$(basename $(jq -c -r .tkg.k8s_bin_location $jsonFile))") $(jq -c -r .tkg.k8s_bin_location $jsonFile) ; fi
if [ -s "$(jq -c -r .tkg.k8s_bin_location $localJsonFile)" ]; then echo "   +++ TKG kubectl file $(jq -c -r .tkg.k8s_bin_location $localJsonFile) is not empty" ; else echo "   +++ TKG kubectl file $(jq -c -r .tkg.k8s_bin_location $localJsonFile) is empty" ; exit 255 ; fi

if [ -s "$(jq -c -r .tkg.ova_location $localJsonFile)" ]; then echo "   +++ Tanzu ova file $(jq -c -r .tkg.ova_location $localJsonFile) is not empty" ; else curl -s -o $(echo "/root/$(basename $(jq -c -r .tkg.ova_location $jsonFile))") $(jq -c -r .tkg.ova_location $jsonFile) ; fi
if [ -s "$(jq -c -r .tkg.ova_location $localJsonFile)" ]; then echo "   +++ Tanzu ova file $(jq -c -r .tkg.ova_location $localJsonFile) is not empty" ; else echo "   +++ Tanzu ova file $(jq -c -r .tkg.ova_location $localJsonFile) is empty" ; exit 255 ; fi