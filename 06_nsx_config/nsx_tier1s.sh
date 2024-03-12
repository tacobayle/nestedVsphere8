#!/bin/bash
jsonFile="/root/nsx.json"
source /nestedVsphere8/bash/nsx/nsx_api.sh
#
IFS=$'\n'
#
nsx_manager=$(jq -r .vsphere_underlay.networks.vsphere.management.nsx_nested_ip $jsonFile)
nsx_password=${TF_VAR_nsx_password}
#
# tier1 creation
#
if $(jq -e '.nsx.config | has("tier1s")' $jsonFile) ; then
  for tier1 in $(jq -c -r .nsx.config.tier1s[] $jsonFile); do
    tier1_name=$(echo ${tier1} | jq -c -r .display_name)
    tier0_ref=$(echo ${tier1} | jq -c -r .tier0)
    dhcp_server_ref=$(echo ${tier1} | jq -c -r .dhcp_server)
    # retrieve tier0_path
    file_json_output="/tmp/nsx_tier1_tier0_path.json"
    json_key="t0_path"
    /bin/bash /nestedVsphere8/bash/nsx/retrieve_object_path.sh "${nsx_manager}" "${nsx_password}" \
              "policy/api/v1/infra/tier-0s" \
              "${tier0_ref}" \
              "${file_json_output}" \
              "${json_key}"
    tier0_path=$(jq -c -r ''.${json_key}'' ${file_json_output})
    echo "   +++ tier0 path is: ${tier0_path} for tier1 called ${tier1_name}"
    # retrieve dhcp_config_path
    file_json_output="/tmp/nsx_tier1_dhcp_path.json"
    json_key="dhcp_path"
    /bin/bash /nestedVsphere8/bash/nsx/retrieve_object_path.sh "${nsx_manager}" "${nsx_password}" \
              "policy/api/v1/infra/dhcp-server-configs" \
              "${dhcp_server_ref}" \
              "${file_json_output}" \
              "${json_key}"
    dhcp_config_path=$(jq -c -r ''.${json_key}'' ${file_json_output})
    echo "   +++ dhcp_config path is: ${dhcp_config_path} for tier1 called ${tier1_name}"
    # retrieve edge_cluster_path
    if $(echo $tier1 | jq -e '.edge_cluster_name' > /dev/null) ; then
      file_json_output="/tmp/nsx_tier1_edge_cluster_id.json"
      json_key="edge_cluster_id"
      /bin/bash /nestedVsphere8/bash/nsx/retrieve_object_id.sh "${nsx_manager}" "${nsx_password}" \
                "api/v1/edge-clusters" \
                "$(echo ${tier1} | jq -c -r .edge_cluster_name)" \
                "${file_json_output}" \
                "${json_key}"
      edge_cluster_path="/infra/sites/default/enforcement-points/default/edge-clusters/$(jq -c -r ''.${json_key}'' ${file_json_output})"
      echo "   +++ edge_cluster path is: ${edge_cluster_path} for tier1 called ${tier1_name}"
    else
      echo "   ++++++ tier1 called $(echo $tier1 | jq '.display_name') has no .edge_cluster_name"
      edge_cluster_path=""
    fi
    if $(echo $tier1 | jq -e '.ha_mode' > /dev/null) ; then
      ha_mode=$(echo ${tier1} | jq -c -r .ha_mode)
      echo "   +++ ha_mode is: ${ha_mode} for tier1 called ${tier1_name}"
    else
      echo "   ++++++ tier1 called $(echo $tier1 | jq '.display_name') has no .ha_mode"
      ha_mode=""
    fi
    # create tier1
    /bin/bash /nestedVsphere8/bash/nsx/create_tier1.sh "${nsx_manager}" "${nsx_password}" \
      "${tier1_name}" \
      "${tier0_path}" \
      "${dhcp_config_path}" \
      "$(echo ${tier1} | jq -c -r .route_advertisement_types)" \
      "${ha_mode}" \
      "${edge_cluster_path}"
  done
fi
