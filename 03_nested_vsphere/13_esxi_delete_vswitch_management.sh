#!/bin/bash
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
# Cleaning unused Standard vswitch config and VM port group
#
echo "++++++++++++++++++++++++++++++++"
echo "Cleaning unused Standard vswitch config"
IFS=$'\n'
load_govc_esxi
echo ""
echo "++++++++++++++++++++++++++++++++"
for ip in $(cat $jsonFile | jq -c -r .vsphere_underlay.networks.vsphere.management.esxi_ips[])
do
  export GOVC_URL=$ip
  echo "Deleting port group called VM Network for Host $ip"
  govc host.esxcli network vswitch standard portgroup remove -p "VM Network" -v "vSwitch0"
  echo "Deleting port group called Management Network for Host $ip"
  govc host.esxcli network vswitch standard portgroup remove -p "Management Network" -v "vSwitch0"
  echo "Deleting vswitch called vSwitch0 for Host $ip"
  govc host.esxcli network vswitch standard remove -v vSwitch0
done