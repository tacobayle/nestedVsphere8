#!/bin/bash
#
source /nestedVsphere8/bash/ip.sh
#
jsonFile="/etc/config/variables.json"
localJsonFile="/nestedVsphere8/10_vcd_appliance/variables.json"
#
IFS=$'\n'
#
if [[ $(jq -c -r .avi $jsonFile) != "null" &&  $(jq -c -r .nsx $jsonFile) != "null" &&  $(jq -c -r .vcd $jsonFile) != "null" && $(jq -c -r .avi.config.cloud.type $jsonFile) == "CLOUD_NSXT" ]]; then
  echo ""
  echo "==> Creating /root/vcd.json file..."
  rm -f /root/vcd.json
  vcd_json=$(jq -c -r . $jsonFile | jq .)
  #
  echo "   +++ Adding vcd_ova_path..."
  vcd_ova_path=$(jq -c -r '.vcd_ova_path' $localJsonFile)
  vcd_json=$(echo $vcd_json | jq '. += {"vcd_ova_path": "'$(echo $vcd_ova_path)'"}')
  #
  echo "   +++ Adding vcd_port_group_mgmt..."
  vcd_port_group_mgmt=$(jq -c -r '.networks.vsphere.management.port_group_name' /nestedVsphere8/03_nested_vsphere/variables.json)
  vcd_json=$(echo $vcd_json | jq '. += {"vcd_port_group_mgmt": "'$(echo $vcd_port_group_mgmt)'"}')
  #
  echo "   +++ Adding vcd_port_group_db..."
  vcd_port_group_db=$(jq -c -r '.networks.vsphere.VSAN.port_group_name' /nestedVsphere8/03_nested_vsphere/variables.json)
  vcd_json=$(echo $vcd_json | jq '. += {"vcd_port_group_db": "'$(echo $vcd_port_group_db)'"}')
  #
  echo "   +++ Adding prefix for management network..."
  prefix=$(ip_prefix_by_netmask $(jq -c -r '.vsphere_underlay.networks.vsphere.management.netmask' $jsonFile) "   ++++++")
  vcd_json=$(echo $vcd_json | jq '.vsphere_underlay.networks.vsphere.management += {"prefix": "'$(echo $prefix)'"}')
  #
  echo "   +++ Adding prefix for db network..."
  prefix=$(ip_prefix_by_netmask $(jq -c -r '.vsphere_underlay.networks.vsphere.vsan.netmask' $jsonFile) "   ++++++")
  vcd_json=$(echo $vcd_json | jq '.vsphere_underlay.networks.vsphere.vsan += {"prefix": "'$(echo $prefix)'"}')
  #
  echo "   +++ Adding vcd_appliance..."
  vcd_appliance=$(jq -c -r '.vcd_appliance' $localJsonFile)
  vcd_json=$(echo $vcd_json | jq '. += {"vcd_appliance": '$(echo $vcd_appliance)'}')
  #
  nfs_path=$(jq -c -r '.nfs_path' /nestedVsphere8/02_external_gateway/variables.json)
  vcd_json=$(echo $vcd_json | jq '.external_gw  += {"nfs_path": "'$(echo $nfs_path)'"}')
  #
  echo $vcd_json | jq . | tee /root/vcd.json > /dev/null
  #
  echo ""
  echo "==> Downloading VCD ova file"
  if [ -s "$(jq -c -r .vcd_ova_path $localJsonFile)" ]; then echo "   +++ VCD ova file $(jq -c -r .vcd_ova_path $localJsonFile) is not empty" ; else curl -s -o $(jq -c -r .vcd_ova_path $localJsonFile) $(jq -c -r .vcd.ova_url $jsonFile) ; fi
  if [ -s "$(jq -c -r .vcd_ova_path $localJsonFile)" ]; then echo "   +++ VCD ova file $(jq -c -r .vcd_ova_path $localJsonFile) is not empty" ; else echo "   +++ VCD ova $(jq -c -r .vcd_ova_path $localJsonFile) is empty" ; exit 255 ; fi
  #
fi