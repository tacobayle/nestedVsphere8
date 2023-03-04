#!/bin/bash
#
jsonFile="/etc/config/variables.json"
#
IFS=$'\n'
#
if [[ $(jq -c -r .nsx $jsonFile) != "null" ]]; then
  echo ""
  echo "==> Creating /root/nsx1.json file..."
  rm -f /root/nsx1.json
  nsx_json=$(jq -c -r . $jsonFile | jq .)
  #
  echo "   +++ Adding networks..."
  networks=$(jq -c -r '.networks' /nestedVsphere8/02_external_gateway/variables.json)
  nsx_json=$(echo $nsx_json | jq '. += {"networks": '$(echo $networks)'}')
  #
  echo "   +++ Adding vds_version..."
  vds_version=$(jq -c -r '.networks.vds.version' /nestedVsphere8/03_nested_vsphere/variables.json)
  nsx_json=$(echo $nsx_json | jq '. += {"vds_version": "'$(echo $vds_version)'"}')
  #
  echo $nsx_json | jq . | tee /root/nsx1.json > /dev/null
fi
