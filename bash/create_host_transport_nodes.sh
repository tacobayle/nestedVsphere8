#!/bin/bash
#
source /nestedVsphere8/bash/nsx_api.sh
#
jsonFile="/root/nsx3.json"
#
nsx_ip=$(jq -r .vcenter_underlay.networks.vsphere.management.nsx_ip $jsonFile)
vcenter_username=administrator
vcenter_domain=$(jq -r .vcenter.sso.domain_name $jsonFile)
vcenter_fqdn="$(jq -r .vcenter.name $jsonFile).$(jq -r .external_gw.bind.domain $jsonFile)"
cookies_file="create_host_transport_nodes_cookies.txt"
headers_file="create_host_transport_nodes_headers.txt"
rm -f $cookies_file $headers_file
#
/bin/bash /nestedVsphere8/bash/create_nsx_api_session.sh admin $TF_VAR_nsx_password $nsx_ip $cookies_file $headers_file
nsx_api 6 10 "GET" $cookies_file $headers_file "" $nsx_ip "api/v1/fabric/compute-collections"
compute_collections=$(echo $response_body)
IFS=$'\n'
for item in $(echo $compute_collections | jq -c -r .results[])
do
  if [[ $(echo $item | jq -r .display_name) == $(jq -r .vcenter.cluster $jsonFile) ]] ; then
    compute_collection_external_id=$(echo $item | jq -r .external_id)
  fi
done
nsx_api 6 10 "GET" $cookies_file $headers_file "" $nsx_ip "api/v1/infra/host-transport-node-profiles"
transport_node_profiles=$(echo $response_body)
IFS=$'\n'
for item in $(echo $transport_node_profiles | jq -c -r .results[])
do
  if [[ $(echo $item | jq -r .display_name) == $(jq -r .nsx.config.transport_node_profiles[0].name $jsonFile) ]] ; then
    transport_node_profile_id=$(echo $item | jq -r .id)
  fi
done
nsx_api 6 10 "POST" $cookies_file $headers_file '{"resource_type": "TransportNodeCollection", "display_name": "TransportNodeCollection-1", "description": "Transport Node Collections 1", "compute_collection_id": "'$compute_collection_external_id'", "transport_node_profile_id": "'$transport_node_profile_id'"}' $nsx_ip "api/v1/transport-node-collections"
#
# waiting for host transport node to be ready
#
sleep 60
nsx_api 10 60 "GET" $cookies_file $headers_file "" $nsx_ip "api/v1/infra/sites/default/enforcement-points/default/host-transport-nodes"
discovered_nodes=$(echo $response_body)
retry_1=60 ; pause_1=30 ; attempt_1=0
IFS=$'\n'
for item in $(echo $discovered_nodes | jq -c -r .results[])
do
  echo "Waiting for host transport nodes to be ready, attempt: $retry_1"
  unique_id=$(echo $item | jq -c -r .unique_id)
  while true ; do
    nsx_api 10 60 "GET" $cookies_file $headers_file "" $nsx_ip "api/v1/infra/sites/default/enforcement-points/default/host-transport-nodes/$unique_id/state"
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
rm -f $cookies_file $headers_file