#!/bin/bash
#
source /nestedVsphere8/bash/nsx/nsx_api.sh
#
jsonFile="/root/nsx.json"
#
IFS=$'\n'
nsx_nested_ip=$(jq -r .vsphere_underlay.networks.vsphere.management.nsx_nested_ip $jsonFile)
cookies_file="create_tiers0_cookies.txt"
headers_file="create_tiers0_headers.txt"
rm -f $cookies_file $headers_file
#
/bin/bash /nestedVsphere8/bash/nsx/create_nsx_api_session.sh admin $TF_VAR_nsx_password $nsx_nested_ip $cookies_file $headers_file
IFS=$'\n'
#
# check the json syntax for tier0s (.nsx.config.tier0s)
#
if [[ $(jq 'has("nsx")' $jsonFile) && $(jq '.nsx | has("config")' $jsonFile) && $(jq '.nsx.config | has("tier0s")' $jsonFile) == "false" ]] ; then
  echo "no json valid entry for nsx.config.tier0s"
  exit
fi
#
# tier 0 creation
#
new_json={}
for tier0 in $(jq -c -r .nsx.config.tier0s[] $jsonFile)
do
  new_json=$(echo $tier0 | jq -c -r '. | del (.edge_cluster_name)')
  new_json=$(echo $new_json | jq -c -r '. | del (.interfaces)')
  new_json=$(echo $new_json | jq -c -r '. | del (.static_routes)')
  new_json=$(echo $new_json | jq -c -r '. | del (.ha_vips)')
  new_json=$(echo $new_json | jq -c -r '. | del (.bgp)')
  echo "creating the tier0 called $(echo $tier0 | jq -r -c .display_name)"
  nsx_api 2 2 "PUT" $cookies_file $headers_file "$(echo $new_json)" $nsx_nested_ip "policy/api/v1/infra/tier-0s/$(echo $tier0 | jq -r -c .display_name)"
  #curl -k -s -X PUT -b cookies.txt -H "`grep X-XSRF-TOKEN headers.txt`" -H "Content-Type: application/json" -d $(echo $new_json) https://$nsx_nested_ip/policy/api/v1/infra/tier-0s/$(echo $tier0 | jq -r -c .display_name)
done
#
# tier 0 edge cluster association
#
new_json={}
for tier0 in $(jq -c -r .nsx.config.tier0s[] $jsonFile)
do
  if [[ $(echo $tier0 | jq 'has("edge_cluster_name")') == "true" ]] ; then
    nsx_api 2 2 "GET" $cookies_file $headers_file "" $nsx_nested_ip "api/v1/edge-clusters"
    edge_clusters=$(echo $response_body | jq -c -r .results[])
    for cluster in $edge_clusters
    do
      if [[ $(echo $cluster | jq -r .display_name) == $(echo $tier0 | jq -r -c .edge_cluster_name) ]] ; then
          edge_cluster_id=$(echo $cluster | jq -r .id)
      fi
    done
    new_json="{\"edge_cluster_path\": \"/infra/sites/default/enforcement-points/default/edge-clusters/$edge_cluster_id\"}"
    echo "associate the tier0 called $(echo $tier0 | jq -r -c .display_name) with edge cluster name $(echo $tier0 | jq -r -c .edge_cluster_name)"
    nsx_api 2 2 "PUT" $cookies_file $headers_file "$(echo $new_json)" $nsx_nested_ip "policy/api/v1/infra/tier-0s/$(echo $tier0 | jq -r -c .display_name)/locale-services/default"
#    curl -k -s -X PUT -b cookies.txt -H "`grep X-XSRF-TOKEN headers.txt`" -H "Content-Type: application/json" -d $(echo $new_json) https://$nsx_nested_ip/policy/api/v1/infra/tier-0s/$(echo $tier0 | jq -r -c .display_name)/locale-services/default
  fi
done
#
# tier 0 iface config
#
ip_index=0
for tier0 in $(jq -c -r .nsx.config.tier0s[] $jsonFile)
do
  if [[ $(echo $tier0 | jq 'has("interfaces")') == "true" ]] ; then
    for interface in $(echo $tier0 | jq -c -r .interfaces[])
    do
      new_json="{\"subnets\" : [ {\"ip_addresses\": [\"$(jq -c -r '.vsphere_underlay.networks.nsx.external.tier0_ips['$ip_index']' $jsonFile)\"], \"prefix_len\" : $(jq -c -r '.vsphere_underlay.networks.nsx.external.prefix' $jsonFile)}]}"
      ip_index=$((ip_index+1))
      new_json=$(echo $new_json | jq .)
      new_json=$(echo $new_json | jq '. += {"display_name": "'$(echo $interface | jq -r .display_name)'"}')
      nsx_api 2 2 "GET" $cookies_file $headers_file "" $nsx_nested_ip "policy/api/v1/infra/segments"
      segments=$(echo $response_body | jq -c -r .results[])
      for segment in $segments
      do
        if [[ $(echo $segment | jq -r .display_name) == $(echo $interface | jq -r -c .segment_name) ]] ; then
          segment_path=$(echo $segment | jq -r .path)
        fi
      done
      new_json=$(echo $new_json | jq '. += {"segment_path": "'$segment_path'"}')
      nsx_api 2 2 "GET" $cookies_file $headers_file "" $nsx_nested_ip "api/v1/edge-clusters"
      edge_clusters=$(echo $response_body | jq -c -r .results[])
      for cluster in $edge_clusters
      do
        if [[ $(echo $cluster | jq -r .display_name) == $(echo $tier0 | jq -r -c .edge_cluster_name) ]] ; then
          edge_cluster_id=$(echo $cluster | jq -r .id)
          for edge_node in $(echo $cluster | jq -r -c .members[])
          do
            if [[ $(echo $edge_node | jq -r .display_name) == $(echo $interface | jq -r -c .edge_name) ]] ; then
              edge_node_id=$(echo $edge_node | jq -r .member_index)
            fi
          done
        fi
      done
      new_json=$(echo $new_json | jq '. += {"edge_path": "/infra/sites/default/enforcement-points/default/edge-clusters/'$(echo $edge_cluster_id)'/edge-nodes/'$(echo $edge_node_id)'"}')
      echo "adding interface to the tier0 called $(echo $tier0 | jq -r -c .display_name)"
      nsx_api 2 2 "PATCH" $cookies_file $headers_file "$(echo $new_json)" $nsx_nested_ip "policy/api/v1/infra/tier-0s/$(echo $tier0 | jq -r -c .display_name)/locale-services/default/interfaces/$(echo $interface | jq -r -c .display_name)"
#      curl -k -s -X PATCH -b cookies.txt -H "`grep X-XSRF-TOKEN headers.txt`" -H "Content-Type: application/json" -d $(echo $new_json) https://$nsx_nested_ip/policy/api/v1/infra/tier-0s/$(echo $tier0 | jq -r -c .display_name)/locale-services/default/interfaces/$(echo $interface | jq -r -c .display_name)
    done
  fi
done
#
# tier 0 static routes
#
for tier0 in $(jq -c -r .nsx.config.tier0s[] $jsonFile)
do
  if [[ $(echo $tier0 | jq 'has("static_routes")') == "true" ]] ; then
    for route in $(echo $tier0 | jq -c -r .static_routes[])
    do
      echo "Adding route: $route to the tier0 called $(echo $tier0 | jq -r -c .display_name)"
      nsx_api 2 2 "PATCH" $cookies_file $headers_file "$(echo $route)" $nsx_nested_ip "policy/api/v1/infra/tier-0s/$(echo $tier0 | jq -r -c .display_name)/static-routes/$(echo $route | jq -r -c .display_name)"
#      curl -k -s -X PATCH -b cookies.txt -H "`grep X-XSRF-TOKEN headers.txt`" -H "Content-Type: application/json" -d $(echo $route) https://$nsx_nested_ip/policy/api/v1/infra/tier-0s/$(echo $tier0 | jq -r -c .display_name)/static-routes/$(echo $route | jq -r -c .display_name)
    done
  fi
done
#
# tier 0 ha-vip config
#
ip_index=0
new_json="{\"display_name\": \"default\", \"ha_vip_configs\": []}"
for tier0 in $(jq -c -r .nsx.config.tier0s[] $jsonFile)
do
  if [[ $(echo $tier0 | jq 'has("ha_vips")') == "true" ]] ; then
    nsx_api 2 2 "GET" $cookies_file $headers_file "" $nsx_nested_ip "api/v1/edge-clusters"
    edge_clusters=$(echo $response_body | jq -c -r .results[])
    for cluster in $edge_clusters
    do
      if [[ $(echo $cluster | jq -r .display_name) == $(echo $tier0 | jq -r -c .edge_cluster_name) ]] ; then
          edge_cluster_id=$(echo $cluster | jq -r .id)
      fi
    done
    new_json=$(echo $new_json | jq '. += {"edge_cluster_path": "/infra/sites/default/enforcement-points/default/edge-clusters/'$edge_cluster_id'"}')
    for vip in $(echo $tier0 | jq -c -r .ha_vips[])
    do
      interfaces=[]
      for interface in $(echo $vip | jq -c -r .interfaces[])
      do
        interfaces=$(echo $interfaces | jq -c -r '. += ["/infra/tier-0s/'$(echo $tier0 | jq -r -c .display_name)'/locale-services/default/interfaces/'$interface'"]')
      done
      new_json=$(echo $new_json | jq -c -r '.ha_vip_configs += [{"enabled": true, "vip_subnets": [{"ip_addresses": [ "'$(jq -c -r '.vsphere_underlay.networks.nsx.external.tier0_vips['$ip_index']' $jsonFile)'" ], "prefix_len": '$(jq -c -r '.vsphere_underlay.networks.nsx.external.prefix' $jsonFile)'}], "external_interface_paths": '$interfaces'}]')
      ip_index=$((ip_index+1))
    done
    echo "adding HA to the tier0 called $(echo $tier0 | jq -r -c .display_name)"
    nsx_api 2 2 "PATCH" $cookies_file $headers_file "$(echo $new_json)" $nsx_nested_ip "policy/api/v1/infra/tier-0s/$(echo $tier0 | jq -r -c .display_name)/locale-services/default"
#    curl -k -s -X PATCH -b cookies.txt -H "`grep X-XSRF-TOKEN headers.txt`" -H "Content-Type: application/json" -d $(echo $new_json) https://$nsx_nested_ip/policy/api/v1/infra/tier-0s/$(echo $tier0 | jq -r -c .display_name)/locale-services/default
  fi
done
#
# BGP config
#
for tier0 in $(jq -c -r .nsx.config.tier0s[] $jsonFile)
do
  if [[ $(echo $tier0 | jq 'has("bgp")') == "true" ]] ; then
    echo "Enabling BGP on tier0 called: $(echo $tier0 | jq -r -c .display_name) with local AS: $(echo $tier0 | jq -r -c .bgp.local_as_num)"
    nsx_api 2 2 "PATCH" $cookies_file $headers_file '{"enabled": "true", "local_as_num": "'$(echo $tier0 | jq -r -c .bgp.local_as_num)'", "ecmp": "'$(echo $tier0 | jq -r -c .bgp.ecmp)'"}' "$nsx_nested_ip/policy/api/v1/infra/tier-0s/$(echo $tier0 | jq -r -c .display_name)/locale-services/default/bgp"
    echo "retrieving tier0 called: $(echo $tier0 | jq -r -c .display_name) interfaces details"
    nsx_api 2 2 "GET" $cookies_file $headers_file '' "$nsx_nested_ip/policy/api/v1/infra/tier-0s/$(echo $tier0 | jq -r -c .display_name)/locale-services/default/interfaces"
    tier0_interfaces=$(echo $response_body)
    tier0_interfaces_ips="[]"
    for interface in $(echo $tier0_interfaces | jq -c -r .results[])
    do
      tier0_interfaces_ips=$(echo $tier0_interfaces_ips | jq -c -r '. += ['$(echo $interface | jq -c '.subnets[0].ip_addresses[0]')']')
    done
    nsx_api 2 2 "GET" $cookies_file $headers_file '' "$nsx_nested_ip/policy/api/v1/infra/tier-0s/$(echo $tier0 | jq -r -c .display_name)/locale-services/default/interfaces"
    neighbor_count=1
    for neighbor in $(echo $tier0 | jq -c -r .bgp.neighbors[])
    do
      echo "Adding neighbor called: peer$neighbor_count to the tier0 called $(echo $tier0 | jq -r -c .display_name) with remote AS number: $(echo $neighbor | jq -r -c .remote_as_num), with remote neighbor IP: $(echo $neighbor | jq -r -c .neighbor_address), with source IP: $(echo $tier0_interfaces_ips | jq -c -r .))"
      nsx_api 1 1 "PUT" $cookies_file $headers_file '{"neighbor_address": "'$(echo $neighbor | jq -r -c .neighbor_address)'", "remote_as_num": "'$(echo $neighbor | jq -r -c .remote_as_num)'", "source_addresses": '$(echo $tier0_interfaces_ips | jq -c -r .)'}' "$nsx_nested_ip/policy/api/v1/infra/tier-0s/$(echo $tier0 | jq -r -c .display_name)/locale-services/default/bgp/neighbors/peer$neighbor_count"
      ((neighbor_count++))
    done
  fi
done