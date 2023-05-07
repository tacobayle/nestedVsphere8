#!/bin/bash
#
source /nestedVsphere8/bash/ip.sh
#
jsonFile="/etc/config/variables.json"
localJsonFile="/nestedVsphere8/05_nsx_manager/variables.json"
#
IFS=$'\n'
#
if [[ $(jq -c -r .nsx $jsonFile) != "null" ]]; then
  echo ""
  echo "==> Creating /root/nsx2.json file..."
  rm -f /root/nsx2.json
  nsx_json=$(jq -c -r . $jsonFile | jq .)
  #
  echo "   +++ Adding nsx_ova_path..."
  nsx_ova_path=$(jq -c -r '.nsx_ova_path' $localJsonFile)
  nsx_json=$(echo $nsx_json | jq '. += {"nsx_ova_path": "'$(echo $nsx_ova_path)'"}')
  #
  echo "   +++ nsx_manager_name"
  nsx_manager_name=$(jq -c -r .nsx_manager_name /nestedVsphere8/02_external_gateway/variables.json)
  external_gw_json=$(echo $external_gw_json | jq '.external_gw += {"nsx_manager_name": "'$(echo $nsx_manager_name)'"}')
  #
  echo "   +++ Adding networks..."
  networks=$(jq -c -r '.networks' "/nestedVsphere8/03_nested_vsphere/variables.json")
  nsx_json=$(echo $nsx_json | jq '. += {"networks": '$(echo $networks)'}')
  #
  echo $nsx_json | jq . | tee /root/nsx2.json > /dev/null
  #
  echo ""
  echo "==> Downloading NSX ova file"
  if [ -s "$(jq -c -r .nsx_ova_path $localJsonFile)" ]; then echo "   +++ NSX ova file $(jq -c -r .nsx_ova_path $localJsonFile) is not empty" ; else curl -s -o $(jq -c -r .nsx_ova_path $localJsonFile) $(jq -c -r .nsx.ova_url $jsonFile) ; fi
  if [ -s "$(jq -c -r .nsx_ova_path $localJsonFile)" ]; then echo "   +++ NSX ova file $(jq -c -r .nsx_ova_path $localJsonFile) is not empty" ; else echo "   +++ NSX ova $(jq -c -r .nsx_ova_path $localJsonFile) is empty" ; exit 255 ; fi
fi
