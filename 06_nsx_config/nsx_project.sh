#!/bin/bash
jsonFile="/root/nsx.json"
source /nestedVsphere8/bash/nsx/nsx_api.sh
#
IFS=$'\n'
#
nsx_manager=$(jq -r .vsphere_underlay.networks.vsphere.management.nsx_nested_ip $jsonFile)
nsx_password=${TF_VAR_nsx_password}
#
# Project creation
#
if $(jq -e '.nsx.config | has("projects")' $jsonFile) ; then
  for project in $(jq -c -r .nsx.config.projects[] $jsonFile); do
    project_mame=$(echo ${project} | jq -c -r .name)
    tier0_ref=$(echo ${project} | jq -c -r .tier0_ref)
    edge_cluster_ref=$(echo ${project} | jq -c -r .edge_cluster_ref)
    # retrieve tier0_path
    file_path_json_output="/tmp/nsx_project_tier0_path.json"
    json_key="t0_path"
    /bin/bash /nestedVsphere8/bash/nsx/retrieve_t0_id.sh \
      "${nsx_manager}" \
      "${nsx_password}" \
      "${tier0_ref}" \
      "${file_path_json_output}" \
      "${json_key}"
    tier0_path=$(jq -c -r ''.${json_key}'' ${file_path_json_output})
    # retrieve edge_cluster_path
    file_path_json_output="/tmp/nsx_project_edge_cluster_path.json"
    json_key="edge_cluster_path"
    /bin/bash /nestedVsphere8/bash/nsx/retrieve_edge_cluster_path.sh \
          "${nsx_manager}" \
          "${nsx_password}" \
          "${edge_cluster_ref}" \
          "${file_path_json_output}" \
          "${json_key}"
    edge_cluster_path=$(jq -c -r ''.${json_key}'' ${file_path_json_output})
    # create project
    /bin/bash /nestedVsphere8/bash/nsx/create_project.sh "${nsx_manager}" "${nsx_password}" "${project_mame}" "${edge_cluster_path}" "${tier0_path}"
  done
fi