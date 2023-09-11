#!/bin/bash
#
source /nestedVsphere8/bash/vcenter_api.sh
source /nestedVsphere8/bash/ip.sh
source /nestedVsphere8/bash/download_file.sh
#
jsonFile="/root/variables.json"
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
echo "   +++ Adding alb_controller_name"
alb_controller_name=$(jq -c -r .alb_controller_name $localJsonFile)
external_gw_json=$(echo $external_gw_json | jq '.external_gw += {"alb_controller_name": "'$(echo $alb_controller_name)'"}')
#
echo "   +++ Adding nsx_manager_name"
nsx_manager_name=$(jq -c -r .nsx_manager_name $localJsonFile)
external_gw_json=$(echo $external_gw_json | jq '.external_gw += {"nsx_manager_name": "'$(echo $nsx_manager_name)'"}')
#
echo "   +++ Adding vcd_appliance_name"
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
echo "   +++ Adding ansible_version..."
ansible_version=$(jq -c -r '.ansible_version' $localJsonFile)
external_gw_json=$(echo $external_gw_json | jq '. += {"ansible_version": "'$(echo $ansible_version)'"}')
#
echo "   +++ Adding avi_sdk_version..."
avi_sdk_version=$(jq -c -r '.avi_sdk_version' $localJsonFile)
external_gw_json=$(echo $external_gw_json | jq '. += {"avi_sdk_version": "'$(echo $avi_sdk_version)'"}')
#
nfs_path=$(jq -c -r '.nfs_path' $localJsonFile)
external_gw_json=$(echo $external_gw_json | jq '.external_gw  += {"nfs_path": "'$(echo $nfs_path)'"}')
#
if [[ $(jq -c -r .unmanaged_k8s_status $jsonFile) != "true" ]]; then
  echo "   +++ Adding .default_kubectl_version... from local variables.json"
  default_kubectl_version=$(jq -c -r '.default_kubectl_version' $localJsonFile)
  external_gw_json=$(echo $external_gw_json | jq '. += {"default_kubectl_version": "'$(echo $default_kubectl_version)'"}')
fi
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_telco" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_vcd" ]]; then
  #
  echo "   +++ Adding Networks MTU details"
  networks_details=$(jq -c -r .networks $localJsonFile)
  external_gw_json=$(echo $external_gw_json | jq '. += {"networks": '$(echo $networks_details)'}')
  #
  echo "   +++ Adding prefix for NSX external network..."
  prefix=$(jq -c -r .vsphere_underlay.networks.nsx.external.cidr $jsonFile | cut -d"/" -f2)
  external_gw_json=$(echo $external_gw_json | jq '.vsphere_underlay.networks.nsx.external += {"prefix": "'$(echo $prefix)'"}')
  #
  echo "   +++ Adding prefix for NSX overlay network..."
  prefix=$(jq -c -r '.vsphere_underlay.networks.nsx.overlay.cidr' $jsonFile | cut -d"/" -f2)
  external_gw_json=$(echo $external_gw_json | jq '.vsphere_underlay.networks.nsx.overlay += {"prefix": "'$(echo $prefix)'"}')
  #
  echo "   +++ Adding prefix for NSX overlay Edge network..."
  prefix=$(jq -c -r '.vsphere_underlay.networks.nsx.overlay_edge.cidr' $jsonFile | cut -d"/" -f2)
  external_gw_json=$(echo $external_gw_json | jq '.vsphere_underlay.networks.nsx.overlay_edge += {"prefix": "'$(echo $prefix)'"}')
  #
  if grep -q "nsx" /nestedVsphere8/02_external_gateway/variables.tf ; then
    echo "   +++ variable nsx is already in /nestedVsphere8/02_external_gateway/variables.tf"
  else
    echo "   +++ Adding variable nsx in /nestedVsphere8/02_external_gateway/variables.tf"
    echo 'variable "nsx" {}' | tee -a /nestedVsphere8/02_external_gateway/variables.tf > /dev/null
  fi
  #
  if grep -q "networks" /nestedVsphere8/02_external_gateway/variables.tf ; then
    echo "   +++ variable networks is already in /nestedVsphere8/02_external_gateway/variables.tf"
  else
    echo "   +++ Adding variable networks in /nestedVsphere8/02_external_gateway/variables.tf"
    echo 'variable "networks" {}' | tee -a /nestedVsphere8/02_external_gateway/variables.tf > /dev/null
  fi
  #
  mv /nestedVsphere8/02_external_gateway/external_gw_nsx.tf.disabled /nestedVsphere8/02_external_gateway/external_gw_nsx.tf
  mv /nestedVsphere8/02_external_gateway/external_gw_vsphere_tanzu_alb.tf /nestedVsphere8/02_external_gateway/external_gw_vsphere_tanzu_alb.tf.disabled
  mv /nestedVsphere8/02_external_gateway/external_gw.tf /nestedVsphere8/02_external_gateway/external_gw.tf.disabled
  #
  new_routes="[]"
  if [[ $(jq -c -r '.nsx.config.segments_overlay | length' $jsonFile) -gt 0 ]] ; then
    echo "   +++ Creating External gateway routes to subnet segments..."
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
  if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_telco" ]]; then
    if [[ $(jq -c -r '.avi.config.cloud.additional_subnets | length' $jsonFile) -gt 0 ]] ; then
      echo "   +++ Creating External gateway routes to .avi.config.cloud.additional_subnets..."
      for network in $(jq -c -r .avi.config.cloud.additional_subnets[] $jsonFile)
      do
        for subnet in $(echo $network | jq -c -r '.subnets[]')
        do
          count=0
          for tier0 in $(jq -c -r .nsx.config.tier0s[] $jsonFile)
          do
            if [[ $(echo $tier0 | jq 'has("bgp")') == "true" ]] ; then
              if [[ $(echo $subnet | jq -c -r .bgp_label) == $(echo $tier0 | jq -c -r .bgp.avi_peer_label) ]] ; then
                new_routes=$(echo $new_routes | jq '. += [{"to": "'$(echo $subnet | jq -c -r .cidr)'", "via": "'$(jq -c -r .vsphere_underlay.networks.nsx.external.tier0_vips["$count"] $jsonFile)'"}]')
                echo "   +++ Route to $(echo $subnet | jq -c -r .cidr) via $(jq -c -r .vsphere_underlay.networks.nsx.external.tier0_vips["$count"] $jsonFile) added: OK"
              fi
            fi
            ((count++))
          done
        done
      done
    fi
  fi
  #
  if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_telco" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_vcd" ]]; then
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
    #
    #
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
      external_gw_json=$(echo $external_gw_json | jq '.external_gw  += {"ip_table_prefixes": '$(echo $ip_table_prefixes)'}')
    fi
  fi
#
  echo "   +++ Adding .routes..."
  external_gw_json=$(echo $external_gw_json | jq '.external_gw += {"routes": '$(echo $new_routes)'}')
  #
  echo "   +++ Adding .default_kubectl_version... from local variables.json"
  default_kubectl_version=$(jq -c -r '.default_kubectl_version' $localJsonFile)
  external_gw_json=$(echo $external_gw_json | jq '. += {"default_kubectl_version": "'$(echo $default_kubectl_version)'"}')
  #
fi
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_alb_wo_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_tanzu_alb_wo_nsx" ]]; then
  alb_networks='["se", "backend", "vip", "tanzu"]'
  ip_table_prefixes="[]"
  for network in $(echo $alb_networks | jq -c -r .[])
  do
    echo "   +++ Adding prefix for alb $network network..."
    netmask=$(ip_netmask_by_prefix $(jq -c -r '.vsphere_underlay.networks.alb.'$network'.cidr'  $jsonFile| cut -d"/" -f2) "   ++++++")
    external_gw_json=$(echo $external_gw_json | jq '.vsphere_underlay.networks.alb.'$network' += {"netmask": "'$(echo $netmask)'"}')
    if [[ $network != "se" ]] ; then ip_table_prefixes=$(echo $ip_table_prefixes | jq '. += ['$(jq .vsphere_underlay.networks.alb.$network.cidr $jsonFile)']') ; fi
    #
    if [[ $(jq -c -r .vsphere_underlay.networks.alb.$network.k8s_clusters $jsonFile) != "null" ]] ; then
      echo "   +++ Adding .default_kubectl_version... from the first k8s cluster version"
      default_kubectl_version=$(jq -c -r .vsphere_underlay.networks.alb.$network.k8s_clusters[0].k8s_version $jsonFile)
      external_gw_json=$(echo $external_gw_json | jq '. += {"default_kubectl_version": "'$(echo $default_kubectl_version)'"}')
    fi
  done
  #
  echo "   +++ Adding Networks MTU details"
  networks_details=$(jq -c -r .networks $localJsonFile)
  external_gw_json=$(echo $external_gw_json | jq '. += {"networks": '$(echo $networks_details)'}')
  #
  echo "   +++ Creating External ip_table_prefixes..."
  external_gw_json=$(echo $external_gw_json | jq '.external_gw  += {"ip_table_prefixes": '$(echo $ip_table_prefixes)'}')
  #
fi
#
disk=$(jq -c -r '.disk' $localJsonFile)
vcd_ip=$(jq -c -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile)
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_vcd" ]]; then
  disk=$(jq -c -r '.disk_if_vcd' $localJsonFile)
  vcd_ip=$(jq -c -r .vsphere_underlay.networks.vsphere.management.vcd_nested_ip $jsonFile)
fi
#
echo "   +++ Adding disk..." # defined above if vcd is enabled or not
external_gw_json=$(echo $external_gw_json | jq '. += {"disk": "'$(echo $disk)'"}')
#
echo "   +++ Adding vcd_ip..."
external_gw_json=$(echo $external_gw_json | jq '. += {"vcd_ip": "'$(echo $vcd_ip)'"}')
#
echo $external_gw_json | jq . | tee /root/external_gw.json > /dev/null
#
#
#
echo "   +++ Updating /etc/hosts..."
contents=$(cat /etc/hosts | grep -v $(jq -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile))
echo "${contents}" | tee /etc/hosts > /dev/null
contents="$(jq -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile) external-gw"
echo "${contents}" | tee -a /etc/hosts > /dev/null
#
#
#
echo "   +++ Creating an alias 'external' to ssh external-gw..."
contents=$(cat /root/.profile | grep -v "external")
echo "${contents}" | tee /root/.profile > /dev/null
echo "alias external='ssh -o StrictHostKeyChecking=no ubuntu@external-gw'" | tee -a /root/.profile > /dev/null
source /root/.profile
#
#
if [[ $(jq -c -r .deployment $jsonFile) != "vsphere_nsx_alb_telco" ]] ; then

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
fi
#
#
download_file_from_url_to_location "$(jq -c -r .ubuntu_ova_url $localJsonFile)" "$(jq -c -r .ubuntu_ova_path $localJsonFile)" "Ubuntu OVA"
#
