#!/bin/bash
#
source /home/ubuntu/lbaas/nsx/nsx_api.sh
#
jsonFile="${1}"
#
operation=$(jq -c -r .operation $jsonFile)
vs_name=$(jq -c -r .vs_name $jsonFile)
#
cookies_file="/tmp/$(basename "$0" | cut -f1 -d'.')_${date_index}_cookies.txt"
headers_file="/tmp/$(basename "$0" | cut -f1 -d'.')_${date_index}_headers.txt"
sudo rm -f $cookies_file $headers_file
#
/bin/bash /home/ubuntu/lbaas/nsx/create_nsx_api_session.sh $(jq -c -r .nsx_username $jsonFile) $(jq -c -r .nsx_password $jsonFile) $(jq -c -r .nsx_nested_ip $jsonFile) $cookies_file $headers_file
#
if [[ ${operation} == "apply" ]] ; then
  nsx_api 2 2 "GET" $cookies_file $headers_file "${json_data}" $(jq -c -r .nsx_nested_ip $jsonFile) "policy/api/v1/infra/domains/default/groups"
  if [[ $(echo $response_body | jq -c -r --arg arg "${vs_name}" '[.results[] | select(.display_name == $arg).display_name] | length') -eq 1 ]]; then
    echo "NSX group ${vs_name} already exist"
  else
    #
    json_data='
    {
      "display_name" : "'${vs_name}'",
      "expression" : [ {
        "member_type" : "VirtualMachine",
        "key" : "Name",
        "operator" : "STARTSWITH",
        "value" : "'${vs_name}'",
        "resource_type" : "Condition"
      } ]
    }'
    nsx_api 2 2 "PUT" $cookies_file $headers_file "${json_data}" $(jq -c -r .nsx_nested_ip $jsonFile) "policy/api/v1/infra/domains/default/groups/${vs_name}"
  fi
fi

if [[ ${operation} == "destroy" ]] ; then
  nsx_api 2 2 "GET" $cookies_file $headers_file "${json_data}" $(jq -c -r .nsx_nested_ip $jsonFile) "policy/api/v1/infra/domains/default/groups"
  if [[ $(echo $response_body | jq -c -r --arg arg "${vs_name}" '[.results[] | select(.display_name == $arg).display_name] | length') -eq 1 ]]; then
    nsx_api 2 2 "DELETE" $cookies_file $headers_file "" $(jq -c -r .nsx_nested_ip $jsonFile) "policy/api/v1/infra/domains/default/groups/${vs_name}"
  else
    echo "NSX group ${vs_name} does not exist"
  fi
fi