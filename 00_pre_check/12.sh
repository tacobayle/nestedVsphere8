#!/bin/bash
#
source /nestedVsphere8/bash/download_file.sh
#
jsonFile="/root/variables.json"
localJsonFile="/nestedVsphere8/12_tkgm/variables.json"
#
echo ""
echo "==> Creating /root/tkgm.json file..."
rm -f /root/tkgm.json
tkgm_json=$(jq -c -r . $jsonFile | jq .)
#
IFS=$'\n'
#
echo "   +++ Adding avi_username on tkg.clusters.management"
tkgm_json=$(echo $tkgm_json | jq '.tkg.clusters.management += {"avi_username": "'$(jq -r .tkgm_user /nestedVsphere8/07_nsx_alb/variables.json)'"}')
#
echo "   +++ Adding avi_cloud_name on tkg.clusters.management"
tkgm_json=$(echo $tkgm_json | jq '.tkg.clusters.management += {"avi_cloud_name": "'$(jq -c -r '.vcenter_default_cloud_name' /nestedVsphere8/07_nsx_alb/variables.json)'"}')
#
echo "   +++ Adding public_key_path on tkg.clusters.management"
tkgm_json=$(echo $tkgm_json | jq '.tkg.clusters += {"public_key_path": "/root/.ssh/id_rsa.pub"}')
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
  echo "   +++ add ako_tenant_ref in workload cluster called $(echo $cluster | jq -c -r .name)"
  cluster=$(echo $cluster | jq '. += {"ako_tenant_ref": "'$(echo $cluster | jq -c -r .name)'"}')
  echo "   +++ add ako_service_engine_group_ref in workload cluster called $(echo $cluster | jq -c -r .name)"
  cluster=$(echo $cluster | jq '. += {"ako_service_engine_group_ref": "'$(echo $cluster | jq -c -r .name)'"}')
  workload_clusters_list=$(echo $workload_clusters_list | jq '. += ['$(echo $cluster | jq -c -r .)']')
done
tkgm_json=$(echo $tkgm_json | jq '. | del (.tkg.clusters.workloads)')
tkgm_json=$(echo $tkgm_json | jq '.tkg.clusters += {"workloads": '$(echo $workload_clusters_list)'}')
#
echo $tkgm_json | jq . | tee /root/tkgm.json > /dev/null
#
local_file="/root/$(basename $(jq -c -r .tkg.tanzu_bin_location $jsonFile))"
download_file_from_url_to_location "$(jq -c -r .tkg.tanzu_bin_location $jsonFile)" "${local_file}" "TKGm bin cli"
#
local_file="/root/$(basename $(jq -c -r .tkg.k8s_bin_location $jsonFile))"
download_file_from_url_to_location "$(jq -c -r .tkg.k8s_bin_location $jsonFile)" "${local_file}" "TKGm kubectl bin"
#
local_file="/root/$(basename $(jq -c -r .tkg.ova_location $jsonFile))"
download_file_from_url_to_location "$(jq -c -r .tkg.ova_location $jsonFile)" "${local_file}" "TKGm ova"
