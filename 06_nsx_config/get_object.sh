#!/bin/bash
jsonFile="/root/nsx.json"
source /nestedVsphere8/bash/nsx/nsx_api.sh
#
nsx_manager=$(jq -r .vsphere_underlay.networks.vsphere.management.nsx_nested_ip $jsonFile)
nsx_password=${TF_VAR_nsx_password}
#
file_json_output=/tmp/nsx_object.json
/bin/bash /nestedVsphere8/bash/nsx/get_object.sh "${nsx_manager}" "${nsx_password}" \
          "policy/api/v1/infra/tier-1s" \
          "${file_json_output}"
jq . ${file_json_output}