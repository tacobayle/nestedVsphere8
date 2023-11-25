#!/bin/bash
jsonFile="/root/vsphere_with_tanzu.json"
source /nestedVsphere8/bash/tf_init_apply.sh
source /nestedVsphere8/bash/vcenter_api.sh
source /nestedVsphere8/bash/ip.sh
#
IFS=$'\n'
#
# registering Avi in the NSX config
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_tanzu_alb" ]]; then
  /bin/bash /nestedVsphere8/bash/nsx/registering_avi_controller.sh \
    "$(jq -r .vsphere_underlay.networks.vsphere.management.nsx_nested_ip $jsonFile)" \
    "${TF_VAR_nsx_password}" \
    "${TF_VAR_avi_password}" \
    "$(jq -c -r .vsphere_underlay.networks.vsphere.management.avi_nested_ip $jsonFile)"
fi
#
# Create Content Library for tanzu
#
create_subscribed_content_library_json_output="/root/tanzu_content_library.json"
/bin/bash /nestedVsphere8/bash/vcenter/create_subscribed_content_library.sh \
  "$(jq -r .vsphere_nested.vcsa_name $jsonFile).$(jq -r .external_gw.bind.domain $jsonFile)" \
  "$(jq -r .vsphere_nested.sso.domain_name $jsonFile)" \
  "${TF_VAR_vsphere_nested_password}" \
  "$(jq -c -r .tanzu_local.content_library.subscription_url $jsonFile)" \
  "$(jq .tanzu_local.content_library.type $jsonFile)" \
  "$(jq .tanzu_local.content_library.automatic_sync_enabled $jsonFile)" \
  "$(jq .tanzu_local.content_library.on_demand $jsonFile)" \
  "$(jq .tanzu_local.content_library.name $jsonFile)" \
  "${create_subscribed_content_library_json_output}"
content_library_id=$(jq -c -r .content_library_id ${create_subscribed_content_library_json_output})
#
# Retrieve cluster id
#
retrieve_cluster_id_json_output="/root/vcenter_cluster_id.json"
/bin/bash /nestedVsphere8/bash/vcenter/retrieve_cluster_id.sh \
  "$(jq -r .vsphere_nested.vcsa_name $jsonFile).$(jq -r .external_gw.bind.domain $jsonFile)" \
  "$(jq -r .vsphere_nested.sso.domain_name $jsonFile)" \
  "${TF_VAR_vsphere_nested_password}" \
  "$(jq -c -r .vsphere_nested.cluster $jsonFile)" \
  "${retrieve_cluster_id_json_output}"
cluster_id=$(jq -c -r .cluster_id ${retrieve_cluster_id_json_output})
#
# Retrieve storage policy
#
retrieve_storage_policy_id_json_output="/root/retrieve_storage_policy_id.json"
/bin/bash /nestedVsphere8/bash/vcenter/retrieve_storage_policy_id.sh \
  "$(jq -r .vsphere_nested.vcsa_name $jsonFile).$(jq -r .external_gw.bind.domain $jsonFile)" \
  "$(jq -r .vsphere_nested.sso.domain_name $jsonFile)" \
  "${TF_VAR_vsphere_nested_password}" \
  "$(jq -c -r .tanzu_local.storage_policy_name $jsonFile)" \
  "${retrieve_storage_policy_id_json_output}"
storage_policy_id=$(jq -c -r .storage_policy_id ${retrieve_storage_policy_id_json_output})
#
# DNS NTP
#
external_gw_ip=$(jq -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile)
#
# Retrieve Network details of tanzu_supervisor_dvportgroup dvportgroup
#
retrieve_network_id_json_output="/root/retrieve_network_id.json"
/bin/bash /nestedVsphere8/bash/vcenter/retrieve_network_id.sh \
  "$(jq -r .vsphere_nested.vcsa_name $jsonFile).$(jq -r .external_gw.bind.domain $jsonFile)" \
  "$(jq -r .vsphere_nested.sso.domain_name $jsonFile)" \
  "${TF_VAR_vsphere_nested_password}" \
  "$(jq -c -r .networks.alb.tanzu.port_group_name $jsonFile)" \
  "${retrieve_network_id_json_output}"
tanzu_supervisor_dvportgroup=$(jq -c -r .network_id ${retrieve_network_id_json_output})
#
# Retrieve Network details of tanzu_worker_dvportgroup dvportgroup
#
retrieve_network_id_json_output="/root/retrieve_network_id.json"
/bin/bash /nestedVsphere8/bash/vcenter/retrieve_network_id.sh \
  "$(jq -r .vsphere_nested.vcsa_name $jsonFile).$(jq -r .external_gw.bind.domain $jsonFile)" \
  "$(jq -r .vsphere_nested.sso.domain_name $jsonFile)" \
  "${TF_VAR_vsphere_nested_password}" \
  "$(jq -c -r .networks.alb.backend.port_group_name $jsonFile)" \
  "${retrieve_network_id_json_output}"
tanzu_worker_dvportgroup=$(jq -c -r .network_id ${retrieve_network_id_json_output})
#
# Retrieve Avi Details
#
echo "   +++ getting NSX ALB certificate..."
openssl s_client -showcerts -connect $(jq -r .vsphere_underlay.networks.vsphere.management.avi_nested_ip $jsonFile):443  </dev/null 2>/dev/null|sed -ne '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' > /tmp/temp_avi-ca.cert
if [ ! -s /tmp/temp_avi-ca.cert ] ; then exit 255 ; fi
avi_cert=$(jq -sR . /tmp/temp_avi-ca.cert)
#
# vsphere_tanzu_alb_wo_nsx use case
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_tanzu_alb_wo_nsx"  ]]; then
  /bin/bash /nestedVsphere8/bash/vcenter/create_supervisor_vds_avi.sh \
    "$(jq -r .vsphere_nested.vcsa_name $jsonFile).$(jq -r .external_gw.bind.domain $jsonFile)" \
    "$(jq -r .vsphere_nested.sso.domain_name $jsonFile)" \
    "${TF_VAR_vsphere_nested_password}" \
    "${external_gw_ip}" \
    "${storage_policy_id}" \
    "$(jq -r .tanzu.supervisor_cluster.service_cidr $jsonFile | cut -d"/" -f1)" \
    "$(jq -r .tanzu.supervisor_cluster.service_cidr $jsonFile | cut -d"/" -f2)" \
    "$(jq -r .tanzu.supervisor_cluster.size $jsonFile)" \
    "${external_gw_ip}" \
    "$(ip_netmask_by_prefix $(jq -c -r '.vsphere_underlay.networks.alb.tanzu.cidr' $jsonFile| cut -d"/" -f2) "   ++++++")" \
    "$(jq -r .vsphere_underlay.networks.alb.tanzu.tanzu_supervisor_starting_ip $jsonFile)" \
    "$(jq -r .vsphere_underlay.networks.alb.tanzu.external_gw_ip $jsonFile)" \
    "$(jq -r .vsphere_underlay.networks.alb.tanzu.tanzu_supervisor_count $jsonFile)" \
    "${tanzu_supervisor_dvportgroup}" \
    "${avi_cert}" \
    "${TF_VAR_avi_password}" \
    "$(jq -r .vsphere_underlay.networks.vsphere.management.avi_nested_ip $jsonFile)" \
    "${content_library_id}" \
    "$(jq -r .networks.alb.backend.port_group_name $jsonFile)" \
    "$(jq -r .vsphere_underlay.networks.alb.backend.tanzu_workers_starting_ip $jsonFile)" \
    "$(jq -r .vsphere_underlay.networks.alb.backend.tanzu_workers_count $jsonFile)" \
    "$(jq -r .vsphere_underlay.networks.alb.backend.external_gw_ip $jsonFile)" \
    "${tanzu_worker_dvportgroup}" \
    "$(ip_netmask_by_prefix $(jq -c -r '.vsphere_underlay.networks.alb.backend.cidr' $jsonFile| cut -d"/" -f2) "   ++++++")'" \
    "${cluster_id}"
fi
#
# vsphere_tanzu_alb_nsx use case
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_tanzu_alb"  ]]; then
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
fi
vcenter_api 6 10 "POST" $token "${json_data}" $api_host "api/vcenter/namespace-management/clusters/${cluster_id}?action=enable"
#
# Wait for supervisor cluster to be running
#
/bin/bash /nestedVsphere8/bash/vcenter/wait_for_supervisor_cluster.sh \
          "$(jq -r .vsphere_nested.vcsa_name $jsonFile).$(jq -r .external_gw.bind.domain $jsonFile)" \
          "$(jq -r .vsphere_nested.sso.domain_name $jsonFile)" \
          "${TF_VAR_vsphere_nested_password}"
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
#
#
#
tf_init_apply "Configuration of Vsphere with Tanzu - This should take less than 60 minutes" /nestedVsphere8/11_vsphere_with_tanzu /nestedVsphere8/log/11.stdout /nestedVsphere8/log/11.stderr $jsonFile