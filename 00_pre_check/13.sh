#!/bin/bash
#
source /nestedVsphere8/bash/download_file.sh
#
jsonFile="/root/variables.json"
localJsonFile="/nestedVsphere8/13_tkgm/variables.json"
#
rm -f /root/tkgm.json
tkgm_json=$(jq -c -r . $jsonFile | jq .)
deployment=$(jq -c -r .deployment $jsonFile)
if [[ ${deployment} == "vsphere_nsx_alb_telco" ]]; then
  echo ""
  echo "==> Creating /root/tkgm.json file..."
  #
  IFS=$'\n'
  #
  echo "   +++ Adding avi_username on tkg.clusters.management"
  tkgm_json=$(echo $tkgm_json | jq '.tkg.clusters.management += {"avi_username": "'$(jq -r .tkgm_user /nestedVsphere8/07_nsx_alb/variables.json)'"}')
  #
  echo "   +++ Adding avi_cloud_name on tkg.clusters.management"
  tkgm_json=$(echo $tkgm_json | jq '.tkg.clusters.management += {"avi_cloud_name": "'$(jq -c -r '.vcenter_default_cloud_name' /nestedVsphere8/07_nsx_alb/variables.json)'"}')
  #
  if $(jq -e '.tkg.clusters.management | has("cluster_ref")' $jsonFile) ; then
    echo "   +++ TKG will be installed on the top of cluster $(jq -c -r '.tkg.clusters.management.cluster_ref' $jsonFile)"
    vsan_datastore_index=$(jq -c -r --arg arg "$(jq -c -r '.tkg.clusters.management.cluster_ref' $jsonFile)" '.vsphere_nested.cluster_list | map( . == $arg ) | index(true)' $jsonFile)
    tkgm_json=$(echo $tkgm_json | jq '.tkg.clusters.management += {"datastore_ref": "'$(jq -c -r '.vsphere_nested.datastore_list['${vsan_datastore_index}']' $jsonFile)'"}')
  else
    echo "   +++ Adding .tkg.clusters.management.cluster_ref..."
    tkgm_json=$(echo $tkgm_json | jq '.tkg.clusters.management += {"cluster_ref": "'$(jq -c -r '.vsphere_nested.cluster_list[0]' $jsonFile)'"}')
    tkgm_json=$(echo $tkgm_json | jq '.tkg.clusters.management += {"datastore_ref": "'$(jq -c -r '.vsphere_nested.datastore_list[0]' $jsonFile)'"}')
  fi
  #
  echo "   +++ Adding avi_domain_prefix..."
  avi_domain_prefix=$(jq -c -r '.avi_domain_prefix' /nestedVsphere8/07_nsx_alb/variables.json)
  tkgm_json=$(echo $tkgm_json | jq '. += {"avi_domain_prefix": "'$(echo $avi_domain_prefix)'"}')
  #
  echo "   +++ Adding public_key_path on tkg.clusters.management"
  tkgm_json=$(echo $tkgm_json | jq '.tkg.clusters += {"public_key_path": "/root/.ssh/id_rsa_external.pub"}')
  #
  echo "   +++ Adding private_key_path on tkg.clusters.management"
  tkgm_json=$(echo $tkgm_json | jq '.tkg.clusters += {"private_key_path": "/root/.ssh/id_rsa_external"}')
  #
  echo "   +++ Adding ova_folder_template on tkg"
  tkgm_json=$(echo $tkgm_json | jq '.tkg += {"ova_folder_template": "'$(jq -c -r '.ova_folder_template' $localJsonFile)'"}')
  #
  echo "   +++ Adding ova_network on tkg"
  tkgm_json=$(echo $tkgm_json | jq '.tkg += {"ova_network": "'$(jq -c -r '.nsx.config.segments_overlay[0].display_name' $jsonFile)'"}')
  #
  workload_clusters_list="[]"
  for cluster in $(jq -c -r .tkg.clusters.workloads[] $jsonFile)
  do
    echo "   +++ add ssh_username in workload cluster called $(echo $cluster | jq -c -r .name)"
    cluster=$(echo $cluster | jq '. += {"ssh_username": "capv"}')
    echo "   +++ add ako_tenant_ref in workload cluster called $(echo $cluster | jq -c -r .name)"
    cluster=$(echo $cluster | jq '. += {"ako_tenant_ref": "'$(echo $cluster | jq -c -r .name)'"}')
    echo "   +++ add ako_service_engine_group_ref in workload cluster called $(echo $cluster | jq -c -r .name)"
    cluster=$(echo $cluster | jq '. += {"ako_service_engine_group_ref": "'$(echo $cluster | jq -c -r .name)'"}')
    if $(echo $cluster | jq -e '. | has("cluster_ref")') ; then
      echo "   +++ TKG Workload will be installed on the top of cluster $(echo $cluster | jq -c -r '.cluster_ref')"
    vsan_datastore_index=$(jq -c -r --arg arg "$(echo $cluster | jq -c -r '.cluster_ref')" '.vsphere_nested.cluster_list | map( . == $arg ) | index(true)' $jsonFile)
    cluster=$(echo $cluster | jq '. += {"datastore_ref": "'$(jq -c -r '.vsphere_nested.datastore_list['${vsan_datastore_index}']' $jsonFile)'"}')
    else
      echo "   +++ add cluster_ref in workload cluster called $(echo $cluster | jq -c -r .name)"
      cluster=$(echo $cluster | jq '. += {"cluster_ref": "'$(jq -c -r '.vsphere_nested.cluster_list[0]' $jsonFile)'"}')
      cluster=$(echo $cluster | jq '. += {"datastore_ref": "'$(jq -c -r '.vsphere_nested.datastore_list[0]' $jsonFile)'"}')
    fi
    workload_clusters_list=$(echo $workload_clusters_list | jq '. += ['$(echo $cluster | jq -c -r .)']')
  done
  tkgm_json=$(echo $tkgm_json | jq '. | del (.tkg.clusters.workloads)')
  tkgm_json=$(echo $tkgm_json | jq '.tkg.clusters += {"workloads": '$(echo $workload_clusters_list)'}')
  #
  # .avi.config.ako.vip_network_name_ref
  #
  echo "   +++ Adding vip_network_name_ref on .avi.config.ako"
  vip_network_name_ref=$(jq -r .networks.nsx.nsx_external.port_group_name /nestedVsphere8/02_external_gateway/variables.json)
  tkgm_json=$(echo $tkgm_json | jq '.avi.config.ako += {"vip_network_name_ref": "'${vip_network_name_ref}'"}')
  #
  # .avi.config.ako.vip_network_cidr
  #
  echo "   +++ Adding vip_network_cidr on .avi.config.ako"
  vip_network_cidr=$(jq -r --arg network_name "${vip_network_name_ref}" '.avi.config.cloud.additional_subnets[] | select(.name_ref == $network_name).subnets[0].cidr' $jsonFile)
  tkgm_json=$(echo $tkgm_json | jq '.avi.config.ako += {"vip_network_cidr": "'${vip_network_cidr}'"}')
  #
  # .avi.config.ako.service_type
  #
  echo "   +++ Adding service_type on .avi.config.ako"
  service_type=$(jq -c -r .ako_service_type /nestedVsphere8/07_nsx_alb/variables.json)
  tkgm_json=$(echo $tkgm_json | jq '.avi.config.ako += {"service_type": "'${service_type}'"}')
  #
  # .avi.config.ako.cloud_name
  #
  echo "   +++ Adding service_type on .avi.config.ako"
  cloud_name=$(jq -c -r .vcenter_default_cloud_name /nestedVsphere8/07_nsx_alb/variables.json)
  tkgm_json=$(echo $tkgm_json | jq '.avi.config.ako += {"cloud_name": "'${cloud_name}'"}')
  #
  local_file="/root/$(basename $(jq -c -r .tkg.tanzu_bin_location $jsonFile))"
  download_file_from_url_to_location "$(jq -c -r .tkg.tanzu_bin_location $jsonFile)" "${local_file}" "TKGm bin cli"
  #
  local_file="/root/$(basename $(jq -c -r .tkg.k8s_bin_location $jsonFile))"
  download_file_from_url_to_location "$(jq -c -r .tkg.k8s_bin_location $jsonFile)" "${local_file}" "TKGm kubectl bin"
  #
  local_file="/root/$(basename $(jq -c -r .tkg.ova_location $jsonFile))"
  download_file_from_url_to_location "$(jq -c -r .tkg.ova_location $jsonFile)" "${local_file}" "TKGm ova"
fi
echo $tkgm_json | jq . | tee /root/tkgm.json > /dev/null