#!/bin/bash
#
source /nestedVsphere8/bash/vcenter_api.sh
#
jsonFile="/root/tanzu_wo_nsx.json"
#
IFS=$'\n'
#
api_host="$(jq -r .vsphere_nested.vcsa_name $jsonFile).$(jq -r .external_gw.bind.domain $jsonFile)"
vsphere_nested_username=administrator
vcenter_domain=$(jq -r .vsphere_nested.sso.domain_name $jsonFile)
vsphere_nested_password=$TF_VAR_vsphere_nested_password
#
# Namespace deletion
#
for ns in $(jq -c -r .tanzu.namespaces[] $jsonFile); do
  ns_name=$(echo $ns | jq -r .name)
  vcenter_api 6 10 "DELETE" $token "" $api_host "api/vcenter/namespaces/instances/${ns_name}"
done