#!/bin/bash
#
source /nestedVsphere8/bash/vcenter_api.sh
#
jsonFile="/root/nested_vsphere.json"
#
api_host="$(jq -r .vsphere_nested.vcsa_name $jsonFile).$(jq -r .external_gw.bind.domain $jsonFile)"
vsphere_nested_username=administrator
vcenter_domain=$(jq -r .vsphere_nested.sso.domain_name $jsonFile)
vsphere_nested_password=$TF_VAR_vsphere_nested_password
#
source /nestedVsphere8/bash/govc/variables.sh
#
#curl_put () {
##  echo $1
##  echo $2
##  echo https://$3/api/$4
#  status_code=$(curl -k -X PUT -H "vmware-api-session-id: $1" -H "Content-Type: application/json" -d $2 -w "%{http_code}" --silent -o /dev/null "https://$3/api/$4")
#  re='^20[0-9]+$'
#  if [[ "$status_code"  =~ $re ]] ; then
#    echo "Config for $(basename $4) has been done successfully"
#  else
#    echo "!!! ERROR !!! : Config for $(basename $4) failed with HTTP code $status_code"
#    exit 1
#  fi
#}
#
#curl_post () {
#  echo $1
#  echo $2
#  echo https://$3/api/$4
#  status_code=$(curl -k -X POST -H "vmware-api-session-id: $1" -H "Content-Type: application/json" -d $2 -w "%{http_code}" --silent -o /dev/null "https://$3/api/$4")
#  echo $status_code
#  re='^20[0-9]+$'
#  if [[ "$status_code"  =~ $re ]] ; then
#    echo "Adding new $(basename $4) has been done successfully"
#  else
#    echo "!!! ERROR !!! : Adding new $(basename $4) failed with HTTP code $status_code"
#    exit 1
#  fi
#}
#
token=$(/bin/bash /nestedVsphere8/bash/create_vcenter_api_session.sh "$vsphere_nested_username" "$vcenter_domain" "$vsphere_nested_password" "$api_host")
vcenter_api 6 10 "PUT" $token '{"enabled":true}' $api_host "api/appliance/access/ssh"
vcenter_api 6 10 "PUT" $token '{"enabled":true}' $api_host "api/appliance/access/dcui"
vcenter_api 6 10 "PUT" $token '{"enabled":true}' $api_host "api/appliance/access/consolecli"
vcenter_api 6 10 "PUT" $token '{"enabled":true,"timeout":120}' $api_host "api/appliance/access/shell"
vcenter_api 6 10 "PUT" $token '{"max_days":0,"min_days":0,"warn_days":0}' $api_host "api/appliance/local-accounts/global-policy"
vcenter_api 6 10 "PUT" $token '{"name":'\"$(jq -r .vsphere_nested.timezone $jsonFile)\"'}' $api_host "api/appliance/system/time/timezone"

#curl_put $token '{"enabled":true}' $api_host "appliance/access/ssh"
#curl_put $token '{"enabled":true}' $api_host "appliance/access/dcui"
#curl_put $token '{"enabled":true}' $api_host "appliance/access/consolecli"
#curl_put $token '{"enabled":true,"timeout":120}' $api_host "appliance/access/shell"
#curl_put $token '{"max_days":0,"min_days":0,"warn_days":0}' $api_host "appliance/local-accounts/global-policy"
#curl_put $token '{"name":'\"$(jq -r .vsphere_nested.timezone $jsonFile)\"'}' $api_host "appliance/system/time/timezone"
##
# Add host in the cluster
#
IFS=$'\n'
count=1
for ip in $(jq -r .vsphere_underlay.networks.vsphere.management.esxi_ips[] $jsonFile)
do
  load_govc_env
  if [[ $count -ne 1 ]] ; then
  echo "Adding host $ip in the cluster"
  govc cluster.add -hostname "$(jq -r .vsphere_nested.esxi.basename $jsonFile)$count.$(jq -r .external_gw.bind.domain $jsonFile)" -username "root" -password "$TF_VAR_nested_esxi_root_password" -noverify
  fi
  count=$((count+1))
done
#
# Network config
#
load_govc_env
govc dvs.create -mtu $(jq -r .networks.vds.mtu $jsonFile) -discovery-protocol $(jq -r .networks.vds.discovery_protocol $jsonFile) -product-version=$(jq -r .networks.vds.version $jsonFile) "$(jq -r .networks.vsphere.management.vds_name $jsonFile)"
govc dvs.create -mtu $(jq -r .networks.vds.mtu $jsonFile) -discovery-protocol $(jq -r .networks.vds.discovery_protocol $jsonFile) -product-version=$(jq -r .networks.vds.version $jsonFile) "$(jq -r .networks.vsphere.VMotion.vds_name $jsonFile)"
govc dvs.create -mtu $(jq -r .networks.vds.mtu $jsonFile) -discovery-protocol $(jq -r .networks.vds.discovery_protocol $jsonFile) -product-version=$(jq -r .networks.vds.version $jsonFile) "$(jq -r .networks.vsphere.VSAN.vds_name $jsonFile)"
govc dvs.portgroup.add -dvs "$(jq -r .networks.vsphere.management.vds_name $jsonFile)" -vlan 0 "$(jq -r .networks.vsphere.management.port_group_name $jsonFile)"
govc dvs.portgroup.add -dvs "$(jq -r .networks.vsphere.management.vds_name $jsonFile)" -vlan 0 "$(jq -r .networks.vsphere.management.port_group_name $jsonFile)-vmk"
govc dvs.portgroup.add -dvs "$(jq -r .networks.vsphere.VMotion.vds_name $jsonFile)" -vlan 0 "$(jq -r .networks.vsphere.VMotion.port_group_name $jsonFile)"
govc dvs.portgroup.add -dvs "$(jq -r .networks.vsphere.VSAN.vds_name $jsonFile)" -vlan 0 "$(jq -r .networks.vsphere.VSAN.port_group_name $jsonFile)"
IFS=$'\n'
count=1
for ip in $(jq -r .vsphere_underlay.networks.vsphere.management.esxi_ips[] $jsonFile)
do
  govc dvs.add -dvs "$(jq -r .networks.vsphere.management.vds_name $jsonFile)" -pnic=vmnic0 "$(jq -r .vsphere_nested.esxi.basename $jsonFile)$count.$(jq -r .external_gw.bind.domain $jsonFile)"
  govc dvs.add -dvs "$(jq -r .networks.vsphere.VMotion.vds_name $jsonFile)" -pnic=vmnic1 "$(jq -r .vsphere_nested.esxi.basename $jsonFile)$count.$(jq -r .external_gw.bind.domain $jsonFile)"
  govc dvs.add -dvs "$(jq -r .networks.vsphere.VSAN.vds_name $jsonFile)" -pnic=vmnic2 "$(jq -r .vsphere_nested.esxi.basename $jsonFile)$count.$(jq -r .external_gw.bind.domain $jsonFile)"
  count=$((count+1))
done
#
# save govc about -json
#
govc about -json | tee /root/vcenter_about.json
#
sleep 5
#
echo "++++++++++++++++++++++++++++++++"
echo "Update vCenter Appliance port group location"
load_govc_env
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