#!/bin/bash
#
source /nestedVsphere8/bash/ip.sh
source /nestedVsphere8/bash/download_file.sh
#
jsonFile="/etc/config/variables.json"
localJsonFile="/nestedVsphere8/13_vcd_appliance/variables.json"
#
IFS=$'\n'
#
echo ""
echo "==> Creating /root/vcd.json file..."
rm -f /root/vcd.json
vcd_json=$(jq -c -r . $jsonFile | jq .)
#
echo "   +++ nsx_manager_name"
nsx_manager_name=$(jq -c -r .nsx_manager_name /nestedVsphere8/02_external_gateway/variables.json)
external_gw_json=$(echo $external_gw_json | jq '.external_gw += {"nsx_manager_name": "'$(echo $nsx_manager_name)'"}')
#
echo "   +++ alb_controller_name"
alb_controller_name=$(jq -c -r .alb_controller_name /nestedVsphere8/02_external_gateway/variables.json)
external_gw_json=$(echo $external_gw_json | jq '.external_gw += {"alb_controller_name": "'$(echo $alb_controller_name)'"}')
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
echo "   +++ Adding vcd_appliance..."
vcd_appliance=$(jq -c -r '.vcd_appliance' $localJsonFile)
vcd_json=$(echo $vcd_json | jq '. += {"vcd_appliance": '$(echo $vcd_appliance)'}')
#
nfs_path=$(jq -c -r '.nfs_path' /nestedVsphere8/02_external_gateway/variables.json)
vcd_json=$(echo $vcd_json | jq '.external_gw  += {"nfs_path": "'$(echo $nfs_path)'"}')
#
echo $vcd_json | jq . | tee /root/vcd.json > /dev/null
#
download_file_from_url_to_location "$(jq -c -r .vcd.ova_url $jsonFile)" "$(jq -c -r .vcd_ova_path $localJsonFile)" "VCD ova"