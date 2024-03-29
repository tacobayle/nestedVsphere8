#!/bin/bash
#
source /nestedVsphere8/bash/nsx/nsx_api.sh
#
nsx_nested_ip=${1}
nsx_password=${2}
display_name=${3}
connectivity_path=${4}
size=${5}
#
cookies_file="/root/nsx_$(basename $0 | cut -d"." -f1)_cookie.txt"
headers_file="/root/nsx_$(basename $0 | cut -d"." -f1)_header.txt"
rm -f $cookies_file $headers_file
/bin/bash /nestedVsphere8/bash/nsx/create_nsx_api_session.sh admin $nsx_password $nsx_nested_ip $cookies_file $headers_file
#
json_data='
  {
    "display_name": "'${display_name}'",
    "connectivity_path": "'${connectivity_path}'",
    "size": "'${size}'"
  }'
#
nsx_api 2 2 "PUT" $cookies_file $headers_file "${json_data}" $nsx_nested_ip "policy/api/v1/infra/lb-services/${display_name}"