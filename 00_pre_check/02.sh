#!/bin/bash
#
source /nestedVsphere8/bash/vcenter_api.sh
source /nestedVsphere8/bash/ip.sh
#
jsonFile="/etc/config/variables.json"
localJsonFile="/nestedVsphere8/02_external_gateway/variables.json"
#
IFS=$'\n'
#
echo ""
echo "==> Generating SSH public and private keys"
if [[ -s "/root/.ssh/id_rsa" && -s "/root/.ssh/id_rsa.pub" ]]; then echo "   +++ ssh key files already exist" ; else ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa > /dev/null ; fi
#
rm -f /root/external_gw.json
external_gw_json=$(jq -c -r . $jsonFile | jq .)
echo ""
echo "==> Creating /root/external_gw.json file..."
if [[ $(jq -c -r .nsx $jsonFile) != "null" ]]; then # with NSX
  #
  echo "   +++ Adding external_gw.nsx_deployment: true"
  external_gw_json=$(echo $external_gw_json | jq '.external_gw += {"nsx_deployment": true}')
  #
  echo "   +++ Adding ansible_version..."
  ansible_version=$(jq -c -r '.ansible_version' $localJsonFile)
  external_gw_json=$(echo $external_gw_json | jq '. += {"ansible_version": "'$(echo $ansible_version)'"}')
  #
  echo "   +++ Adding avi_sdk_version..."
  avi_sdk_version=$(jq -c -r '.avi_sdk_version' $localJsonFile)
  external_gw_json=$(echo $external_gw_json | jq '. += {"avi_sdk_version": "'$(echo $avi_sdk_version)'"}')
  #
  echo "   +++ Creating External gateway routes to subnet segments..."
  new_routes="[]"
  if [[ $(jq -c -r '.nsx.config.segments_overlay | length' $jsonFile) -gt 0 ]] ; then
    for segment in $(jq -c -r .nsx.config.segments_overlay[] $jsonFile)
    do
      for tier1 in $(jq -c -r .nsx.config.tier1s[] $jsonFile)
      do
        if [[ $(echo $segment | jq -c -r .tier1) == $(echo $tier1 | jq -c -r .display_name) ]] ; then
          count=0
          for tier0 in $(jq -c -r .nsx.config.tier0s[] $jsonFile)
          do
            if [[ $(echo $tier1 | jq -c -r .tier0) == $(echo $tier0 | jq -c -r .display_name) ]] ; then
              new_routes=$(echo $new_routes | jq '. += [{"to": "'$(echo $segment | jq -c -r .cidr)'", "via": "'$(jq -c -r .vsphere_underlay.networks.nsx.external.tier0_vips["$count"] $jsonFile)'"}]')
              echo "   ++++++ Route to $(echo $segment | jq -c -r .cidr) via $(jq -c -r .vsphere_underlay.networks.nsx.external.tier0_vips["$count"] $jsonFile) added: OK"
            fi
            ((count++))
          done
        fi
      done
    done
  fi
  #
  if [[ $(jq -c -r '.avi.config.cloud.networks_data | length' $jsonFile) -gt 0 ]] ; then
    echo "   +++ Creating External gateway routes to Avi VIP subnets..."
    for network in $(jq -c -r .avi.config.cloud.networks_data[] $jsonFile)
    do
      for segment in $(jq -c -r .nsx.config.segments_overlay[] $jsonFile)
      do
        if [[ $(echo $network | jq -c -r .name) == $(echo $segment | jq -c -r .display_name) ]] ; then
          for tier1 in $(jq -c -r .nsx.config.tier1s[] $jsonFile)
          do
            if [[ $(echo $segment | jq -c -r .tier1) == $(echo $tier1 | jq -c -r .display_name) ]] ; then
              count=0
              for tier0 in $(jq -c -r .nsx.config.tier0s[] $jsonFile)
              do
                if [[ $(echo $tier1 | jq -c -r .tier0) == $(echo $tier0 | jq -c -r .display_name) ]] ; then
                  new_routes=$(echo $new_routes | jq '. += [{"to": "'$(echo $network | jq -c -r .avi_ipam_vip.cidr)'", "via": "'$(jq -c -r .vsphere_underlay.networks.nsx.external.tier0_vips["$count"] $jsonFile)'"}]')
                  echo "   ++++++ Route to $(echo $network | jq -c -r .avi_ipam_vip.cidr) via $(jq -c -r .vsphere_underlay.networks.nsx.external.tier0_vips["$count"] $jsonFile) added: OK"
                fi
                ((count++))
              done
            fi
          done
        fi
      done
    done
  fi
  external_gw_json=$(echo $external_gw_json | jq '.external_gw += {"routes": '$(echo $new_routes)'}')
  #
  if [[ $(jq -c -r .avi.config.cloud.type $jsonFile) == "CLOUD_NSXT" ]]; then
    echo "   +++ Creating External ip_table_prefixes..."
    ip_table_prefixes="[]"
    if [[ $(jq -c -r '.nsx.config.segments_overlay | length' $jsonFile) -gt 0 ]] ; then
      for segment in $(jq -c -r .nsx.config.segments_overlay[] $jsonFile)
      do
        if [[ $(echo $segment | jq -c -r .display_name) != $(jq -c -r .avi.config.cloud.network_management.name $jsonFile) ]] ; then
          ip_table_prefixes=$(echo $ip_table_prefixes | jq '. += ["'$(echo $segment | jq -c -r .cidr)'"]')
          echo "   ++++++ Prefix $(echo $segment | jq -c -r .cidr) added: OK"
        fi
      done
    fi
    external_gw_json=$(echo $external_gw_json | jq '.external_gw  += {"ip_table_prefixes": '$(echo $ip_table_prefixes)'}')
  fi
  #
  echo "   +++ Adding Networks MTU details"
  networks_details=$(jq -c -r .networks $localJsonFile)
  external_gw_json=$(echo $external_gw_json | jq '. += {"networks": '$(echo $networks_details)'}')
  #
  echo "   +++ Adding prefix for NSX external network..."
  prefix=$(ip_prefix_by_netmask $(jq -c -r '.vsphere_underlay.networks.nsx.external.netmask' $jsonFile) "   ++++++")
  external_gw_json=$(echo $external_gw_json | jq '.vsphere_underlay.networks.nsx.external += {"prefix": "'$(echo $prefix)'"}')
  #
  echo "   +++ Adding prefix for NSX overlay network..."
  prefix=$(jq -c -r '.vsphere_underlay.networks.nsx.overlay.nsx_pool.cidr' $jsonFile | cut -d"/" -f2)
  external_gw_json=$(echo $external_gw_json | jq '.vsphere_underlay.networks.nsx.overlay += {"prefix": "'$(echo $prefix)'"}')
  #
  echo "   +++ Adding prefix for NSX overlay Edge network..."
  prefix=$(jq -c -r '.vsphere_underlay.networks.nsx.overlay_edge.nsx_pool.cidr' $jsonFile | cut -d"/" -f2)
  external_gw_json=$(echo $external_gw_json | jq '.vsphere_underlay.networks.nsx.overlay_edge += {"prefix": "'$(echo $prefix)'"}')
  #
  if [[ $(jq -c -r .vcd $jsonFile) != "null" && $(jq -c -r .avi.config.cloud.type $jsonFile) == "CLOUD_NSXT" ]]; then
    echo "   +++ Adding external_gw.vcd_deployment: true"
    external_gw_json=$(echo $external_gw_json | jq '.external_gw += {"vcd_deployment": true}')
  else
    echo "   +++ Adding external_gw.vcd_deployment: false"
    external_gw_json=$(echo $external_gw_json | jq '.external_gw += {"vcd_deployment": false}')
  fi
  #
  if [[ $(jq -c -r .vcd $jsonFile) != "null" ]]; then
    disk=$(jq -c -r '.disk_if_vcd' $localJsonFile)
    vcd_ip=$(jq -c -r .vsphere_underlay.networks.vsphere.management.vcd_nested_ip $jsonFile)
  else
    disk=$(jq -c -r '.disk' $localJsonFile)
    vcd_ip=$(jq -c -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile)
  fi
  echo "   +++ Adding vcd_ip..."
  external_gw_json=$(echo $external_gw_json | jq '. += {"vcd_ip": "'$(echo $vcd_ip)'"}')
  #
  nfs_path=$(jq -c -r '.nfs_path' $localJsonFile)
  external_gw_json=$(echo $external_gw_json | jq '.external_gw  += {"nfs_path": "'$(echo $nfs_path)'"}')
  #
else # without NSX
  echo "   +++ Adding external_gw.nsx_deployment: false"
  external_gw_json=$(echo $external_gw_json | jq '.external_gw += {"nsx_deployment": false}')
  disk=$(jq -c -r '.disk' $localJsonFile)
fi
#
if [[ $(jq -c -r .avi $jsonFile) != "null" ]]; then
  #
  echo "   +++ Adding external_gw.avi_deployment: true"
  external_gw_json=$(echo $external_gw_json | jq '.external_gw += {"avi_deployment": true}')
else
  echo "   +++ Adding external_gw.avi_deployment: false"
  external_gw_json=$(echo $external_gw_json | jq '.external_gw += {"avi_deployment": false}')
fi
#
echo "   +++ Adding reverse DNS zone..."
ip_external_gw=$(jq -c -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile)
octets=""
addr=""
IFS="." read -r -a octets <<< "$ip_external_gw"
count=0
for octet in "${octets[@]}"; do if [ $count -eq 3 ]; then break ; fi ; addr=$octet"."$addr ;((count++)) ; done
reverse=${addr%.}
echo "   ++++++ Found: $reverse"
external_gw_json=$(echo $external_gw_json | jq '.external_gw.bind += {"reverse": "'$(echo $reverse)'"}')
#
echo "   +++ Adding prefix for management network..."
prefix=$(ip_prefix_by_netmask $(jq -c -r '.vsphere_underlay.networks.vsphere.management.netmask' $jsonFile) "   ++++++")
external_gw_json=$(echo $external_gw_json | jq '.vsphere_underlay.networks.vsphere.management += {"prefix": "'$(echo $prefix)'"}')
#
echo "   +++ Adding a date index"
date_index=$(date '+%Y%m%d%H%M%S')
external_gw_json=$(echo $external_gw_json | jq '. += {"date_index": '$(echo $date_index)'}')
#
echo "   +++ Adding Ubuntu OVA path"
ubuntu_ova_path=$(jq -c -r .ubuntu_ova_path $localJsonFile)
external_gw_json=$(echo $external_gw_json | jq '. += {"ubuntu_ova_path": "'$(echo $ubuntu_ova_path)'"}')
#
echo "   +++ alb_controller_name"
alb_controller_name=$(jq -c -r .alb_controller_name $localJsonFile)
external_gw_json=$(echo $external_gw_json | jq '.external_gw += {"alb_controller_name": "'$(echo $alb_controller_name)'"}')
#
echo "   +++ nsx_manager_name"
nsx_manager_name=$(jq -c -r .nsx_manager_name $localJsonFile)
external_gw_json=$(echo $external_gw_json | jq '.external_gw += {"nsx_manager_name": "'$(echo $nsx_manager_name)'"}')
#
echo "   +++ vcd_appliance_name"
vcd_appliance_name=$(jq -c -r .vcd_appliance_name $localJsonFile)
external_gw_json=$(echo $external_gw_json | jq '.external_gw += {"vcd_appliance_name": "'$(echo $vcd_appliance_name)'"}')
#
echo "   +++ Adding cpu..."
cpu=$(jq -c -r '.cpu' $localJsonFile)
external_gw_json=$(echo $external_gw_json | jq '. += {"cpu": "'$(echo $cpu)'"}')
#
echo "   +++ Adding memory..."
memory=$(jq -c -r '.memory' $localJsonFile)
external_gw_json=$(echo $external_gw_json | jq '. += {"memory": "'$(echo $memory)'"}')
#
echo "   +++ Adding disk..." # defined above if vcd is enabled or not
external_gw_json=$(echo $external_gw_json | jq '. += {"disk": "'$(echo $disk)'"}')
#
echo $external_gw_json | jq . | tee /root/external_gw.json > /dev/null
#
echo ""
echo "==> Checking vSphere VMs for name conflict..."
api_host="$(jq -r .vsphere_underlay.vcsa $jsonFile)"
vcenter_username=$TF_VAR_vsphere_underlay_username
vcenter_domain=''
vsphere_password=$TF_VAR_vsphere_underlay_password
token=$(/bin/bash /nestedVsphere8/bash/create_vcenter_api_session.sh "$vcenter_username" "$vcenter_domain" "$vsphere_password" "$api_host")
vcenter_api 6 10 "GET" $token "" $api_host "rest/vcenter/vm"
response_vm=$(echo $response_body)
for vm_entry in $(echo $response_vm | jq -c -r .value[])
do
  if [[ $(echo $vm_entry | jq -c -r .name) == "external-gw-$(jq -c -r .date_index /root/external_gw.json)" ]] ; then
    echo "  +++ ERROR +++ VM called "external-gw-$(jq -c -r .date_index /root/external_gw.json)" already exists"
    exit 255
  fi
done
echo "  +++ No conflict found, OK"

#
echo ""
echo "==> Downloading Ubuntu OVA"
if [ -s "$(jq -c -r .ubuntu_ova_path $localJsonFile)" ]; then echo "   +++ ubuntu file $(jq -c -r .ubuntu_ova_path $localJsonFile) is not empty" ; else curl -s -o $(jq -c -r .ubuntu_ova_path $localJsonFile) $(jq -c -r .ubuntu_ova_url $localJsonFile) ; fi
if [ -s "$(jq -c -r .ubuntu_ova_path $localJsonFile)" ]; then echo "   +++ ubuntu file $(jq -c -r .ubuntu_ova_path $localJsonFile) is not empty" ; else echo "   +++ ubuntu file $(jq -c -r .ubuntu_ova_path $localJsonFile) is empty" ; exit 255 ; fi
#
echo ""
echo "==> Copying the files..."
if [[ $(jq -c -r .nsx $jsonFile) != "null" ]]; then
  echo "   +++ with NSX..."
else
  echo "   +++ without NSX..."
  cp /nestedVsphere8/02_external_gateway/wo_nsx/* /nestedVsphere8/02_external_gateway/
fi
