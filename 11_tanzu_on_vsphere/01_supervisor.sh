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
json_data='{"storage_backings":[{"datastore_id":"'${datastore_id}'","type":"DATASTORE"}],"type": '$(jq .tanzu_local.content_library.subscription_url $jsonFile)',"version":"2","subscription_info":{"authentication_method":"NONE","ssl_thumbprint":"'${ValidCmThumbPrint}'","automatic_sync_enabled": '$(jq .tanzu_local.content_library.automatic_sync_enabled $jsonFile)',"subscription_url": '$(jq .tanzu_local.content_library.subscription_url $jsonFile)',"on_demand": '$(jq .tanzu_local.content_library.on_demand $jsonFile)'},"name": '$(jq .tanzu_local.content_library.name $jsonFile)'}'
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
tanzu_supervisor_netmask=$(jq -r .vsphere_underlay.networks.alb.tanzu.netmask $jsonFile)
tanzu_supervisor_gw=$(jq -r .vsphere_underlay.networks.alb.tanzu.external_gw_ip $jsonFile)
tanzu_worker_netmask=$(jq -r .vsphere_underlay.networks.alb.backend.netmask $jsonFile)
tanzu_worker_gw=$(jq -r .vsphere_underlay.networks.alb.backend.external_gw_ip $jsonFile)
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
    "address":"10.96.0.0",
    "prefix":23
  },
  "size_hint":"SMALL",
  "worker_DNS":["'${external_gw_ip}'"],
  "master_DNS":["'${external_gw_ip}'"],
  "network_provider":"'${network_provider}'",
  "master_storage_policy":"'${storage_policy_id}'",
  "master_management_network":
  {
    "mode":"STATICRANGE","address_range":
  {
    "subnet_mask":"'${tanzu_supervisor_netmask}'",
    "starting_address":"10.0.120.21",
    "gateway":"'${tanzu_supervisor_gw}'",
    "address_count":5
  },
    "network":"'${tanzu_supervisor_dvportgroup}'"
  },
  "load_balancer_config_spec": {
    "address_ranges": [],
    "avi_config_create_spec": {
      "certificate_authority_chain": "-----BEGIN CERTIFICATE-----\nMIIC0zCCAbugAwIBAgIUGy2UCuFMxDHIBm3LUqP2uKR9fqYwDQYJKoZIhvcNAQEL\nBQAwGTEXMBUGA1UEAwwOYWxiLmFsYjEyMy5jb20wHhcNMjMwODAzMTE0MDM5WhcN\nMjQwODAyMTE0MDM5WjAZMRcwFQYDVQQDDA5hbGIuYWxiMTIzLmNvbTCCASIwDQYJ\nKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMsSqEFCyEvu5IyU/v3+EjH27Onuc92L\n+c1/dBobRo/Hw5acvH/HOaPLSdsvr7qGX2k6Ep6v0DIyGby6TgwAXUNbPSR63g5U\nqH19YHr14nyk0cXEV8xdrvV3c8um1X2o0U7RB8PEf5eckFjqYiZHtH+4HPR4E7s5\nj2VHeDtzBddZ6x2ppK18A+N7IjVnYLgzS78xa0Pv75I4yr89QB1I7ehUSoGzoPMt\nxn6Lu7Lwz1OUF8uQYOQirOXU4uBTQLxosBhzgUlRD8MFoBvW+qTyo1RBHIhJAxVs\nHR3O6snjUk/nUOHkHPR6JIRDXVSrW6txUmNLFTkXKICrk4iKsOdwLj0CAwEAAaMT\nMBEwDwYDVR0RBAgwBocECimG1zANBgkqhkiG9w0BAQsFAAOCAQEABeBdK5h/MgxY\nIbawz4Lt4OSxcamxMNKeRYOKMQN8RgEyGTL0TRZC3wMntVDxpoXE1vlOxYJcmTMW\nvvdHb8ulHQY3Vx7OXzisK7hJ5l0ycJyJlvPvyIR3aYKON0BqBxdoWCPvUrfybj79\n0gJBbkX6TBMB3+CuFj+Re+KdOHxiFvkZn6COejg+ozgrlIb+zg/TSscibPvhUo9j\nLB5ohLrFmpmnOsWP8JNX+5kcSj8uGSeLcLlneDjN9++cuyWrqoAExXj/YXkdfh5i\nIh+40XKEUTOrkFKDZslCRMBsuu+EshM2guhDMgbKq/1VDsOdJimYWSI/G64Nq3bj\nGBujokotZQ==\n-----END CERTIFICATE-----",
      "password": "'${avi_password}'",
      "server": {
        "host": "10.41.134.215",
        "port": 443
      },
      "username": "admin"
    },
    "id": "avi",
    "provider": "AVI"
  },
  "Master_DNS_names":["tanzu.alb123.com"],
  "default_kubernetes_service_content_library":"42bf330d-26d7-4ead-994a-0997251e0d8e",
  "workload_networks_spec": {
    "supervisor_primary_workload_network": {
      "network": "backend-pg",
      "network_provider": "VSPHERE_NETWORK",
      "vsphere_network": {
        "address_ranges": [
          {
            "address": "10.0.118.51",
            "count": 19
          }
        ],
        "gateway": "'${tanzu_worker_gw}'",
        "ip_assignment_mode": "STATICRANGE",
        "portgroup": "'${tanzu_worker_dvportgroup}'",
        "subnet_mask": "'${tanzu_worker_netmask}'"
      }
    }
  }
}
'


#vcenter_api 6 10 "GET" $token "" $api_host "rest/com/vmware/content/subscribed-library"
#
# example of a get subscribed content library
# {"value":{"creation_time":"2023-01-04T12:57:42.124Z","storage_backings":[{"datastore_id":"datastore-14","type":"DATASTORE"}],"last_modified_time":"2023-01-04T12:57:42.124Z","server_guid":"2ad54d17-2b8a-4aa1-8f69-a9e0c5ac6d26","description":"","security_policy_id":"f24c4762-a8ed-8fe3-b3a1-33972ec8df04","type":"SUBSCRIBED","version":"2","subscription_info":{"authentication_method":"NONE","ssl_thumbprint":"b2:52:9e:4d:57:9f:ea:53:4d:a0:0b:7f:d4:7e:55:91:56:c0:64:bb","automatic_sync_enabled":true,"subscription_url":"https://wp-content.vmware.com/v2/latest/lib.json","on_demand":false},"name":"test","id":"21f89e44-9a90-47ad-b1d0-6f21d0bf036a"}}
#
#
#
#
#vcenter_api 6 10 "GET" $token '' $api_host "api/vcenter/namespace-management/clusters"
#cluster_id=$(echo $response_body | jq -c -r .[0].cluster)
retry=61
pause=60
attempt=1
while true ; do
  echo "attempt $attempt to get supervisor cluster config_status RUNNING"
  vcenter_api 6 10 "GET" $token '' $api_host "api/vcenter/namespace-management/clusters"
  if [[ $(echo $response_body | jq -c -r .[0].config_status) == "RUNNING" ]]; then
    echo "supervisor cluster is $(echo $response_body | jq -c -r .[0].config_status) after $attempt attempts"
    break 2
  fi
  ((attempt++))
  if [ $attempt -eq $retry ]; then
    echo "Unable to get supervisor cluster config_status RUNNING after $attempt"
    exit 255
  fi
  sleep $pause
done
#
#
#
#for ns in $(jq -c -r .tanzu.namespaces[] $jsonFile); do
#  vcenter_api 6 10 "GET" $token '' $api_host "api/vcenter/namespace-management/clusters"
#  clusters=$(echo $response_body)
#  for cluster in $(echo $clusters | jq -c -r .[]); do
#    if [[ $(echo $ns | jq -c -r .cluster_ref) == $(echo $cluster | jq -c -r .cluster_name) ]]; then
#      cluster_id=$(echo $cluster | jq -c -r .cluster)
#    else
#      echo $ns
#      echo "Unable to get cluster_id for cluster called $(echo $ns | jq -c -r .cluster_ref)"
#      exit 255
#    fi
#  done
#  echo '{"cluster": '\"$(echo $cluster_id)\"', "namespace": '$(echo $ns | jq .name)'}'
#  vcenter_api 6 10 "POST" $token '{"cluster": '\"$(echo $cluster_id)\"', "namespace": '$(echo $ns | jq .name)'}' $api_host "api/vcenter/namespaces/instances"
#done
