#!/bin/bash
#
jsonFile="/root/nested_vsphere.json"
#
api_host="$(jq -r .vsphere_nested.vcsa_name $jsonFile).$(jq -r .external_gw.bind.domain $jsonFile)"
vsphere_nested_username=administrator
vcenter_domain=$(jq -r .vsphere_nested.sso.domain_name $jsonFile)
vsphere_nested_password=$TF_VAR_vsphere_nested_password
#
load_govc_env () {
  export GOVC_USERNAME="$vsphere_nested_username@$vcenter_domain"
  export GOVC_PASSWORD=$vsphere_nested_password
  export GOVC_DATACENTER=$(jq -r .vsphere_nested.datacenter $jsonFile)
  export GOVC_INSECURE=true
  export GOVC_CLUSTER=$(jq -r .vsphere_nested.cluster $jsonFile)
  export GOVC_URL=$api_host
}
#
load_govc_esxi () {
  export GOVC_USERNAME="root"
  export GOVC_PASSWORD=$TF_VAR_nested_esxi_root_password
  export GOVC_INSECURE=true
  unset GOVC_DATACENTER
  unset GOVC_CLUSTER
  unset GOVC_URL
}
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
  echo "Deleting vswitch called vSwitch2 for Host $ip"
  govc host.esxcli network vswitch standard remove -v vSwitch2
done