#!/bin/bash
#
source /nestedVsphere8/bash/nsx/nsx_api.sh
#
nsx_ip="${1}"
nsx_username=admin
nsx_password="${2}"
edge_cluster_name="${3}"
json_output_file="${4}"
#
cookies_file="get_edge_clusters_cookies.txt"
headers_file="get_edge_clusters_headers.txt"
#
rm -f $cookies_file $headers_file
#
# NSX API creation
#
/bin/bash /nestedVsphere8/bash/nsx/create_nsx_api_session.sh "${nsx_username}" "${nsx_password}" "${nsx_ip}" $cookies_file $headers_file
#
# Retrieve edge cluster list
#
nsx_api 18 10 "GET" $cookies_file $headers_file "" "${nsx_ip}" "api/v1/edge-clusters"
namespace_edge_cluster_id=$(echo $response_body | jq -c -r --arg edge_cluster "${edge_cluster_name}" '.results[] | select(.display_name == $edge_cluster) | .id')
echo "   +++ testing if variable namespace_edge_cluster_id is not empty" ; if [ -z "$namespace_edge_cluster_id" ] ; then exit 255 ; fi
echo '{"namespace_edge_cluster_id":"'${namespace_edge_cluster_id}'"}' | tee ${json_output_file}