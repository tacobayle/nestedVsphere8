#!/bin/bash
#
source /nestedVsphere8/bash/vcenter_api.sh
#
# vCenter API session creation
#
api_host=$1
vsphere_nested_username=administrator
vcenter_domain=$2
vsphere_nested_password=$3
workload_ntp_server=$4
storage_policy_id=$5
service_cidr_cidr_address=$6
service_cidr_cidr_prefix=$7
size_hint=$8
worker_DNS=$9
master_management_network_subnet_mask="${10}"
master_management_network_starting_address="${11}"
master_management_network_gateway="${12}"
master_management_network_address_count="${13}"
tanzu_supervisor_dvportgroup="${14}"
avi_cert="${15}"
avi_password="${16}"
avi_nested_ip="${17}"
content_library_id="${18}"
supervisor_primary_workload_network_name="${19}"
supervisor_primary_workload_network_address_range_address="${20}"
supervisor_primary_workload_network_address_range_count="${21}"
supervisor_primary_workload_network_gateway="${22}"
tanzu_worker_dvportgroup="${23}"
supervisor_primary_workload_network_subnet_mask="${24}"
cluster_id="${25}"
#
token=$(/bin/bash /nestedVsphere8/bash/create_vcenter_api_session.sh "$vsphere_nested_username" "$vcenter_domain" "$vsphere_nested_password" "$api_host")
#
# vsphere_tanzu_alb_wo_nsx use case
#
network_provider="VSPHERE_NETWORK"
provider="AVI"
#
# Building json data to create the supervisor cluster
#
json_data='
{
 "cluster_proxy_config": {
   "proxy_settings_source": "VC_INHERITED"
 },
 "workload_ntp_servers":["'${workload_ntp_server}'"],
 "image_storage":
 {
   "storage_policy":"'${storage_policy_id}'"
 },
 "master_NTP_servers":["'${workload_ntp_server}'"],
 "ephemeral_storage_policy":"'${storage_policy_id}'",
 "service_cidr":
 {
   "address":"'${service_cidr_cidr_address}'",
   "prefix": "'${service_cidr_cidr_prefix}'"
 },
 "size_hint":"'${size_hint}'",
 "worker_DNS":["'${worker_DNS}'"],
 "master_DNS":["'${worker_DNS}'"],
 "network_provider":"'${network_provider}'",
 "master_storage_policy":"'${storage_policy_id}'",
 "master_management_network":
 {
   "mode":"STATICRANGE",
   "address_range":
     {
       "subnet_mask":"'${master_management_network_subnet_mask}'",
       "starting_address":"'${master_management_network_starting_address}'",
       "gateway":"'${master_management_network_gateway}'",
       "address_count":"'${master_management_network_address_count}'"
     },
   "network":"'${tanzu_supervisor_dvportgroup}'"
 },
 "load_balancer_config_spec": {
   "address_ranges": [],
   "avi_config_create_spec": {
     "certificate_authority_chain": '${avi_cert}',
     "password": "'${avi_password}'",
     "server": {
       "host": "'${avi_nested_ip}'",
       "port": 443
     },
     "username": "admin"
   },
   "id": "avi",
   "provider": "AVI"
 },
 "default_kubernetes_service_content_library":"'${content_library_id}'",
 "workload_networks_spec": {
   "supervisor_primary_workload_network": {
     "network": "'${supervisor_primary_workload_network_name}'",
     "network_provider": "'${network_provider}'",
     "vsphere_network": {
       "address_ranges": [
         {
           "address": "'${supervisor_primary_workload_network_address_range_address}'",
           "count": '${supervisor_primary_workload_network_address_range_count}'
         }
       ],
       "gateway": "'${supervisor_primary_workload_network_gateway}'",
       "ip_assignment_mode": "STATICRANGE",
       "portgroup": "'${tanzu_worker_dvportgroup}'",
       "subnet_mask": "'${supervisor_primary_workload_network_subnet_mask}'"
     }
   }
 }
}'
#
vcenter_api 6 10 "POST" $token "${json_data}" $api_host "api/vcenter/namespace-management/clusters/${cluster_id}?action=enable"