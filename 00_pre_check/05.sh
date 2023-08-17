#!/bin/bash
#
source /nestedVsphere8/bash/ip.sh
source /nestedVsphere8/bash/test_if_variables.sh
#
jsonFile="/root/variables.json"
localJsonFile="/nestedVsphere8/05_nsx_manager/variables.json"
#
IFS=$'\n'
#
echo ""
echo "==> Creating /root/nsx.json file..."
rm -f /root/nsx.json
nsx_json=$(jq -c -r . $jsonFile | jq .)
#
echo "   +++ Adding nsx_ova_path..."
nsx_ova_path=$(jq -c -r '.nsx_ova_path' $localJsonFile)
nsx_json=$(echo $nsx_json | jq '. += {"nsx_ova_path": "'$(echo $nsx_ova_path)'"}')
#
echo "   +++ Adding dhcp_servers_api_endpoint..."
dhcp_servers_api_endpoint=$(jq -c -r '.dhcp_servers_api_endpoint' $localJsonFile)
nsx_json=$(echo $nsx_json | jq '. += {"dhcp_servers_api_endpoint": "'$(echo $dhcp_servers_api_endpoint)'"}')
#
echo "   +++ Adding dhcp_servers..."
dhcp_servers=$(jq -c -r '.dhcp_servers' $localJsonFile)
nsx_json=$(echo $nsx_json | jq '. += {"dhcp_servers": '$(echo $dhcp_servers)'}')
#
echo "   +++ Adding groups_api_endpoint..."
groups_api_endpoint=$(jq -c -r '.groups_api_endpoint' $localJsonFile)
nsx_json=$(echo $nsx_json | jq '. += {"groups_api_endpoint": "'$(echo $groups_api_endpoint)'"}')
#
echo "   +++ Adding groups..."
groups=$(jq -c -r '.groups' $localJsonFile)
nsx_json=$(echo $nsx_json | jq '. += {"groups": '$(echo $groups)'}')
#
echo "   +++ Adding exclusion_list_api_endpoint..."
exclusion_list_api_endpoint=$(jq -c -r '.exclusion_list_api_endpoint' $localJsonFile)
nsx_json=$(echo $nsx_json | jq '. += {"exclusion_list_api_endpoint": "'$(echo $exclusion_list_api_endpoint)'"}')
#
echo "   +++ Adding exclusion_list_groups..."
exclusion_list_groups=$(jq -c -r '.exclusion_list_groups' $localJsonFile)
nsx_json=$(echo $nsx_json | jq '. += {"exclusion_list_groups": '$(echo $exclusion_list_groups)'}')
#
echo "   +++ Adding nsx_manager_name"
nsx_manager_name=$(jq -c -r .nsx_manager_name /nestedVsphere8/02_external_gateway/variables.json)
nsx_json=$(echo $nsx_json | jq '.external_gw += {"nsx_manager_name": "'$(echo $nsx_manager_name)'"}')
#
echo "   +++ Adding edge sizing information..."
if [[ $(jq -c -r '.nsx.config.edge_node.size' $jsonFile | tr '[:upper:]' [:lower:]) == "small" ]] ;  then
  nsx_json=$(echo $nsx_json | jq '.nsx.config.edge_node += {"cpu": 2, "memory": 4, "disk": 200}')
fi
if [[ $(jq -c -r '.nsx.config.edge_node.size' $jsonFile | tr '[:upper:]' [:lower:]) == "medium" ]] ;  then
  nsx_json=$(echo $nsx_json | jq '.nsx.config.edge_node += {"cpu": 4, "memory": 8, "disk": 200}')
fi
if [[ $(jq -c -r '.nsx.config.edge_node.size' $jsonFile | tr '[:upper:]' [:lower:]) == "large" ]] ;  then
  nsx_json=$(echo $nsx_json | jq '.nsx.config.edge_node += {"cpu": 8, "memory": 32, "disk": 200}')
fi
if [[ $(jq -c -r '.nsx.config.edge_node.size' $jsonFile | tr '[:upper:]' [:lower:]) == "extra_large" ]] ;  then
  nsx_json=$(echo $nsx_json | jq '.nsx.config.edge_node += {"cpu": 16, "memory": 64, "disk": 200}')
fi
prefix=$(ip_prefix_by_netmask $(jq -c -r '.vsphere_underlay.networks.vsphere.management.netmask' $jsonFile) "   ++++++")
nsx_json=$(echo $nsx_json | jq '.vsphere_underlay.networks.vsphere.management += {"prefix": "'$(echo $prefix)'"}')
#
echo "   +++ Adding prefix for management network..."
prefix=$(ip_prefix_by_netmask $(jq -c -r '.vsphere_underlay.networks.vsphere.management.netmask' $jsonFile) "   ++++++")
nsx_json=$(echo $nsx_json | jq '.vsphere_underlay.networks.vsphere.management += {"prefix": "'$(echo $prefix)'"}')
#
echo "   +++ Adding prefix for NSX external network..."
prefix=$(ip_prefix_by_netmask $(jq -c -r '.vsphere_underlay.networks.nsx.external.netmask' $jsonFile) "   ++++++")
nsx_json=$(echo $nsx_json | jq '.vsphere_underlay.networks.nsx.external += {"prefix": "'$(echo $prefix)'"}')
#
echo "   +++ Adding nsx networks..."
networks=$(jq -c -r '.networks' /nestedVsphere8/02_external_gateway/variables.json)
nsx_json=$(echo $nsx_json | jq '. += {"nsx_networks": '$(echo $networks)'}')
#
echo "   +++ Adding vsphere networks..."
networks=$(jq -c -r '.networks' /nestedVsphere8/03_nested_vsphere/variables.json)
nsx_json=$(echo $nsx_json | jq '. += {"vsphere_networks": '$(echo $networks)'}')
#
echo "   +++ Adding ip_pools details..."
ip_pools=[]
ip_pool_0=$(jq -c -r '.ip_pools[0]' $localJsonFile)
ip_pool_0=$(echo $ip_pool_0 | jq '. += {"gateway": "'$(jq -c -r .vsphere_underlay.networks.nsx.overlay.nsx_pool.gateway $jsonFile)'"}')
ip_pool_0=$(echo $ip_pool_0 | jq '. += {"start": "'$(jq -c -r .vsphere_underlay.networks.nsx.overlay.nsx_pool.start $jsonFile)'"}')
ip_pool_0=$(echo $ip_pool_0 | jq '. += {"end": "'$(jq -c -r .vsphere_underlay.networks.nsx.overlay.nsx_pool.end $jsonFile)'"}')
ip_pool_0=$(echo $ip_pool_0 | jq '. += {"cidr": "'$(jq -c -r .vsphere_underlay.networks.nsx.overlay.nsx_pool.cidr $jsonFile)'"}')
ip_pools=$(echo $ip_pools | jq '. += ['$(echo $ip_pool_0)']')
ip_pool_1=$(jq -c -r '.ip_pools[1]' $localJsonFile)
ip_pool_1=$(echo $ip_pool_1 | jq '. += {"gateway": "'$(jq -c -r .vsphere_underlay.networks.nsx.overlay_edge.nsx_pool.gateway $jsonFile)'"}')
ip_pool_1=$(echo $ip_pool_1 | jq '. += {"start": "'$(jq -c -r .vsphere_underlay.networks.nsx.overlay_edge.nsx_pool.start $jsonFile)'"}')
ip_pool_1=$(echo $ip_pool_1 | jq '. += {"end": "'$(jq -c -r .vsphere_underlay.networks.nsx.overlay_edge.nsx_pool.end $jsonFile)'"}')
ip_pool_1=$(echo $ip_pool_1 | jq '. += {"cidr": "'$(jq -c -r .vsphere_underlay.networks.nsx.overlay_edge.nsx_pool.cidr $jsonFile)'"}')
ip_pools=$(echo $ip_pools | jq '. += ['$(echo $ip_pool_1)']')
nsx_json=$(echo $nsx_json | jq '.nsx.config.ip_pools += '$(echo $ip_pools | jq -c -r .)'')
#
echo "   +++ Adding uplink_profiles details..."
uplink_profiles=$(jq -c -r '.uplink_profiles' $localJsonFile)
nsx_json=$(echo $nsx_json | jq '.nsx.config += {"uplink_profiles": '$(echo $uplink_profiles | jq -c -r .)'}')
#
echo "   +++ Adding transport_zones details..."
transport_zones=$(jq -c -r '.transport_zones' $localJsonFile)
nsx_json=$(echo $nsx_json | jq '.nsx.config += {"transport_zones": '$(echo $transport_zones | jq -c -r .)'}')
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_vcd" ]]; then
  echo "   +++ Adding segments details..."
  segments=$(jq -c -r '.segments' $localJsonFile)
  nsx_json=$(echo $nsx_json | jq '.nsx.config += {"segments": '$(echo $segments | jq -c -r .)'}')
fi
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_telco" ]]; then
  nsx_segments="[]"
  nsx_segment_external=0
  echo "   +++ Checking NSX external segments..."
  for segment in $(jq -c -r .segments[] $localJsonFile)
  do
    if [[ $(echo $segment | jq -c -r .nsx_external) == true ]] ; then
      ((nsx_segment_external++))
      cidr=$(jq -c -r .vsphere_underlay.networks.nsx_external.cidr $jsonFile)
      echo "   ++++++ Adding CIDR to external segment called $(echo $segment | jq -c -r .name): $(jq -c -r .vsphere_underlay.networks.nsx_external.cidr $jsonFile)"
      new_segment=$(echo $segment | jq '. += {"cidr": "'$(echo $cidr)'"}')
    else
      new_segment=$(echo $segment)
    fi
    if [[ $nsx_segment_external -gt 1 ]] ; then
      echo "   ++++++ERROR++++++ only one segment can be nsx_external network in .nsx.config.segments[] - found: $nsx_segment_external !!"
      exit 255
    fi
    nsx_segments=$(echo $nsx_segments | jq '. += ['$(echo $new_segment)']')
  done
  nsx_json=$(echo $nsx_json | jq '.nsx.config += {"segments": '$(echo $nsx_segments)'}')
fi
#
echo "   +++ Adding transport_node_profiles details..."
transport_node_profiles=$(jq -c -r '.transport_node_profiles' $localJsonFile | jq '.[0].switches[0] += {"name": "'$(jq -c -r .networks.nsx.nsx_overlay.name /root/networks.json)'"}')
nsx_json=$(echo $nsx_json | jq '.nsx.config += {"transport_node_profiles": '$(echo $transport_node_profiles | jq -c -r .)'}')
#
echo "   +++ Adding edge_node details..."
data_network=$(jq -c -r '.edge_node.data_network' $localJsonFile)
nsx_json=$(echo $nsx_json | jq '.nsx.config.edge_node += {"data_network": "'$(echo $data_network)'"}')
#
echo "   +++ Adding edge_node details..."
host_switch_spec=$(jq -c -r '.edge_node.host_switch_spec' $localJsonFile)
nsx_json=$(echo $nsx_json | jq '.nsx.config.edge_node += {"host_switch_spec": '$(echo $host_switch_spec | jq -c -r .)'}')
#
echo "   +++ Adding tier0s details..."
tier0s=[]
ha_mode=$(jq -c -r '.tier0s.ha_mode' $localJsonFile)
for item in $(jq -c -r .nsx.config.tier0s[] $jsonFile)
do
  for edge_cluster in $(jq -c -r .nsx.config.edge_clusters[] $jsonFile)
  do
    interfaces=[]
    ha_vips_interfaces=[]
    if [[ $(echo $item | jq -c -r .edge_cluster_name) == $(echo $edge_cluster | jq -c -r .display_name) ]] ; then
      count=0
      for edge in $(echo $edge_cluster | jq -c -r .members_name[])
      do
        interface="{}"
        interface=$(echo $interface | jq '. += {"edge_name": "'$(echo $edge)'"}')
        interface=$(echo $interface | jq '. += {"segment_name": "'$(jq -c -r '.segments[0].name' $localJsonFile)'"}')
        interface=$(echo $interface | jq '. += {"type": "EXTERNAL"}')
        interface=$(echo $interface | jq '. += {"display_name": "if-ext-'$count'"}')

        interfaces=$(echo $interfaces | jq '. += ['$(echo $interface | jq -c -r .)']')
        ha_vips_interfaces=$(echo $ha_vips_interfaces | jq '. += ["if-ext-'$count'"]')
        ((count++))
      done
    fi
  done
  static_routes=[]
  static_routes=$(echo $static_routes | jq '. += [{"display_name" : "default-route", "network" : "0.0.0.0/0", "next_hops" : [ { "ip_address": "'$(jq -c -r .vsphere_underlay.networks.nsx.external.external_gw_ip $jsonFile)'" } ]}]')
  item=$(echo $item | jq '. += {"ha_mode": "'$(echo $ha_mode)'"}')
  item=$(echo $item | jq '. += {"interfaces": '$(echo $interfaces | jq -c -r .)'}')
  item=$(echo $item | jq '. += {"static_routes": '$(echo $static_routes)'}')
  ha_vips=[]
  ha_vips=$(echo $ha_vips | jq '. += [{"interfaces": '$(echo $ha_vips_interfaces | jq -c -r .)'}]')
  item=$(echo $item | jq '. += {"ha_vips": '$(echo $ha_vips | jq -c -r .)'}')
  #
  if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_telco" ]]; then
    if [[ $(echo $item | jq 'has("bgp")') == "true" ]] ; then
      local_as=$(jq --arg context $(echo $item | jq -c -r .bgp.avi_context_ref) '.avi.config.cloud.contexts[] | select(.name == $context).local_as' $jsonFile)
#      get_value_from_list_when_match  "$(echo $item | jq -c -r .bgp.avi_context_ref)" \
#                                      "name" \
#                                      ".avi.config.cloud.contexts[]" \
#                                      "local_as" \
#                                      "$jsonFile" \
#                                      "   ++++++ Searching for 'local_as' value in '.avi.config.cloud.contexts[]' when 'name' value equals '$(echo $item | jq -c -r .bgp.avi_context_ref)'" \
#                                      "   +++++++++ found 'local_as' value equals to" \
#                                      "   +++++++++ERROR+++++++++ 'local_as' not found"
#      local_as=$value_to_return
      avi_ipam_pool_start=$(jq '.avi.config.cloud.networks[] | select(.bgp == true).avi_ipam_pool' $jsonFile | cut -d"-" -f1)
      vi_ipam_pool_end=$(jq '.avi.config.cloud.networks[] | select(.bgp == true).avi_ipam_pool' $jsonFile | cut -d"-" -f2)
#      get_value_from_list_when_match  "$(jq -c -r '.networks.nsx.nsx_external.port_group_name' /nestedVsphere8/02_external_gateway/variables.json)" \
#                                          "name" \
#                                          ".avi.config.cloud.networks[]" \
#                                          "avi_ipam_pool" \
#                                          "$jsonFile" \
#                                          "   ++++++ Searching for 'avi_ipam_pool' value in '.avi.config.cloud.networks[]' when 'name' value equals '$(jq -c -r '.networks.nsx.nsx_external.port_group_name' /nestedVsphere8/02_external_gateway/variables.json)'" \
#                                          "   +++++++++ found 'avi_ipam_pool' value equals to" \
#                                          "   +++++++++ERROR+++++++++ 'avi_ipam_pool' not found"
#      avi_ipam_pool_start=$(echo $value_to_return | cut -d"-" -f1)
#      avi_ipam_pool_end=$(echo $value_to_return | cut -d"-" -f2)
      neighbors="{\"neighbors\": []}"
      neighbors=$(echo $neighbors | jq -c -r '.neighbors += [{"neighbor_address": "'$(echo $avi_ipam_pool_start)'", "remote_as_num": "'$(echo $local_as)'"}]')
      while [[ $avi_ipam_pool_start != $avi_ipam_pool_end ]]
      do
        avi_ipam_pool_start=$(nextip $avi_ipam_pool_start)
        neighbors=$(echo $neighbors | jq -c -r '.neighbors += [{"neighbor_address": "'$(echo $avi_ipam_pool_start)'", "remote_as_num": "'$(echo $local_as)'"}]')
      done
      item=$(echo $item | jq -c -r '.bgp += '$(echo $neighbors | jq -c -r)'')
      tiers0=$(echo $tiers0 | jq '. += ['$(echo $item)']')
    else
      tiers0=$(echo $tiers0 | jq '. += ['$(echo $tier0)']')
    fi
  fi
  tier0s=$(echo $tier0s | jq '. += ['$(echo $item | jq -c -r .)']')
done
nsx_json=$(echo $nsx_json | jq '. | del (.nsx.config.tier0s)')
nsx_json=$(echo $nsx_json | jq '.nsx.config += {"tier0s": '$(echo $tier0s | jq -c -r .)'}')
#
echo "   +++ Adding tier1s details..."
tier1s=[]
route_advertisement_types=$(jq -c -r '.tier1s.route_advertisement_types' $localJsonFile)
for item in $(jq -c -r .nsx.config.tier1s[] $jsonFile)
do
  item=$(echo $item | jq '. += {"route_advertisement_types": '$(echo $route_advertisement_types | jq -c -r .)'}')
  item=$(echo $item | jq '. += {"dhcp_server": "'$(jq -c -r .dhcp_servers[0].name $localJsonFile)'"}')
  tier1s=$(echo $tier1s | jq '. += ['$(echo $item | jq -c -r .)']')
done
nsx_json=$(echo $nsx_json | jq '. | del (.nsx.config.tier1s)')
nsx_json=$(echo $nsx_json | jq '.nsx.config += {"tier1s": '$(echo $tier1s | jq -c -r .)'}')
#
echo "   +++ Adding .nsx.config.segments_overlay[].transport_zone..."
segments_overlay=[]
for item in $(jq -c -r .nsx.config.segments_overlay[] $jsonFile)
do
  item=$(echo $item | jq '. += {"transport_zone": "'$(jq -c -r '.transport_zones[0].name' $localJsonFile)'"}')
  segments_overlay=$(echo $segments_overlay | jq '. += ['$(echo $item | jq -c -r .)']')
done
nsx_json=$(echo $nsx_json | jq '. | del (.nsx.config.segments_overlay)')
nsx_json=$(echo $nsx_json | jq '.nsx.config += {"segments_overlay": '$(echo $segments_overlay | jq -c -r .)'}')
#
echo $nsx_json | jq . | tee /root/nsx.json > /dev/null
#
echo ""
echo "==> Downloading NSX ova file"
if [ -s "$(jq -c -r .nsx_ova_path $localJsonFile)" ]; then echo "   +++ NSX ova file $(jq -c -r .nsx_ova_path $localJsonFile) is not empty" ; else curl -s -o $(jq -c -r .nsx_ova_path $localJsonFile) $(jq -c -r .nsx.ova_url $jsonFile) ; fi
if [ -s "$(jq -c -r .nsx_ova_path $localJsonFile)" ]; then echo "   +++ NSX ova file $(jq -c -r .nsx_ova_path $localJsonFile) is not empty" ; else echo "   +++ NSX ova $(jq -c -r .nsx_ova_path $localJsonFile) is empty" ; exit 255 ; fi
