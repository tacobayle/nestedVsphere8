#!/bin/bash
#
source /nestedVsphere8/bash/nsx/nsx_api.sh
#
nsx_nested_ip=${1}
nsx_password=${2}
tier1_name=${3}
json_output_file=${4}
#
cookies_file="/root/nsx_$(basename $0 | cut -d"." -f1)_cookie.txt"
headers_file="/root/nsx_$(basename $0 | cut -d"." -f1)_header.txt"
rm -f $cookies_file $headers_file
/bin/bash /nestedVsphere8/bash/nsx/create_nsx_api_session.sh admin $nsx_password $nsx_nested_ip $cookies_file $headers_file
#
nsx_api 6 10 "GET" $cookies_file $headers_file "" $nsx_nested_ip "policy/api/v1/infra/tier-1s"
t1_path=$(echo $response_body | jq -c -r --arg tier1_name "${tier1_name}" '.results[] | select(.display_name == $tier1_name) | .path')
echo "   +++ testing if variable t1_path is not empty" ; if [ -z "$t1_path" ] ; then exit 255 ; fi
echo '{"t1_path":"'${t1_path}'"}' | tee ${json_output_file}
rm -f $cookies_file $headers_file