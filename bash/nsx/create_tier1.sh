#!/bin/bash
#
source /nestedVsphere8/bash/nsx/nsx_api.sh
#
nsx_nested_ip=${1}
nsx_password=${2}
t1_display_name=${3}
tier0_path=${4}
dhcp_config_path=${5}
route_advertisement_types=$(echo ${6} | jq -c -r .)
ha_mode=${7}
edge_cluster_path=${8}
#
cookies_file="/root/nsx_$(basename $0 | cut -d"." -f1)_cookie.txt"
headers_file="/root/nsx_$(basename $0 | cut -d"." -f1)_header.txt"
rm -f $cookies_file $headers_file
/bin/bash /nestedVsphere8/bash/nsx/create_nsx_api_session.sh admin $nsx_password $nsx_nested_ip $cookies_file $headers_file
#
json_data='
  {
    "display_name": "'${t1_display_name}'",
    "tier0_path": "'${tier0_path}'",
    "dhcp_config_paths": ["'${dhcp_config_path}'"],
    "route_advertisement_types": '${route_advertisement_types}'
  }'
#
if [[ ${ha_mode} != "" ]] ; then
  json_data=$(echo $json_data | jq '. += {"ha_mode": "'${ha_mode}'"}')
fi
#
nsx_api 2 2 "PUT" $cookies_file $headers_file "${json_data}" $nsx_nested_ip "policy/api/v1/infra/tier-1s/${t1_display_name}"
#
if [[ ${edge_cluster_path} != "" ]] ; then
  json_data='
    {
      "display_name": "default",
      "edge_cluster_path": "'${edge_cluster_path}'"
    }'
    nsx_api 2 2 "PUT" $cookies_file $headers_file "${json_data}" $nsx_nested_ip "policy/api/v1/infra/tier-1s/${t1_display_name}/locale-services/default"

fi