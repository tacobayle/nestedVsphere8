#!/bin/bash
#
source /nestedVsphere8/bash/nsx/nsx_api.sh
#
nsx_nested_ip=${1}
nsx_password=${2}
edge_cluster_name=${3}
json_output_file=${4}
json_key=${5}
#
cookies_file="/root/nsx_$(basename $0 | cut -d"." -f1)_cookie.txt"
headers_file="/root/nsx_$(basename $0 | cut -d"." -f1)_header.txt"
rm -f $cookies_file $headers_file
/bin/bash /nestedVsphere8/bash/nsx/create_nsx_api_session.sh admin $nsx_password $nsx_nested_ip $cookies_file $headers_file
#
nsx_api 2 2 "GET" $cookies_file $headers_file "" $nsx_nested_ip "api/v1/edge-clusters"
edge_cluster_id=$(echo $response_body | jq -c -r --arg edge_cluster_name "${edge_cluster_name}" '.results[] | select(.display_name == $edge_cluster_name) | .id')
echo "   +++ testing if variable edge_cluster_id is not empty" ; if [ -z "$edge_cluster_id" ] ; then exit 255 ; fi
echo '{"'${json_key}'":"/infra/sites/default/enforcement-points/default/edge-clusters/'${edge_cluster_id}'"}' | tee ${json_output_file}
rm -f $cookies_file $headers_file