#!/bin/bash
#
#
source /nestedVsphere8/bash/nsx_api.sh
#
jsonFile="/root/nsx.json"
#
nsx_nested_ip=$(jq -r .vsphere_underlay.networks.vsphere.management.nsx_nested_ip $jsonFile)
cookies_file="create_edge_clusters_cookies.txt"
headers_file="create_edge_clusters_headers.txt"
rm -f $cookies_file $headers_file
#
/bin/bash /nestedVsphere8/bash/create_nsx_api_session.sh admin $TF_VAR_nsx_password $nsx_nested_ip $cookies_file $headers_file
IFS=$'\n'
#
# edge cluster creation
#
new_json=[]
edge_cluster_count=0
for edge_cluster in $(jq -c -r .nsx.config.edge_clusters[] $jsonFile)
do
  new_json=$(echo $new_json | jq -r -c '. |= .+ ['$edge_cluster']')
  new_json=$(echo $new_json | jq '.['$edge_cluster_count'] += {"members": []}')
  for name_edge_cluster in $(echo $edge_cluster | jq -r .members_name[])
  do
    nsx_api 6 10 "GET" $cookies_file $headers_file "" $nsx_nested_ip "api/v1/transport-nodes"
    edge_node_ids=$(echo $response_body)
#    edge_node_ids=$(curl -k -s -X GET -b cookies.txt -H "`grep X-XSRF-TOKEN headers.txt`" -H "Content-Type: application/json" https://$nsx_nested_ip/api/v1/transport-nodes)
    IFS=$'\n'
    for item in $(echo $edge_node_ids | jq -c -r .results[])
    do
      if [[ $(echo $item | jq -r .display_name) == $name_edge_cluster ]] ; then
        edge_node_id=$(echo $item | jq -r .id)
      fi
    done
    new_json=$(echo $new_json | jq '.['$edge_cluster_count'].members += [{"transport_node_id": "'$edge_node_id'", "display_name": "'$name_edge_cluster'"}]')
  done
  new_json=$(echo $new_json | jq 'del (.['$edge_cluster_count'].members_name)' )
  edge_cluster_count=$((edge_cluster_count+1))
done
for edge_cluster in $(echo $new_json | jq .[] -c -r)
do
  echo "edge cluster creation"
  nsx_api 18 10 "POST" $cookies_file $headers_file "$(echo $edge_cluster)" $nsx_nested_ip "api/v1/edge-clusters"
#  curl -k -s -X POST -b cookies.txt -H "`grep X-XSRF-TOKEN headers.txt`" -H "Content-Type: application/json" -d $(echo $edge_cluster) https://$nsx_nested_ip/api/v1/edge-clusters
done



#
#curl -k -c cookies.txt -D headers.txt -X POST -d 'j_username=admin&j_password='$TF_VAR_nsx_password'' https://$nsx_nested_ip/api/session/create
#IFS=$'\n'
##
## check the json syntax for tier0s (.nsx.config.edge_clusters)
##
#if [[ $(jq 'has("nsx")' $jsonFile) && $(jq '.nsx | has("config")' $jsonFile) && $(jq '.nsx.config | has("edge_clusters")' $jsonFile) == "false" ]] ; then
#  echo "no json valid entry for nsx.config.edge_clusters"
#  exit
#fi
##
## edge cluster creation
##
#new_json=[]
#edge_cluster_count=0
#for edge_cluster in $(jq -c -r .nsx.config.edge_clusters[] $jsonFile)
#do
#  new_json=$(echo $new_json | jq -r -c '. |= .+ ['$edge_cluster']')
#  new_json=$(echo $new_json | jq '.['$edge_cluster_count'] += {"members": []}')
#  for name_edge_cluster in $(echo $edge_cluster | jq -r .members_name[])
#  do
#    edge_node_ids=$(curl -k -s -X GET -b cookies.txt -H "`grep X-XSRF-TOKEN headers.txt`" -H "Content-Type: application/json" https://$nsx_nested_ip/api/v1/transport-nodes)
#    IFS=$'\n'
#    for item in $(echo $edge_node_ids | jq -c -r .results[])
#    do
#      if [[ $(echo $item | jq -r .display_name) == $name_edge_cluster ]] ; then
#        edge_node_id=$(echo $item | jq -r .id)
#      fi
#    done
#    new_json=$(echo $new_json | jq '.['$edge_cluster_count'].members += [{"transport_node_id": "'$edge_node_id'", "display_name": "'$name_edge_cluster'"}]')
#  done
#  new_json=$(echo $new_json | jq 'del (.['$edge_cluster_count'].members_name)' )
#  edge_cluster_count=$((edge_cluster_count+1))
#done
#for edge_cluster in $(echo $new_json | jq .[] -c -r)
#do
#  echo "edge cluster creation"
#  curl -k -s -X POST -b cookies.txt -H "`grep X-XSRF-TOKEN headers.txt`" -H "Content-Type: application/json" -d $(echo $edge_cluster) https://$nsx_nested_ip/api/v1/edge-clusters
#done
