#!/bin/bash
#
source /nestedVsphere8/bash/nsx/nsx_api.sh
#
nsx_nested_ip="${1}"
nsx_password="${2}"
ip_block_name="${3}"
ip_block_project_id="${4}"
ip_block_cidr="${5}"
ip_block_visibility="${6}"
#
cookies_file="/root/nsx_$(basename $0 | cut -d"." -f1)_cookie.txt"
headers_file="/root/nsx_$(basename $0 | cut -d"." -f1)_header.txt"
rm -f $cookies_file $headers_file
/bin/bash /nestedVsphere8/bash/nsx/create_nsx_api_session.sh admin $nsx_password $nsx_nested_ip $cookies_file $headers_file
#
json_data='
  {
    "display_name": "'${ip_block_name}'",
    "cidr": "'${ip_block_cidr}'",
    "visibility": "'${ip_block_visibility}'"
  }'
if [[ ${ip_block_project_id} == "default" ]] ; then
  nsx_api 1 2 "PATCH" $cookies_file $headers_file "${json_data}" $nsx_nested_ip "policy/api/v1/infra/ip-blocks/${ip_block_name}"
else
  nsx_api 1 2 "PATCH" $cookies_file $headers_file "${json_data}" $nsx_nested_ip "policy/api/v1/orgs/default/projects/${ip_block_project_id}/infra/ip-blocks/${ip_block_name}"
fi