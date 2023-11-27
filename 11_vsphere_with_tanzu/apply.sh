#!/bin/bash
jsonFile="/root/vsphere_with_tanzu.json"
source /nestedVsphere8/bash/tf_init_apply.sh
source /nestedVsphere8/bash/vcenter_api.sh
source /nestedVsphere8/bash/ip.sh
source /nestedVsphere8/bash/nsx/nsx_api.sh
#
IFS=$'\n'
#
vcsa_fqdn="$(jq -r .vsphere_nested.vcsa_name $jsonFile).$(jq -r .external_gw.bind.domain $jsonFile)"
vcsa_sso_domain=$(jq -r .vsphere_nested.sso.domain_name $jsonFile)
external_gw_ip=$(jq -c -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile)
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
exit
#
# Create Content Library for tanzu
#
create_subscribed_content_library_json_output="/root/tanzu_content_library.json"
/bin/bash /nestedVsphere8/bash/vcenter/create_subscribed_content_library.sh \
  "${vcsa_fqdn}" \
  "${vcsa_sso_domain}" \
  "${TF_VAR_vsphere_nested_password}" \
  "$(jq -c -r .tanzu_local.content_library.subscription_url $jsonFile)" \
  "$(jq -c -r .tanzu_local.content_library.type $jsonFile)" \
  "$(jq -c -r .tanzu_local.content_library.automatic_sync_enabled $jsonFile)" \
  "$(jq -c -r .tanzu_local.content_library.on_demand $jsonFile)" \
  "$(jq -c -r .tanzu_local.content_library.name $jsonFile)" \
  "${create_subscribed_content_library_json_output}"
content_library_id=$(jq -c -r .content_library_id ${create_subscribed_content_library_json_output})
#
# Retrieve cluster id
#
retrieve_cluster_id_json_output="/root/vcenter_cluster_id.json"
/bin/bash /nestedVsphere8/bash/vcenter/retrieve_cluster_id.sh \
  "${vcsa_fqdn}" \
  "${vcsa_sso_domain}" \
  "${TF_VAR_vsphere_nested_password}" \
  "$(jq -c -r .vsphere_nested.cluster $jsonFile)" \
  "${retrieve_cluster_id_json_output}"
cluster_id=$(jq -c -r .cluster_id ${retrieve_cluster_id_json_output})
#
# Retrieve storage policy
#
retrieve_storage_policy_id_json_output="/root/retrieve_storage_policy_id.json"
/bin/bash /nestedVsphere8/bash/vcenter/retrieve_storage_policy_id.sh "${vcsa_fqdn}" "${vcsa_sso_domain}" "${TF_VAR_vsphere_nested_password}" \
  "$(jq -c -r .tanzu_local.storage_policy_name $jsonFile)" \
  "${retrieve_storage_policy_id_json_output}"
storage_policy_id=$(jq -c -r .storage_policy_id ${retrieve_storage_policy_id_json_output})
#
# Retrieve Network details of tanzu_supervisor_dvportgroup dvportgroup
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_tanzu_alb_wo_nsx" ]]; then
  supervisor_network="$(jq -c -r .networks.alb.tanzu.port_group_name $jsonFile)"
fi
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_tanzu_alb" ]]; then
  supervisor_network="$(jq -c -r .tanzu.supervisor_cluster.management_tanzu_segment $jsonFile)"
fi
#
retrieve_network_id_json_output="/root/retrieve_network_id.json"
/bin/bash /nestedVsphere8/bash/vcenter/retrieve_network_id.sh \
  "${vcsa_fqdn}" \
  "${vcsa_sso_domain}" \
  "${TF_VAR_vsphere_nested_password}" \
  "${supervisor_network}" \
  "${retrieve_network_id_json_output}"
tanzu_supervisor_dvportgroup=$(jq -c -r .network_id ${retrieve_network_id_json_output})
#
# Retrieve Network details of tanzu_worker_dvportgroup dvportgroup
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_tanzu_alb_wo_nsx" ]]; then
  retrieve_network_id_json_output="/root/retrieve_network_id.json"
  /bin/bash /nestedVsphere8/bash/vcenter/retrieve_network_id.sh \
    "${vcsa_fqdn}" \
    "${vcsa_sso_domain}" \
    "${TF_VAR_vsphere_nested_password}" \
    "$(jq -c -r .networks.alb.backend.port_group_name $jsonFile)" \
    "${retrieve_network_id_json_output}"
  tanzu_worker_dvportgroup=$(jq -c -r .network_id ${retrieve_network_id_json_output})
fi
#
# Retrieve Avi Details
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_tanzu_alb_wo_nsx" ]]; then
  echo "   +++ getting NSX ALB certificate..."
  openssl s_client -showcerts -connect $(jq -r .vsphere_underlay.networks.vsphere.management.avi_nested_ip $jsonFile):443  </dev/null 2>/dev/null|sed -ne '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' > /tmp/temp_avi-ca.cert
  if [ ! -s /tmp/temp_avi-ca.cert ] ; then exit 255 ; fi
  avi_cert=$(jq -sR . /tmp/temp_avi-ca.cert)
fi
#
# vsphere_tanzu_alb_wo_nsx use case
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_tanzu_alb_wo_nsx"  ]]; then
  /bin/bash /nestedVsphere8/bash/vcenter/create_supervisor_cluster_vds.sh "${vcsa_fqdn}" "${vcsa_sso_domain}" "${TF_VAR_vsphere_nested_password}" \
    "${external_gw_ip}" \
    "${storage_policy_id}" \
    "$(jq -r .tanzu.supervisor_cluster.service_cidr $jsonFile | cut -d"/" -f1)" \
    "$(jq -r .tanzu.supervisor_cluster.service_cidr $jsonFile | cut -d"/" -f2)" \
    "$(jq -r .tanzu.supervisor_cluster.size $jsonFile)" \
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
  #
  # retrieve edge cluster id
  #
  retrieve_network_id_json_output="/root/retrieve_namespace_edge_cluster_id.json"
  /bin/bash /nestedVsphere8/bash/nsx/get_edge_cluster.sh \
           "$(jq -r .vsphere_underlay.networks.vsphere.management.nsx_nested_ip $jsonFile)" \
           "${TF_VAR_nsx_password}" \
           "$(jq -r .tanzu.supervisor_cluster.namespace_edge_cluster $jsonFile)" \
           "${retrieve_network_id_json_output}"
  namespace_edge_cluster_id=$(jq -c -r .namespace_edge_cluster_id ${retrieve_network_id_json_output})
  #
  # create supervisor cluster
  #
  management_tanzu_segment=$(jq -r .tanzu.supervisor_cluster.management_tanzu_segment $jsonFile)
  management_tanzu_cidr=$(jq -c -r --arg segment ${management_tanzu_segment} '.nsx.config.segments_overlay[] | select(.display_name == $segment) | .cidr' $jsonFile)
  /bin/bash /nestedVsphere8/bash/vcenter/create_supervisor_cluster_nsx.sh "${vcsa_fqdn}" "${vcsa_sso_domain}" "${TF_VAR_vsphere_nested_password}" \
            "${content_library_id}" \
            "${storage_policy_id}" \
            "${external_gw_ip}" \
            "$(jq -r .tanzu.supervisor_cluster.size $jsonFile)" \
            "$(jq -r .tanzu.supervisor_cluster.service_cidr $jsonFile | cut -d"/" -f1)" \
            "$(jq -r .tanzu.supervisor_cluster.service_cidr $jsonFile | cut -d"/" -f2)" \
            "$(ip_netmask_by_prefix $(echo ${management_tanzu_cidr} | cut -d"/" -f2) "   ++++++")" \
            "$(jq -c -r --arg segment ${management_tanzu_segment} '.nsx.config.segments_overlay[] | select(.display_name == $segment) | .tanzu_supervisor_starting_ip' $jsonFile)" \
            "$(nextip $(echo ${management_tanzu_cidr} | cut -d"/" -f1 ))" \
            "$(jq -c -r --arg segment ${management_tanzu_segment} '.nsx.config.segments_overlay[] | select(.display_name == $segment) | .tanzu_supervisor_count' $jsonFile)" \
            "${tanzu_supervisor_dvportgroup}" \
            "$(jq -c -r .vds_network_nsx_overlay_id /root/vds_network_nsx_overlay_id.json)" \
            "$(jq -r .tanzu.supervisor_cluster.namespace_cidr $jsonFile | cut -d"/" -f1)" \
            "$(jq -r .tanzu.supervisor_cluster.namespace_cidr $jsonFile | cut -d"/" -f2)" \
            "$(jq -r .tanzu.supervisor_cluster.namespace_tier0 $jsonFile)" \
            "${namespace_edge_cluster_id}" \
            "$(jq -r .tanzu.supervisor_cluster.prefix_per_namespace $jsonFile)" \
            "$(jq -r .tanzu.supervisor_cluster.ingress_cidr $jsonFile | cut -d"/" -f1)" \
            "$(jq -r .tanzu.supervisor_cluster.ingress_cidr $jsonFile | cut -d"/" -f2)" \
            "${cluster_id}"
fi
#
# Wait for supervisor cluster to be running
#
/bin/bash /nestedVsphere8/bash/vcenter/retrieve_api_server_cluster_endpoint.sh "${vcsa_fqdn}" "${vcsa_sso_domain}" "${TF_VAR_vsphere_nested_password}"
#
# Namespace creation
#
for ns in $(jq -c -r .tanzu.namespaces[] $jsonFile); do
  /bin/bash /nestedVsphere8/bash/vcenter/create_namespaces.sh "${vcsa_fqdn}" "${vcsa_sso_domain}" "${TF_VAR_vsphere_nested_password}" \
            "$(jq -r .tanzu_local.vm_classes $jsonFile)" \
            "${storage_policy_id}" \
            "$(echo $ns | jq -c -r .name)"
done
#
# retrieve K8s Supervisor node IP
#
retrieve_api_server_cluster_endpoint_json_output="/root/retrieve_api_server_cluster_endpoint.json"
/bin/bash /nestedVsphere8/bash/vcenter/retrieve_api_server_cluster_endpoint.sh "${vcsa_fqdn}" "${vcsa_sso_domain}" "${TF_VAR_vsphere_nested_password}" \
          "${retrieve_api_server_cluster_endpoint_json_output}"
api_server_cluster_endpoint=$(jq -c -r .api_server_cluster_endpoint ${retrieve_api_server_cluster_endpoint_json_output})
#
# TKC creation
#
# templating vsphere plugin install
sed -e "s/\${api_server_cluster_endpoint}/${api_server_cluster_endpoint}/" templates/vsphere_plugin_install.sh.template | tee /root/vsphere_plugin_install.sh > /dev/null
# transfer vsphere plugin install
scp -o StrictHostKeyChecking=no /root/vsphere_plugin_install.sh ubuntu${external_gw_ip}:/home/ubuntu/tanzu/vsphere_plugin_install.sh
# exec vsphere plugin install
ssh -o StrictHostKeyChecking=no -t ubuntu@${external_gw_ip} "/bin/bash /home/ubuntu/tanzu/vsphere_plugin_install.sh"
# templating tanzu auth supervisor script
sed -e "s/\${kubectl_password}/${TF_VAR_vsphere_nested_password}/" \
    -e "s/\${sso_domain_name}/${vcsa_sso_domain}/" \
    -e "s/\${api_server_cluster_endpoint}/${api_server_cluster_endpoint}/" templates/tanzu_auth_supervisor.sh.template | tee /root/tanzu_auth_supervisor.sh > /dev/null
# transfer tanzu auth supervisor script
scp -o StrictHostKeyChecking=no /root/tanzu_auth_supervisor.sh ubuntu${external_gw_ip}:/home/ubuntu/tanzu/auth_supervisor.sh
#
#
cluster_count=1
remote_path="/home/ubuntu/tkc/create-tkc-"
remote_path_destroy="/home/ubuntu/tkc/destroy-tkc-"
remote_path_auth="/home/ubuntu/tkc/auth-tkc-"
for tkc in $(jq -c -r .tanzu.tkc_clusters[] $jsonFile); do
  # yaml templating
  sed -e "s/\${name}/$(echo $tkc | jq -c -r .name)/" \
      -e "s/\${namespace_ref}/$(echo $tkc | jq -c -r .namespace_ref)/" \
      -e "s/\${services_cidrs}/$(echo $tkc | jq -c -r .services_cidrs)/" \
      -e "s/\${pods_cidrs}/$(echo $tkc | jq -c -r .pods_cidrs)/" \
      -e "s/\${serviceDomain}/$(jq -r .external_gw.bind.domain $jsonFile)/" \
      -e "s/\${k8s_version}/$(echo $tkc | jq -c -r .k8s_version)/" \
      -e "s/\${control_plane_count}/$(echo $tkc | jq -c -r .control_plane_count)/" \
      -e "s/\${cluster_count}/${cluster_count}/" \
      -e "s/\${workers_count}/$(echo $tkc | jq -c -r .workers_count)/" \
      -e "s/\${vm_class}/$(echo $tkc | jq -c -r .vm_class)/" templates/tkc.yml.template | tee /root/tkc-${cluster_count}.yml > /dev/null
  # yaml transfer
  scp -o StrictHostKeyChecking=no /root/tkc-${cluster_count}.yml ubuntu${external_gw_ip}:${remote_path}-${cluster_count}.sh
  # bash create templating
  sed -e "s/\${kubectl_password}/${TF_VAR_vsphere_nested_password}/" \
      -e "s/\${sso_domain_name}/${vcsa_sso_domain}/" \
      -e "s/\${api_server_cluster_endpoint}/${api_server_cluster_endpoint}/" \
      -e "s/\${namespace_ref}/$(echo $tkc | jq -c -r .namespace_ref)/" \
      -e "s/\${remote_path}/${remote_path}/" \
      -e "s/\${cluster_count}/${cluster_count}/" templates/tkc.sh.template | tee /root/create-tkc-${cluster_count}.sh > /dev/null
  # bash create transfer
  scp -o StrictHostKeyChecking=no /root/create-tkc-${cluster_count}.sh ubuntu@${external_gw_ip}:${remote_path}-${cluster_count}.sh
  # bash destroy templating
  sed -e "s/\${kubectl_password}/${TF_VAR_vsphere_nested_password}/" \
      -e "s/\${sso_domain_name}/${vcsa_sso_domain}/" \
      -e "s/\${api_server_cluster_endpoint}/${api_server_cluster_endpoint}/" \
      -e "s/\${namespace_ref}/$(echo $tkc | jq -c -r .namespace_ref)/" \
      -e -e "s/\${name}/$(echo $tkc | jq -c -r .name)/" templates/tkc_destroy.sh.template | tee /root/destroy-tkc-${cluster_count}.sh > /dev/null
  # bash destroy transfer
  scp -o StrictHostKeyChecking=no /root/destroy-tkc-${cluster_count}.sh ubuntu@${external_gw_ip}:${remote_path_destroy}-${cluster_count}.sh
  # bash auth tkc templating
  sed -e "s/\${kubectl_password}/${TF_VAR_vsphere_nested_password}/" \
      -e "s/\${sso_domain_name}/${vcsa_sso_domain}/" \
      -e "s/\${api_server_cluster_endpoint}/${api_server_cluster_endpoint}/" \
      -e "s/\${namespace_ref}/$(echo $tkc | jq -c -r .namespace_ref)/" \
      -e -e "s/\${name}/$(echo $tkc | jq -c -r .name)/" templates/tanzu_auth_tkc.sh.template | tee /root/tanzu_auth_tkc-${cluster_count}.sh > /dev/null
  # bash auth tkc transfer
  scp -o StrictHostKeyChecking=no /root/tanzu_auth_tkc-${cluster_count}.sh ubuntu@${external_gw_ip}:${remote_path_auth}-${cluster_count}.sh
  # bash create exec
  ssh -o StrictHostKeyChecking=no -t ubuntu@${external_gw_ip} "/bin/bash ${remote_path}-${cluster_count}.sh"
  ((cluster_count++))
done
tf_init_apply "Configuration of Vsphere with Tanzu - This should take less than 60 minutes" /nestedVsphere8/11_vsphere_with_tanzu /nestedVsphere8/log/11.stdout /nestedVsphere8/log/11.stderr $jsonFile