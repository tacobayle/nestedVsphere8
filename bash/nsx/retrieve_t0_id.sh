#!/bin/bash
#
source /nestedVsphere8/bash/nsx/nsx_api.sh
#
nsx_nested_ip=${1}
nsx_password=${2}
tier0_name=${3}
json_output_file=${4}
#
cookies_file="/root/nsx_$(basename $0 | cut -d"." -f1)_cookie.txt"
headers_file="/root/nsx_$(basename $0 | cut -d"." -f1)_header.txt"
rm -f $cookies_file $headers_file
/bin/bash /nestedVsphere8/bash/nsx/create_nsx_api_session.sh admin $nsx_password $nsx_nested_ip $cookies_file $headers_file
#
nsx_api 6 10 "GET" $cookies_file $headers_file "" $nsx_nested_ip "policy/api/v1/infra/tier-0s"
t0_path=$(echo $response_body | jq -c -r --arg tier0_name "${tier0_name}" '.results[] | select(.display_name == $tier0_name) | .path')
echo "   +++ testing if variable t0_path is not empty" ; if [ -z "$t0_path" ] ; then exit 255 ; fi
echo '{"t0_path":"'${t0_path}'"}' | tee ${json_output_file}
rm -f $cookies_file $headers_file