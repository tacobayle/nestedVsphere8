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
token=$(/bin/bash /nestedVsphere8/bash/create_vcenter_api_session.sh "$vsphere_nested_username" "$vcenter_domain" "$vsphere_nested_password" "$api_host")
#
# Create Content Library for tanzu
#
vcenter_api 6 10 "GET" $token '' $api_host "rest/vcenter/datastore"
datastore_id=$(echo $response_body | jq -c -r .value[0].datastore)
ValidCmThumbPrint=$(openssl s_client -connect $(jq -c -r .tanzu_local.content_library.subscription_url $jsonFile  | cut -d"/" -f3):443 < /dev/null 2>/dev/null | openssl x509 -fingerprint -noout -in /dev/stdin | awk -F'Fingerprint=' '{print $2}')
json_data='
{
  "storage_backings":
  [
    {
      "datastore_id":"'${datastore_id}'",
      "type":"DATASTORE"
    }
  ],
  "type": '$(jq .tanzu_local.content_library.type $jsonFile)',
  "version":"2",
  "subscription_info":
    {
      "authentication_method":"NONE",
      "ssl_thumbprint":"'${ValidCmThumbPrint}'",
      "automatic_sync_enabled": '$(jq .tanzu_local.content_library.automatic_sync_enabled $jsonFile)',
      "subscription_url": '$(jq .tanzu_local.content_library.subscription_url $jsonFile)',
      "on_demand": '$(jq .tanzu_local.content_library.on_demand $jsonFile)'
    },
  "name": '$(jq .tanzu_local.content_library.name $jsonFile)'
}'
#echo $json_data
vcenter_api 6 10 "POST" $token "${json_data}" $api_host "api/content/subscribed-library"
content_library_id=$(echo $response_body | tr -d '"')
echo "   +++ testing if variable content_library_id is not empty" ; if [ -z "$content_library_id" ] ; then exit 255 ; fi
#vcenter_api 6 10 "GET" $token '' $api_host "rest/com/vmware/content/subscribed-library"
#content_library_id=$(echo $response_body | jq -c -r .value[0])
#
# Retrieve cluster id
#
vcenter_api 6 10 "GET" $token '' $api_host "api/vcenter/cluster"
cluster_id=$(echo $response_body | jq -r --arg cluster "$(jq -c -r .vsphere_nested.cluster $jsonFile)" '.[] | select(.name == $cluster).cluster')
#echo $cluster_id
echo "   +++ testing if variable cluster_id is not empty" ; if [ -z "$cluster_id" ] ; then exit 255 ; fi
#
# Retrieve storage policy
#
vcenter_api 6 10 "GET" $token '' $api_host "api/vcenter/storage/policies"
storage_policy_id=$(echo $response_body | jq -r --arg policy "$(jq -c -r .tanzu_local.storage_policy_name $jsonFile)" '.[] | select(.name == $policy) | .policy')
#echo $storage_policy_id
echo "   +++ testing if variable storage_policy_id is not empty" ; if [ -z "$storage_policy_id" ] ; then exit 255 ; fi
#
# DNS NTP
#
external_gw_ip=$(jq -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile)
#echo $external_gw_ip
#
# Retrieve Network details and dvportgroup(s)
#
vcenter_api 6 10 "GET" $token '' $api_host "api/vcenter/network"
tanzu_supervisor_dvportgroup=$(echo $response_body | jq -r --arg pg "$(jq -c -r .networks.alb.tanzu.port_group_name $jsonFile)" '.[] | select(.name == $pg) | .network')
#echo $tanzu_supervisor_dvportgroup
echo "   +++ testing if variable tanzu_supervisor_dvportgroup is not empty" ; if [ -z "$tanzu_supervisor_dvportgroup" ] ; then exit 255 ; fi
tanzu_worker_dvportgroup=$(echo $response_body | jq -r --arg pg "$(jq -c -r .networks.alb.backend.port_group_name $jsonFile)" '.[] | select(.name == $pg) | .network')
#echo $tanzu_worker_dvportgroup
echo "   +++ testing if variable tanzu_worker_dvportgroup is not empty" ; if [ -z "$tanzu_worker_dvportgroup" ] ; then exit 255 ; fi
#
# Retrieve Avi Details
#
echo "   +++ getting NSX ALB certificate..."
openssl s_client -showcerts -connect $(jq -r .vsphere_underlay.networks.vsphere.management.avi_nested_ip $jsonFile):443  </dev/null 2>/dev/null|sed -ne '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' > /tmp/temp_avi-ca.cert
if [ ! -s /tmp/temp_avi-ca.cert ] ; then exit 255 ; fi
avi_cert=$(jq -sR . /tmp/temp_avi-ca.cert)
avi_password=${TF_VAR_avi_password}
avi_nested_ip=$(jq -r .vsphere_underlay.networks.vsphere.management.avi_nested_ip $jsonFile)
avi_username="admin"
#
# Retrieve network_provider
#
echo "   +++ getting network_provider..."
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_tanzu_alb_wo_nsx"  ]]; then
 network_provider="VSPHERE_NETWORK"
 provider_="AVI"
fi
#
# Building json data to create the supervisor cluster
#
json_data='
{
  "cluster_proxy_config": {
    "proxy_settings_source": "VC_INHERITED"
  },
  "workload_ntp_servers":["'${external_gw_ip}'"],
  "image_storage":
  {
    "storage_policy":"'${storage_policy_id}'"
  },
  "master_NTP_servers":["'${external_gw_ip}'"],
  "ephemeral_storage_policy":"'${storage_policy_id}'",
  "service_cidr":
  {
    "address":"'$(jq -r .tanzu.supervisor_cluster.service_cidr $jsonFile | cut -d"/" -f1)'",
    "prefix": '$(jq -r .tanzu.supervisor_cluster.service_cidr $jsonFile | cut -d"/" -f2)'
  },
  "size_hint":"'$(jq -r .tanzu.supervisor_cluster.size $jsonFile)'",
  "worker_DNS":["'${external_gw_ip}'"],
  "master_DNS":["'${external_gw_ip}'"],
  "network_provider":"'${network_provider}'",
  "master_storage_policy":"'${storage_policy_id}'",
  "master_management_network":
  {
    "mode":"STATICRANGE",
    "address_range":
      {
        "subnet_mask":"'$(jq -r .vsphere_underlay.networks.alb.tanzu.netmask $jsonFile)'",
        "starting_address":"'$(jq -r .vsphere_underlay.networks.alb.tanzu.tanzu_supervisor_starting_ip $jsonFile)'",
        "gateway":"'$(jq -r .vsphere_underlay.networks.alb.tanzu.external_gw_ip $jsonFile)'",
        "address_count":'$(jq -r .vsphere_underlay.networks.alb.tanzu.tanzu_supervisor_count $jsonFile)'
      },
    "network":"'${tanzu_supervisor_dvportgroup}'"
  },
  "load_balancer_config_spec": {
    "address_ranges": [],
    "avi_config_create_spec": {
      "certificate_authority_chain": '${avi_cert}',
      "password": "'${avi_password}'",
      "server": {
        "host": "'$(jq -c -r .vsphere_underlay.networks.vsphere.management.avi_nested_ip $jsonFile)'",
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
      "network": "'$(jq -r .networks.alb.backend.port_group_name $jsonFile)'",
      "network_provider": "'${network_provider}'",
      "vsphere_network": {
        "address_ranges": [
          {
            "address": "'$(jq -r .vsphere_underlay.networks.alb.backend.tanzu_workers_starting_ip $jsonFile)'",
            "count": '$(jq -r .vsphere_underlay.networks.alb.backend.tanzu_workers_count $jsonFile)'
          }
        ],
        "gateway": "'$(jq -r .vsphere_underlay.networks.alb.backend.external_gw_ip $jsonFile)'",
        "ip_assignment_mode": "STATICRANGE",
        "portgroup": "'${tanzu_worker_dvportgroup}'",
        "subnet_mask": "'$(jq -r .vsphere_underlay.networks.alb.backend.netmask $jsonFile)'"
      }
    }
  }
}'
vcenter_api 6 10 "POST" $token "${json_data}" $api_host "api/vcenter/namespace-management/clusters/${cluster_id}?action=enable"
#
# Wait for supervisor cluster to be running
#
retry_tanzu_supervisor=61
pause_tanzu_supervisor=120
attempt_tanzu_supervisor=1
while true ; do
  echo "attempt $attempt_tanzu_supervisor to get supervisor cluster config_status RUNNING"
  vcenter_api 6 10 "GET" $token '' $api_host "api/vcenter/namespace-management/clusters"
  if [[ $(echo $response_body | jq -c -r .[0].config_status) == "RUNNING" ]]; then
    echo "supervisor cluster is $(echo $response_body | jq -c -r .[0].config_status) after $attempt_tanzu_supervisor attempts"
    break 2
  fi
  ((attempt_tanzu_supervisor++))
  if [ $attempt_tanzu_supervisor -eq $retry_tanzu_supervisor ]; then
    echo "Unable to get supervisor cluster config_status RUNNING after $attempt_tanzu_supervisor"
    exit 255
  fi
  sleep $pause_tanzu_supervisor
done
#
# Namespace creation
#
for ns in $(jq -c -r .tanzu.namespaces[] $jsonFile); do
  vcenter_api 6 10 "GET" $token '' $api_host "api/vcenter/namespace-management/clusters"
  cluster_id=$(echo $response_body | jq -c -r .[0].cluster)
  sso_domain=$(jq -c -r .vsphere_nested.sso.domain_name jsonFile)
  ns_name=$(echo $ns | jq -r .name)
  json_data='
  {
    "cluster": "'${cluster_id}'",
    "access_list": [
      {
        "role": "OWNER",
        "subject_type": "USER",
        "subject": "Administrator",
        "domain": "'${sso_domain}'"
      }
    ],
    "vm_service_spec": {
      "vm_classes": '$(jq -r .tanzu_local.vm_classes $jsonFile)',
      "content_libraries": []
    },
    "storage_specs": [
      {
        "policy": "'${storage_policy_id}'"
      }
    ],
    "namespace": "'${ns_name}'"
  }'
  vcenter_api 6 10 "POST" $token "${json_data}" $api_host "api/vcenter/namespaces/instances"
done
#
# retrieve K8s Supervisor node IP
#
vcenter_api 6 10 "GET" $token '' $api_host "api/vcenter/namespace-management/clusters/${cluster_id}"
api_server_cluster_endpoint=$(echo $response_body | jq -c -r .api_server_cluster_endpoint)
json_data='
{
  "api_server_cluster_endpoint": "'${api_server_cluster_endpoint}'"
}'
echo $json_data | tee /root/api_server_cluster_endpoint.json