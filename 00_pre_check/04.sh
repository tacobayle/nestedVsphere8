#!/bin/bash
#
jsonFile="/root/variables.json"
deployment=$(jq -c -r .deployment $jsonFile)
#
IFS=$'\n'
#
rm -f /root/networks.json
networks_json=$(jq -c -r . $jsonFile | jq .)
if [[ ${deployment} == "vsphere_nsx" || ${deployment} == "vsphere_nsx_alb" || ${deployment} == "vsphere_nsx_alb_telco" || ${deployment} == "vsphere_nsx_tanzu_alb" || ${deployment} == "vsphere_nsx_alb_vcd" || ${deployment} == "vsphere_alb_wo_nsx" || ${deployment} == "vsphere_tanzu_alb_wo_nsx" ]]; then
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
    if grep -q "nsx" /nestedVsphere8/04_networks/variables.tf ; then
      echo "   +++ variable nsx is already in /nestedVsphere8/08_app/variables.tf"
    else
      echo "   +++ Adding variable nsx in /nestedVsphere8/04_networks/variables.tf"
      echo 'variable "nsx" {}' | tee -a /nestedVsphere8/04_networks/variables.tf > /dev/null
    #
    fi
  fi
fi
echo $networks_json | jq . | tee /root/networks.json > /dev/null