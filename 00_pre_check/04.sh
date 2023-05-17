#!/bin/bash
#
jsonFile="/root/variables.json"
#
IFS=$'\n'
#
rm -f /root/networks.json
networks_json=$(jq -c -r . $jsonFile | jq .)
#
if [[ $(jq -c -r .nsx $jsonFile) != "null" ]]; then
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
  echo "   +++ Adding variable nsx in /nestedVsphere8/04_networks/variables.tf"
  echo 'variable "nsx" {}' | tee -a /nestedVsphere8/04_networks/variables.tf > /dev/null
  #
  echo "   +++ Adding variable networks in /nestedVsphere8/04_networks/variables.tf"
  echo 'variable "networks" {}' | tee -a /nestedVsphere8/04_networks/variables.tf > /dev/null
  #
  echo $networks_json | jq . | tee /root/networks.json > /dev/null
  #
else
  if [[ $(jq -c -r .vsphere_underlay.networks.alb $jsonFile) != "null" ]]; then
    echo ""
    echo "==> Creating /root/networks.json file..."
    #
    networks=$(jq -c -r '.networks' /nestedVsphere8/02_external_gateway/variables.json)
    networks_json=$(echo $networks_json | jq '. += {"networks": '$(echo $networks)'}')
    #
    echo $networks_json | jq . | tee /root/networks.json > /dev/null
  fi
fi
