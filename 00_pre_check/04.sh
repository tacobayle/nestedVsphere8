#!/bin/bash
#
jsonFile="/root/variables.json"
#
IFS=$'\n'
#
rm -f /root/networks.json
networks_json=$(jq -c -r . $jsonFile | jq .)
#
echo ""
echo "==> Creating /root/networks.json file..."
#
echo "   +++ Adding networks..."
networks=$(jq -c -r '.networks' /nestedVsphere8/02_external_gateway/variables.json)
networks_json=$(echo $networks_json | jq '. += {"networks": '$(echo $networks)'}')
#
echo "   +++ Adding vds_version..."
vds_version=$(jq -c -r '.networks.vds.version' /nestedVsphere8/03_nested_vsphere/variables.json)
networks_json=$(echo $networks_json | jq '. += {"vds_version": "'$(echo $vds_version)'"}')
#
if [[ $(jq -c -r .nsx $jsonFile) != "null" ]]; then
  #
  echo "   +++ Adding variable nsx in /nestedVsphere8/04_networks/variables.tf"
  echo 'variable "nsx" {}' | tee -a /nestedVsphere8/04_networks/variables.tf > /dev/null
  #
fi
#
echo $networks_json | jq . | tee /root/networks.json > /dev/null