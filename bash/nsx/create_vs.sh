#!/bin/bash
#
source /nestedVsphere8/bash/nsx/nsx_api.sh
#
nsx_nested_ip=${1}
nsx_password=${2}
display_name=${3}
pool_path=${4}
ip_address=${5}
ports=${6}
lb_persistence_profile_path=${7}
application_profile_path=${8}
lb_path=${9}
#
cookies_file="/root/nsx_$(basename $0 | cut -d"." -f1)_cookie.txt"
headers_file="/root/nsx_$(basename $0 | cut -d"." -f1)_header.txt"
rm -f $cookies_file $headers_file
/bin/bash /nestedVsphere8/bash/nsx/create_nsx_api_session.sh admin $nsx_password $nsx_nested_ip $cookies_file $headers_file
#
json_data='
  {
    "enabled": true,
    "ip_address": "'${ip_address}'",
    "ports": '${ports}',
    "lb_persistence_profile_path": "'${lb_persistence_profile_path}'",
    "lb_service_path": "'${lb_path}'",
    "pool_path": "'${pool_path}'",
    "application_profile_path": "'${application_profile_path}'",
    "resource_type": "LBVirtualServer",
    "display_name": "'${display_name}'"
  }'
#
nsx_api 2 2 "PUT" $cookies_file $headers_file "${json_data}" $nsx_nested_ip "policy/api/v1/infra/lb-virtual-servers/${display_name}"