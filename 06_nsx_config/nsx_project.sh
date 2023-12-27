#!/bin/bash
jsonFile="/root/nsx.json"
source /nestedVsphere8/bash/nsx/nsx_api.sh
#
IFS=$'\n'
#
nsx_manager=$(jq -r .vsphere_underlay.networks.vsphere.management.nsx_nested_ip $jsonFile)
nsx_password=${TF_VAR_nsx_password}
#
# ip block creation for project default
#
if $(jq -e '.nsx.config | has("ip_blocks")' $jsonFile) ; then
  for ip_block in $(jq -c -r .nsx.config.ip_blocks[] $jsonFile); do
    ip_block_project=""
    if $(echo ${ip_block} | jq -e '. | has("project_ref")') ; then
      if [[ $(echo ${ip_block} | jq -c -r '.project_ref') == "default" ]] ; then
        ip_block_project="default"
      fi
    else
      ip_block_project="default"
    fi
    if [[ ${ip_block_project} == "default" ]] ; then
      ip_block_name=$(echo ${ip_block} | jq -c -r .name)
      ip_block_cidr=$(echo ${ip_block} | jq -c -r .cidr)
      ip_block_visibility=$(echo ${ip_block} | jq -c -r .visibility)
      /bin/bash /nestedVsphere8/bash/nsx/create_ip_block.sh \
        "${nsx_manager}" \
        "${nsx_password}" \
        "${ip_block_name}" \
        "${ip_block_project}" \
        "${ip_block_cidr}" \
        "${ip_block_visibility}"
    fi
  done
fi
#
# Project creation
#
if $(jq -e '.nsx.config | has("projects")' $jsonFile) ; then
  for project in $(jq -c -r .nsx.config.projects[] $jsonFile); do
    project_mame=$(echo ${project} | jq -c -r .name)
    ip_block_ref=$(echo ${project} | jq -c -r .ip_block_ref)
    tier0_ref=$(echo ${project} | jq -c -r .tier0_ref)
    edge_cluster_ref=$(echo ${project} | jq -c -r .edge_cluster_ref)
    # retrieve ip_block_path
    file_path_json_output="/tmp/nsx_project_ip_block_path.json"
    json_key="ip_block_path"
    /bin/bash /nestedVsphere8/bash/nsx/retrieve_object_path.sh \
      "${nsx_manager}" \
      "${nsx_password}" \
      "policy/api/v1/infra/ip-blocks" \
      "${ip_block_ref}" \
      "${file_path_json_output}" \
      "${json_key}"
    ip_block_path=$(jq -c -r ''.${json_key}'' ${file_path_json_output})
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
    /bin/bash /nestedVsphere8/bash/nsx/create_project.sh "${nsx_manager}" "${nsx_password}" "${project_mame}" "${ip_block_path}" "${edge_cluster_path}" "${tier0_path}"
  done
fi
#
# ip block creation for other projects
#
if $(jq -e '.nsx.config | has("ip_blocks")' $jsonFile) ; then
  for ip_block in $(jq -c -r .nsx.config.ip_blocks[] $jsonFile); do
    if $(echo ${ip_block} | jq -e '. | has("project_ref")') ; then
      if [[ $(echo ${ip_block} | jq -c -r .project_ref) != "default" ]] ; then
        # retrieve ip_block_project_id
        file_path_json_output="/tmp/nsx_ip_block_project_id.json"
        json_key="project_id"
        /bin/bash /nestedVsphere8/bash/nsx/retrieve_object_id.sh \
          "${nsx_manager}" \
          "${nsx_password}" \
          "policy/api/v1/orgs/default/projects" \
          "$(echo ${ip_block} | jq -c -r .project_ref)" \
          "${file_path_json_output}" \
          "${json_key}"
        ip_block_project_id=$(jq -c -r ''.${json_key}'' ${file_path_json_output})
        ip_block_name=$(echo ${ip_block} | jq -c -r .name)
        ip_block_cidr=$(echo ${ip_block} | jq -c -r .cidr)
        ip_block_visibility=$(echo ${ip_block} | jq -c -r .visibility)
        /bin/bash /nestedVsphere8/bash/nsx/create_ip_block.sh \
          "${nsx_manager}" \
          "${nsx_password}" \
          "${ip_block_name}" \
          "${ip_block_project_id}" \
          "${ip_block_cidr}" \
          "${ip_block_visibility}"
      fi
    fi
  done
fi