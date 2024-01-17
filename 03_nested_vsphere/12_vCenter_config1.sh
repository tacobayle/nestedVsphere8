#!/bin/bash
#
source /nestedVsphere8/bash/vcenter_api.sh
source /nestedVsphere8/bash/govc/variables.sh
#
jsonFile="/root/nested_vsphere.json"
#
api_host="$(jq -r .vsphere_nested.vcsa_name $jsonFile).$(jq -r .external_gw.bind.domain $jsonFile)"
vsphere_nested_username=administrator
vcenter_domain=$(jq -r .vsphere_nested.sso.domain_name $jsonFile)
vsphere_nested_password=$TF_VAR_vsphere_nested_password
#
IFS=$'\n'
#
token=$(/bin/bash /nestedVsphere8/bash/create_vcenter_api_session.sh "$vsphere_nested_username" "$vcenter_domain" "$vsphere_nested_password" "$api_host")
vcenter_api 6 10 "PUT" $token '{"enabled":true}' $api_host "api/appliance/access/ssh"
vcenter_api 6 10 "PUT" $token '{"enabled":true}' $api_host "api/appliance/access/dcui"
vcenter_api 6 10 "PUT" $token '{"enabled":true}' $api_host "api/appliance/access/consolecli"
vcenter_api 6 10 "PUT" $token '{"enabled":true,"timeout":120}' $api_host "api/appliance/access/shell"
vcenter_api 6 10 "PUT" $token '{"max_days":0,"min_days":0,"warn_days":0}' $api_host "api/appliance/local-accounts/global-policy"
vcenter_api 6 10 "PUT" $token '{"name":'\"$(jq -r .vsphere_nested.timezone $jsonFile)\"'}' $api_host "api/appliance/system/time/timezone"
#
# Add cluster(s) in dc
#
count=1
for cluster in $(jq -r .vsphere_nested.cluster_list[] $jsonFile)
do
  if [[ $count -ne 1 ]] ; then
    load_govc_env_wo_cluster
    echo "Adding vSphere cluster ${cluster}"
    govc cluster.create "${cluster}"
  fi
  count=$((count+1))
done
#
# Add host in the cluster(s)
#
count=1
for ip in $(jq -r .vsphere_underlay.networks.vsphere.management.esxi_ips[] $jsonFile)
do
  if [[ $count -ne 1 ]] ; then
    cluster_count=$(((${count}+$(jq -c -r '.vsphere_nested.cluster_list | length' $jsonFile)-1)/$(jq -c -r '.vsphere_nested.cluster_list | length' $jsonFile)))
    load_govc_env_with_cluster "$(jq -c -r .vsphere_nested.cluster_list[${cluster_count}] $jsonFile)"
    echo "Adding host $ip in the cluster"
    govc cluster.add -hostname "$(jq -r .vsphere_nested.esxi.basename $jsonFile)$count.$(jq -r .external_gw.bind.domain $jsonFile)" -username "root" -password "$TF_VAR_nested_esxi_root_password" -noverify
  fi
  count=$((count+1))
done
#
# Network config
#
load_govc_env_wo_cluster
govc dvs.create -mtu $(jq -r .networks.vds.mtu $jsonFile) -discovery-protocol $(jq -r .networks.vds.discovery_protocol $jsonFile) -product-version=$(jq -r .networks.vds.version $jsonFile) "$(jq -r .networks.vsphere.management.vds_name $jsonFile)"
govc dvs.create -mtu $(jq -r .networks.vds.mtu $jsonFile) -discovery-protocol $(jq -r .networks.vds.discovery_protocol $jsonFile) -product-version=$(jq -r .networks.vds.version $jsonFile) "$(jq -r .networks.vsphere.VMotion.vds_name $jsonFile)"
govc dvs.create -mtu $(jq -r .networks.vds.mtu $jsonFile) -discovery-protocol $(jq -r .networks.vds.discovery_protocol $jsonFile) -product-version=$(jq -r .networks.vds.version $jsonFile) "$(jq -r .networks.vsphere.VSAN.vds_name $jsonFile)"
govc dvs.portgroup.add -dvs "$(jq -r .networks.vsphere.management.vds_name $jsonFile)" -vlan 0 "$(jq -r .networks.vsphere.management.port_group_name $jsonFile)"
govc dvs.portgroup.add -dvs "$(jq -r .networks.vsphere.management.vds_name $jsonFile)" -vlan 0 "$(jq -r .networks.vsphere.management.port_group_name $jsonFile)-vmk"
govc dvs.portgroup.add -dvs "$(jq -r .networks.vsphere.VMotion.vds_name $jsonFile)" -vlan 0 "$(jq -r .networks.vsphere.VMotion.port_group_name $jsonFile)"
govc dvs.portgroup.add -dvs "$(jq -r .networks.vsphere.VSAN.vds_name $jsonFile)" -vlan 0 "$(jq -r .networks.vsphere.VSAN.port_group_name $jsonFile)"
# Add ESXi host on each port group
count=1
if [[ $(jq -c -r '.vsphere_underlay.networks_vsphere_dual_attached' $jsonFile) == "true" || $(jq -c -r '.vsphere_underlay.networks_vsphere_dual_attached' $jsonFile) == "True" ]]; then
  for ip in $(jq -r .vsphere_underlay.networks.vsphere.management.esxi_ips[] $jsonFile)
  do
    govc dvs.add -dvs "$(jq -r .networks.vsphere.management.vds_name $jsonFile)" -pnic=vmnic0 "$(jq -r .vsphere_nested.esxi.basename $jsonFile)$count.$(jq -r .external_gw.bind.domain $jsonFile)"
    govc dvs.add -dvs "$(jq -r .networks.vsphere.VMotion.vds_name $jsonFile)" -pnic=vmnic1 "$(jq -r .vsphere_nested.esxi.basename $jsonFile)$count.$(jq -r .external_gw.bind.domain $jsonFile)"
    govc dvs.add -dvs "$(jq -r .networks.vsphere.VSAN.vds_name $jsonFile)" -pnic=vmnic2 "$(jq -r .vsphere_nested.esxi.basename $jsonFile)$count.$(jq -r .external_gw.bind.domain $jsonFile)"
    count=$((count+1))
  done
fi
#
if [[ $(jq -c -r '.vsphere_underlay.networks_vsphere_dual_attached' $jsonFile) == "false" || $(jq -c -r '.vsphere_underlay.networks_vsphere_dual_attached' $jsonFile) == "False" ]]; then
  for ip in $(jq -r .vsphere_underlay.networks.vsphere.management.esxi_ips[] $jsonFile)
  do
    govc dvs.add -dvs "$(jq -r .networks.vsphere.management.vds_name $jsonFile)" -pnic=vmnic3 "$(jq -r .vsphere_nested.esxi.basename $jsonFile)$count.$(jq -r .external_gw.bind.domain $jsonFile)"
    count=$((count+1))
  done
fi
#
# save govc about -json
#
govc about -json | tee /root/vcenter_about.json
#
sleep 5
#
echo "++++++++++++++++++++++++++++++++"
echo "Update vCenter Appliance port group location"
load_govc_env_with_cluster "$(jq -r .vsphere_nested.cluster_basename $jsonFile)-1"
govc vm.network.change -vm $(jq -r .vsphere_nested.vcsa_name $jsonFile) -net $(jq -r .networks.vsphere.management.port_group_name $jsonFile) ethernet-0 &
govc_pid=$(echo $!)
echo "Waiting 5 secs to check if vCenter VM is UP"
sleep 10
if ping -c 1 $api_host &> /dev/null
then
  echo "vCenter VM is UP"
  #
  # Sometimes the GOVC command to migrate the vCenter VM to new port group fails
  #
  kill $(echo $govc_pid) || true
else
  echo "vCenter VM is DOWN - exit script config"
  exit
fi