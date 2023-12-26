#!/bin/bash
#
source /nestedVsphere8/bash/nsx/nsx_api.sh
#
nsx_nested_ip=${1}
nsx_password=${2}
json_output_file=${3}
#
cookies_file="/root/nsx_$(basename $0 | cut -d"." -f1)_cookie.txt"
headers_file="/root/nsx_$(basename $0 | cut -d"." -f1)_header.txt"
rm -f $cookies_file $headers_file
/bin/bash /nestedVsphere8/bash/nsx/create_nsx_api_session.sh admin $nsx_password $nsx_nested_ip $cookies_file $headers_file
nsx_api 6 10 "GET" $cookies_file $headers_file "${json_data}" $nsx_nested_ip "policy/api/v1/orgs/default/projects"
projects=$(echo $response_body | jq -c -r '.results')
echo "   +++ testing if variable projects is not empty" ; if [ -z "$projects" ] ; then exit 255 ; fi
echo '{"projects": '${projects}'}' | tee ${json_output_file}