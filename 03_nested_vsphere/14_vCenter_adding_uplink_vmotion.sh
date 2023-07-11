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
# Network config
#
load_govc_env
IFS=$'\n'
count=1
for ip in $(jq -r .vsphere_underlay.networks.vsphere.management.esxi_ips[] $jsonFile)
do
  govc dvs.add -dvs "$(jq -r .networks.vsphere.VMotion.vds_name $jsonFile)" -pnic=vmnic3 "$(jq -r .vsphere_nested.esxi.basename $jsonFile)$count.$(jq -r .external_gw.bind.domain $jsonFile)"
  count=$((count+1))
done
#