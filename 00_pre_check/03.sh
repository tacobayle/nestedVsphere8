#!/bin/bash
#
source /nestedVsphere8/bash/ip.sh
source /nestedVsphere8/bash/download_file.sh
#
jsonFile="/root/variables.json"
localJsonFile="/nestedVsphere8/03_nested_vsphere/variables.json"
#
IFS=$'\n'
#
echo ""
echo "==> Creating /root/nested_vsphere.json file..."
rm -f /root/nested_vsphere.json
nested_vsphere_json=$(jq -c -r . $jsonFile | jq .)
#
echo "   +++ Adding boot_cfg_location..."
boot_cfg_location=$(jq -c -r '.boot_cfg_location' $localJsonFile)
nested_vsphere_json=$(echo $nested_vsphere_json | jq '. += {"boot_cfg_location": "'$(echo $boot_cfg_location)'"}')
#
echo "   +++ Adding iso_location..."
iso_location=$(jq -c -r '.iso_location' $localJsonFile)
nested_vsphere_json=$(echo $nested_vsphere_json | jq '. += {"iso_location": "'$(echo $iso_location)'"}')
#
echo "   +++ Adding iso_source_location..."
iso_source_location=$(jq -c -r '.iso_source_location' $localJsonFile)
nested_vsphere_json=$(echo $nested_vsphere_json | jq '. += {"iso_source_location": "'$(echo $iso_source_location)'"}')
#
echo "   +++ Adding vcenter_iso_path..."
vcenter_iso_path=$(jq -c -r '.vcenter_iso_path' $localJsonFile)
nested_vsphere_json=$(echo $nested_vsphere_json | jq '. += {"vcenter_iso_path": "'$(echo $vcenter_iso_path)'"}')
#
echo "   +++ Adding boot_cfg_lines..."
boot_cfg_lines=$(jq -c -r '.boot_cfg_lines' $localJsonFile)
nested_vsphere_json=$(echo $nested_vsphere_json | jq '. += {"boot_cfg_lines": '$(echo $boot_cfg_lines)'}')
#
echo "   +++ Adding bios..."
bios=$(jq -c -r '.bios' $localJsonFile)
nested_vsphere_json=$(echo $nested_vsphere_json | jq '. += {"bios": "'$(echo $bios)'"}')
#
echo "   +++ Adding guest_id..."
guest_id=$(jq -c -r '.guest_id' $localJsonFile)
nested_vsphere_json=$(echo $nested_vsphere_json | jq '. += {"guest_id": "'$(echo $guest_id)'"}')
#
echo "   +++ Adding keyboard_type..."
keyboard_type=$(jq -c -r '.keyboard_type' $localJsonFile)
nested_vsphere_json=$(echo $nested_vsphere_json | jq '. += {"keyboard_type": "'$(echo $keyboard_type)'"}')
#
echo "   +++ Adding wait_for_guest_net_timeout..."
wait_for_guest_net_timeout=$(jq -c -r '.wait_for_guest_net_timeout' $localJsonFile)
nested_vsphere_json=$(echo $nested_vsphere_json | jq '. += {"wait_for_guest_net_timeout": "'$(echo $wait_for_guest_net_timeout)'"}')
#
echo "   +++ Adding nested_hv_enabled..."
nested_hv_enabled=$(jq -c -r '.nested_hv_enabled' $localJsonFile)
nested_vsphere_json=$(echo $nested_vsphere_json | jq '. += {"nested_hv_enabled": "'$(echo $nested_hv_enabled)'"}')
#
echo "   +++ Adding cache_disk..."
cache_disk=$(jq -c -r '.cache_disk' $localJsonFile)
nested_vsphere_json=$(echo $nested_vsphere_json | jq '. += {"cache_disk": "'$(echo $cache_disk)'"}')
#
echo "   +++ Adding capacity_disk..."
capacity_disk=$(jq -c -r '.capacity_disk' $localJsonFile)
nested_vsphere_json=$(echo $nested_vsphere_json | jq '. += {"capacity_disk": "'$(echo $capacity_disk)'"}')
#
echo "   +++ Adding enable_vsan_esa..."
enable_vsan_esa=$(jq -c -r '.enable_vsan_esa' $localJsonFile)
nested_vsphere_json=$(echo $nested_vsphere_json | jq '. += {"enable_vsan_esa": "'$(echo $enable_vsan_esa)'"}')
#
echo "   +++ Adding thin_disk_mode..."
thin_disk_mode=$(jq -c -r '.thin_disk_mode' $localJsonFile)
nested_vsphere_json=$(echo $nested_vsphere_json | jq '. += {"thin_disk_mode": "'$(echo $thin_disk_mode)'"}')
#
echo "   +++ Adding deployment_option..."
deployment_option=$(jq -c -r '.deployment_option' $localJsonFile)
nested_vsphere_json=$(echo $nested_vsphere_json | jq '. += {"deployment_option": "'$(echo $deployment_option)'"}')
#
echo "   +++ Adding ssh_enable..."
ssh_enable=$(jq -c -r '.ssh_enable' $localJsonFile)
nested_vsphere_json=$(echo $nested_vsphere_json | jq '. += {"ssh_enable": "'$(echo $ssh_enable)'"}')
#
echo "   +++ Adding ceip_enabled..."
ceip_enabled=$(jq -c -r '.ceip_enabled' $localJsonFile)
nested_vsphere_json=$(echo $nested_vsphere_json | jq '. += {"ceip_enabled": "'$(echo $ceip_enabled)'"}')
#
echo "   +++ Adding json_config_file..."
json_config_file=$(jq -c -r '.json_config_file' $localJsonFile)
nested_vsphere_json=$(echo $nested_vsphere_json | jq '. += {"json_config_file": "'$(echo $json_config_file)'"}')
#
echo "   +++ Adding networks..."
networks=$(jq -c -r '.networks' $localJsonFile)
nested_vsphere_json=$(echo $nested_vsphere_json | jq '. += {"networks": '$(echo $networks)'}')
#
echo "   +++ Adding a date_index"
date_index=$(date '+%Y%m%d%H%M%S')
nested_vsphere_json=$(echo $nested_vsphere_json | jq '. += {"date_index": '$(echo $date_index)'}')
#
echo "   +++ Adding disk label and disk unit number..."
count=0
new_disks="[]"
for disk in $(jq -c -r .vsphere_nested.esxi.disks[] $jsonFile)
do
  new_disk=$(echo $disk | jq '. += {"label": "'$(echo disk$count)'", "unit_number": "'$(echo $count)'"}')
  new_disks=$(echo $new_disks | jq '. += ['$(echo $new_disk)']')
  ((count++))
done
nested_vsphere_json=$(echo $nested_vsphere_json | jq '. | del (.vsphere_nested.esxi.disks)')
nested_vsphere_json=$(echo $nested_vsphere_json | jq '.vsphere_nested.esxi += {"disks": '$(echo $new_disks)'}')
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_tanzu_alb_wo_nsx" ]]; then
  alb_networks='["se", "backend", "vip", "tanzu"]'
  ip_routes_vcenter="[]"
  for network in $(echo $alb_networks | jq -c -r .[])
  do
    if [[ $network != "se" ]] ; then
      echo "   +++ Adding vcenter ip route prefix $(jq .vsphere_underlay.networks.alb.$network.cidr $jsonFile)..."
      ip_routes_vcenter=$(echo $ip_routes_vcenter | jq '. += ['$(jq .vsphere_underlay.networks.alb.$network.cidr $jsonFile)']')
    fi
  done
  nested_vsphere_json=$(echo $nested_vsphere_json | jq '.vsphere_nested  += {"ip_routes_vcenter": '$(echo $ip_routes_vcenter)'}')
fi
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_telco" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_vcd" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_tanzu_alb" ]]; then
  #
  if grep -q "nsx" /nestedVsphere8/03_nested_vsphere/variables.tf ; then
    echo "   +++ variable nsx is already in /nestedVsphere8/03_nested_vsphere/variables.tf"
  else
    echo "   +++ Adding variable nsx in /nestedVsphere8/03_nested_vsphere/variables.tf"
    echo 'variable "nsx" {}' | tee -a /nestedVsphere8/03_nested_vsphere/variables.tf > /dev/null
  fi
  #
  if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_tanzu_alb" ]]; then
    if [[ $(jq -c -r '.nsx.config.segments_overlay | length' $jsonFile) -gt 0 ]] ; then
      ip_routes_vcenter=$(jq -c -r '.nsx.config.segments_overlay | map(select(any) | .cidr)' $jsonFile)
    fi
    nested_vsphere_json=$(echo $nested_vsphere_json | jq '.vsphere_nested  += {"ip_routes_vcenter": '${ip_routes_vcenter}'}')
  fi
fi
echo $nested_vsphere_json | jq . | tee /root/nested_vsphere.json > /dev/null
#
download_file_from_url_to_location "$(jq -c -r .vsphere_nested.esxi.iso_url $jsonFile)" "$(jq -c -r .iso_source_location $localJsonFile)" "ESXi ISO"
#
download_file_from_url_to_location "$(jq -c -r .vsphere_nested.iso_url $jsonFile)" "$(jq -c -r .vcenter_iso_path $localJsonFile)" "vSphere ISO"