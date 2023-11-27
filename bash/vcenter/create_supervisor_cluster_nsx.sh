#!/bin/bash
#
vsphere_nested_username=administrator
vcenter_domain="${2}"
kubectl_password="${3}"
storage_policy_id="${4}"

#
network_provider="NSXT_CONTAINER_PLUGIN"
json_data='
{
 "ephemeral_storage_policy":"'${storage_policy_id}'",
 "image_storage":
 {
   "storage_policy":"'${storage_policy_id}'"
 },
 "master_storage_policy":"'${storage_policy_id}'",

 "cluster_proxy_config": {
   "proxy_settings_source": "VC_INHERITED"
 },
 "workload_ntp_servers":["'${external_gw_ip}'"],
 "master_management_network":
 {
   "mode":"STATICRANGE",
   "address_range":
     {
       "subnet_mask":"'$(ip_netmask_by_prefix $(jq -c -r '.vsphere_underlay.networks.alb.tanzu.cidr' $jsonFile| cut -d"/" -f2) "   ++++++")'",
       "starting_address":"'$(jq -r .vsphere_underlay.networks.alb.tanzu.tanzu_supervisor_starting_ip $jsonFile)'",
       "gateway":"'$(jq -r .vsphere_underlay.networks.alb.tanzu.external_gw_ip $jsonFile)'",
       "address_count":'$(jq -r .vsphere_underlay.networks.alb.tanzu.tanzu_supervisor_count $jsonFile)'
     },
   "network":"'${tanzu_supervisor_dvportgroup}'"
 },
}'