#!/bin/bash
#
source /nestedVsphere8/bash/vcenter_api.sh
#
jsonFile="/root/nested_vsphere.json"
#
IFS=$'\n'
#
api_host="$(jq -r .vsphere_nested.vcsa_name $jsonFile).$(jq -r .external_gw.bind.domain $jsonFile)"
vsphere_nested_username=administrator
vcenter_domain=$(jq -r .vsphere_nested.sso.domain_name $jsonFile)
vsphere_nested_password=$TF_VAR_vsphere_nested_password
#
source /nestedVsphere8/bash/govc/variables.sh
#
# Network config
#
load_govc_env_wo_cluster
count=1
for ip in $(jq -r .vsphere_underlay.networks.vsphere.management.esxi_ips[] $jsonFile)
do
  govc dvs.add -dvs "$(jq -r .networks.vsphere.VMotion.vds_name $jsonFile)" -pnic=vmnic3 "$(jq -r .vsphere_nested.esxi.basename $jsonFile)$count.$(jq -r .external_gw.bind.domain $jsonFile)"
  count=$((count+1))
done
#