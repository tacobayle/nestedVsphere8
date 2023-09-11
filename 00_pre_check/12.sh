#!/bin/bash
#
source /nestedVsphere8/bash/download_file.sh
#
jsonFile="/root/variables.json"
localJsonFile="/nestedVsphere8/12_tkgm/variables.json"
#
IFS=$'\n'
#
local_file="/root/$(basename $(jq -c -r .tkg.tanzu_bin_location $jsonFile))"
download_file_from_url_to_location "$(jq -c -r .tkg.tanzu_bin_location $jsonFile)" "${local_file}" "TKGm bin cli"
#
local_file="/root/$(basename $(jq -c -r .tkg.k8s_bin_location $jsonFile))"
download_file_from_url_to_location "$(jq -c -r .tkg.k8s_bin_location $jsonFile)" "${local_file}" "TKGm kubectl bin"
#
local_file="/root/$(basename $(jq -c -r .tkg.ova_location $jsonFile))"
download_file_from_url_to_location "$(jq -c -r .tkg.ova_location $jsonFile)" "${local_file}" "TKGm ova"