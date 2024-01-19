#!/bin/bash
#
source /nestedVsphere8/bash/nsx/nsx_api.sh
#
IFS=$'\n'
#
nsx_nested_ip="${1}"
nsx_password="${2}"
vsphere_nested_cluster="${3}"
transport_node_profile="${4}"
cookies_file="/root/nsx_$(basename $0 | cut -d"." -f1)_cookie.txt"
headers_file="/root/nsx_$(basename $0 | cut -d"." -f1)_header.txt"
rm -f ${cookies_file} ${headers_file}
#
/bin/bash /nestedVsphere8/bash/nsx/create_nsx_api_session.sh admin $nsx_password $nsx_nested_ip $cookies_file $headers_file
nsx_api 2 2 "GET" $cookies_file $headers_file "" $nsx_nested_ip "api/v1/fabric/compute-collections"
compute_collections=$(echo $response_body)
#
for item in $(echo $compute_collections | jq -c -r .results[])
do
  if [[ $(echo $item | jq -r .display_name) == ${vsphere_nested_cluster} ]] ; then
    compute_collection_external_id=$(echo $item | jq -r .external_id)
  fi
done
#
nsx_api 2 2 "GET" $cookies_file $headers_file "" $nsx_nested_ip "api/v1/infra/host-transport-node-profiles"
transport_node_profiles=$(echo $response_body)
for item in $(echo $transport_node_profiles | jq -c -r .results[])
do
  if [[ $(echo $item | jq -r .display_name) == ${transport_node_profile} ]] ; then
    transport_node_profile_id=$(echo $item | jq -r .id)
  fi
done
#
json_data='
{
  "resource_type": "TransportNodeCollection",
  "display_name": "TransportNodeCollection-1",
  "description": "Transport Node Collections 1",
  "compute_collection_id": "'$compute_collection_external_id'",
  "transport_node_profile_id": "'$transport_node_profile_id'"
}'
#
nsx_api 2 2 "POST" $cookies_file $headers_file "${json_data}" $nsx_nested_ip "api/v1/transport-node-collections"
#
# waiting for host transport node to be ready
#
sleep 60
nsx_api 10 60 "GET" $cookies_file $headers_file "" $nsx_nested_ip "api/v1/infra/sites/default/enforcement-points/default/host-transport-nodes"
discovered_nodes=$(echo $response_body)
retry_1=60 ; pause_1=30 ; attempt_1=0
#
for item in $(echo $discovered_nodes | jq -c -r .results[])
do
  echo "Waiting for host transport nodes to be ready, attempt: $retry_1"
  unique_id=$(echo $item | jq -c -r .unique_id)
  while true ; do
    nsx_api 10 60 "GET" $cookies_file $headers_file "" $nsx_nested_ip "api/v1/infra/sites/default/enforcement-points/default/host-transport-nodes/$unique_id/state"
    hosts_host_transport_node_state=$(echo $response_body)
    if [[ "$(echo $hosts_host_transport_node_state | jq -r .deployment_progress_state.progress)" == 100 ]] && [[ "$(echo $hosts_host_transport_node_state | jq -r .state)" == "success"  ]] ; then
      echo "  Host transport node id $unique_id progress at 100% and host transport node state success"
      break
    else
      echo "  Waiting for host transport node id $unique_id to be ready, attempt: $attempt_1 on $retry_1"
    fi
    if [ $attempt_1 -eq $retry_1 ]; then
      echo "  FAILED to get transport node deployment progress at 100% after $attempt_1"
      echo "$response_body"
      exit 255
    fi
    sleep $pause_1
    ((attempt_1++))
  done
done
#