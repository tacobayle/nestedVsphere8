#!/bin/bash
jsonFile="/root/nsx.json"
source /nestedVsphere8/bash/nsx/nsx_api.sh
#
IFS=$'\n'
#
nsx_manager=$(jq -r .vsphere_underlay.networks.vsphere.management.nsx_nested_ip $jsonFile)
nsx_password=${TF_VAR_nsx_password}
#
# lb creation
#
count=1
if $(jq -e '.nsx.config | has("tier1s")' $jsonFile) ; then
  for tier1 in $(jq -c -r .nsx.config.tier1s[] $jsonFile); do
    if [[ $(echo $tier1 | jq -c -r .lb) == true ]] ; then
      lb_name="lb-${count}"
      tier1_ref=$(echo ${tier1} | jq -c -r .display_name)
      # retrieve tier1_path
      file_json_output="/tmp/nsx_lb_tier1_path.json"
      json_key="t1_path"
      /bin/bash /nestedVsphere8/bash/nsx/retrieve_object_path.sh "${nsx_manager}" "${nsx_password}" \
                "policy/api/v1/infra/tier-1s" \
                "${tier1_ref}" \
                "${file_json_output}" \
                "${json_key}"
      tier1_path=$(jq -c -r ''.${json_key}'' ${file_json_output})
      echo "   +++ tier1 path is: ${tier1_path} for lb called ${lb_name}"
      # create lb
      /bin/bash /nestedVsphere8/bash/nsx/create_lb.sh "${nsx_manager}" "${nsx_password}" \
      "${lb_name}" \
      "${tier1_path}" \
      "$(jq -c -r .nsx.config.lb_size ${jsonFile})"
      # retrieve group_path
      nsx_group_name=$(jq -c -r .app.nsxt_group_name /root/app.json)
      file_json_output="/tmp/nsx_lb_group_path.json"
      json_key="group_path"
      /bin/bash /nestedVsphere8/bash/nsx/retrieve_object_path.sh "${nsx_manager}" "${nsx_password}" \
                "policy/api/v1/infra/domains/default/groups" \
                "${nsx_group_name}" \
                "${file_json_output}" \
                "${json_key}"
      group_path=$(jq -c -r ''.${json_key}'' ${file_json_output})
      echo "   +++ group path is: ${group_path} for lb called ${lb_name}"
      # pool creation
      pool_name="pool-${count}"
      /bin/bash /nestedVsphere8/bash/nsx/create_pool.sh "${nsx_manager}" "${nsx_password}" \
      "${pool_name}" \
      "${group_path}"
      # retrieve lb_path
      file_json_output="/tmp/nsx_lb_lb_path.json"
      json_key="lb_path"
      /bin/bash /nestedVsphere8/bash/nsx/retrieve_object_path.sh "${nsx_manager}" "${nsx_password}" \
                "policy/api/v1/infra/lb-services/" \
                "${lb_name}" \
                "${file_json_output}" \
                "${json_key}"
      lb_path=$(jq -c -r ''.${json_key}'' ${file_json_output})
      # retrieve pool_path
      file_json_output="/tmp/nsx_lb_pool_path.json"
      json_key="pool_path"
      /bin/bash /nestedVsphere8/bash/nsx/retrieve_object_path.sh "${nsx_manager}" "${nsx_password}" \
                "policy/api/v1/infra/lb-pools" \
                "${pool_name}" \
                "${file_json_output}" \
                "${json_key}"
      pool_path=$(jq -c -r ''.${json_key}'' ${file_json_output})
      # vs creation
      vs_name="vs-${count}"
      /bin/bash /nestedVsphere8/bash/nsx/create_vs.sh "${nsx_manager}" "${nsx_password}" \
      "${vs_name}" \
      "${pool_path}" \
      "$(jq -c -r .nsx.config.vip_pool ${jsonFile})${count}" \
      "$(jq -c -r .nsx.config.vip_ports ${jsonFile})" \
      "$(jq -c -r .nsx.config.lb_persistence_profile_path ${jsonFile})" \
      "$(jq -c -r .nsx.config.application_profile_path ${jsonFile})" \
      "${lb_path}"
      #
      count=$((count+1))
    fi
  done
fi