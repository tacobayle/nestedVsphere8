#!/bin/bash
#
jsonFile="/root/variables.json"
localJsonFile="/nestedVsphere8/07_nsx_alb/variables.json"
source /nestedVsphere8/bash/ip.sh
source /nestedVsphere8/bash/download_file.sh
#
IFS=$'\n'
#
echo ""
echo "==> Creating /root/avi.json file..."
rm -f /root/avi.json
avi_json=$(jq -c -r . $jsonFile | jq .)
#
seg_list="[]"
for seg in $(jq -c -r .avi.config.cloud.service_engine_groups[] $jsonFile)
do
  echo "   +++ add vcenter_folder in Service Engine Group called $(echo $seg | jq -c -r .name)"
  seg=$(echo $seg | jq '. += {"vcenter_folder": "'$(jq -c -r .seg_folder_basename /nestedVsphere8/07_nsx_alb/variables.json)'-'$(echo $seg | jq -c -r .name)'"}')
  seg_list=$(echo $seg_list | jq '. += ['$(echo $seg | jq -c -r .)']')
done
#
echo "   +++ alb_controller_name"
alb_controller_name=$(jq -c -r .alb_controller_name /nestedVsphere8/02_external_gateway/variables.json)
avi_json=$(echo $avi_json | jq '.external_gw += {"alb_controller_name": "'$(echo $alb_controller_name)'"}')
#
echo "   +++ seg_folder_basename"
seg_folder_basename=$(jq -c -r .seg_folder_basename /nestedVsphere8/07_nsx_alb/variables.json)
avi_json=$(echo $avi_json | jq '.avi.config += {"seg_folder_basename": "'$(echo $seg_folder_basename)'"}')
#
echo "   +++ Adding avi.config.avi_config_repo..."
avi_config_repo=$(jq -c -r '.avi_config_repo' $localJsonFile)
avi_json=$(echo $avi_json | jq '.avi.config += {"avi_config_repo": "'$(echo $avi_config_repo)'"}')
#
echo "   +++ Adding avi_ova_path..."
avi_ova_path=$(jq -c -r '.avi_ova_path' $localJsonFile)
avi_json=$(echo $avi_json | jq '. += {"avi_ova_path": "'$(echo $avi_ova_path)'"}')
#
echo "   +++ Adding nsx_alb_se_cl..."
nsx_alb_se_cl=$(jq -c -r '.nsx_alb_se_cl' $localJsonFile)
avi_json=$(echo $avi_json | jq '. += {"nsx_alb_se_cl": "'$(echo $nsx_alb_se_cl)'"}')
#
echo "   +++ Adding avi_port_group..."
avi_port_group=$(jq -c -r '.networks.vsphere.management.port_group_name' /nestedVsphere8/03_nested_vsphere/variables.json)
avi_json=$(echo $avi_json | jq '. += {"avi_port_group": "'$(echo $avi_port_group)'"}')
#
if [[ $(jq -c -r .avi.config.tenants $jsonFile) == "null" ]]; then
  echo "   +++ Adding avi.config.tenants... as an empty list"
  avi_json=$(echo $avi_json | jq '.avi.config += {"tenants": []}')
fi
#
if [[ $(jq -c -r .avi.config.users $jsonFile) == "null" ]]; then
  echo "   +++ Adding avi.config.users... as an empty list"
  avi_json=$(echo $avi_json | jq '.avi.config += {"users": []}')
fi
#
echo "   +++ Adding dhcp_enabled on .avi.config.cloud"
dhcp_enabled=$(jq -c -r '.dhcp_enabled_default' $localJsonFile)
avi_json=$(echo $avi_json | jq '.avi.config.cloud += {"dhcp_enabled": "'$(echo $dhcp_enabled)'"}')
#
# ALB with NSX-T cloud use cases
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_tanzu_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_vcd" ]]; then
  #
  if grep -q "nsx_password" /nestedVsphere8/10_nsx_alb_config/variables.tf ; then
    echo "   +++ variable nsx_password is already in /nestedVsphere8/10_nsx_alb_config/variables.tf"
  else
    echo "   +++ Adding variable nsx_password in /nestedVsphere8/10_nsx_alb_config/variables.tf"
    echo 'variable "nsx_password" {}' | tee -a /nestedVsphere8/10_nsx_alb_config/variables.tf > /dev/null
  fi
  #
  if grep -q "transport_zone" /nestedVsphere8/10_nsx_alb_config/variables.tf ; then
    echo "   +++ variable transport_zone is already in /nestedVsphere8/10_nsx_alb_config/variables.tf"
  else
    echo "   +++ Adding variable transport_zone in /nestedVsphere8/10_nsx_alb_config/variables.tf"
    echo 'variable "transport_zone" {}' | tee -a /nestedVsphere8/10_nsx_alb_config/variables.tf > /dev/null
  fi
  #
  mv /nestedVsphere8/10_nsx_alb_config/ansible_avi_nsx.tf.disabled /nestedVsphere8/10_nsx_alb_config/ansible_avi_nsx.tf
  mv /nestedVsphere8/10_nsx_alb_config/ansible_avi_vcenter.tf /nestedVsphere8/10_nsx_alb_config/ansible_avi_vcenter.tf..disabled
  #
  echo "   +++ Adding avi.config.cloud.name..."
  avi_json=$(echo $avi_json | jq '.avi.config.cloud += {"name": "'$(jq -c -r '.nsx_default_cloud_name' $localJsonFile)'"}')
  #
  echo "   +++ Adding avi.config.avi_config_tag..."
  avi_config_tag=$(jq -c -r '.avi_config_tag_nsx_cloud' $localJsonFile)
  avi_json=$(echo $avi_json | jq '.avi.config += {"avi_config_tag": "'$(echo $avi_config_tag)'"}')
  #
  echo "   +++ Adding avi.config.playbook..."
  playbook_env_nsx_cloud=$(jq -c -r '.playbook_env_nsx_cloud' $localJsonFile)
  avi_json=$(echo $avi_json | jq '.avi.config += {"playbook": "'$(echo $playbook_env_nsx_cloud)'"}')
  #
  echo "   +++ Adding transport_zone details..."
  transport_zone=$(jq -c -r '.transport_zones[0].name' /nestedVsphere8/05_nsx_manager/variables.json)
  avi_json=$(echo $avi_json | jq '. += {"transport_zone": "'$(echo $transport_zone)'"}')
  #
  if [[ $(jq -c -r '.nsx.config.segments_overlay | length' $jsonFile) -gt 0 ]] ; then
    echo "   +++ Creating External routes to subnet overlay segments..."
    static_routes="[]"
    count=0
    for segment in $(jq -c -r .nsx.config.segments_overlay[] $jsonFile)
    do
      static_routes=$(echo $static_routes | jq '. += [{"prefix": "'$(echo $segment | jq -c -r .cidr)'", "next_hop": "'$(jq -c -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile)'", "if_name": "'$(jq -c -r .nsx_alb_controller_if_name $localJsonFile)'", "route_id": "'$(echo $count)'"}]')
      ((count++))
      #
      if [[ $(echo $segment | jq -c -r .k8s_clusters) != "null" ]] ; then
        for cluster in $(echo $segment | jq -c -r .k8s_clusters[])
        do
          echo "   +++ Updating avi.config.cloud.service_engine_groups for unmanaged k8s cluster(s)..."
          seg_list=$(echo $seg_list | jq '. += [{"name": "'$(echo $cluster | jq -c -r .cluster_name)'", "vcenter_folder": "'$(jq -c -r .seg_folder_basename /nestedVsphere8/07_nsx_alb/variables.json)'-'$(echo $cluster | jq -c -r .cluster_name)'", "ha_mode": "HA_MODE_SHARED_PAIR", "min_scaleout_per_vs": 2, "buffer_se": 0, "extra_shared_config_memory": 0, "vcpus_per_se": 2, "memory_per_se": 2048, "disk_per_se": 25, "realtime_se_metrics": {"enabled": true,"duration": 0}}]')
        done
      fi
      #
    done
    avi_json=$(echo $avi_json | jq '.avi.config += {"static_routes": '$(echo $static_routes)'}')
  fi
  #
  # .avi.config.cloud.network_management
  echo "   +++ Checking Avi Cloud networks settings"
  for segment in $(jq -c -r .nsx.config.segments_overlay[] $jsonFile)
  do
    if [[ $(echo $segment | jq -r .display_name) == $(jq -c -r .avi.config.cloud.network_management.name $jsonFile) ]] ; then
      tier1=$(echo $segment | jq -r .tier1)
    fi
  done
  network_management=$(echo $(jq -c -r .avi.config.cloud.network_management $jsonFile) | jq '. += {"tier1": "'$(echo $tier1)'"}')
  avi_json=$(echo $avi_json | jq '. | del (.avi.config.cloud.network_management)')
  avi_json=$(echo $avi_json | jq '.avi.config.cloud += {"network_management": '$(echo $network_management)'}')
  # .avi.config.cloud.networks_data[]
  networks_data="[]"
  for network in $(jq -c -r .avi.config.cloud.networks_data[] $jsonFile)
  do
    for segment in $(jq -c -r .nsx.config.segments_overlay[] $jsonFile)
    do
      if [[ $(echo $segment | jq -r .display_name) == $(echo $network | jq -c -r .name) ]] ; then
        tier1=$(echo $segment | jq -r .tier1)
      fi
    done
    network_data=$(echo $network | jq '. += {"tier1": "'$(echo $tier1)'"}')
    networks_data=$(echo $networks_data | jq '. += ['$(echo $network_data)']')
  done
  avi_json=$(echo $avi_json | jq '. | del (.avi.config.cloud.networks_data)')
  avi_json=$(echo $avi_json | jq '.avi.config.cloud += {"networks_data": '$(echo $networks_data)'}')
  #
  echo "   +++ Creating Avi pools and VS"
  avi_pools="[]"
  avi_virtual_services_http="[]"
  count=1
  for item in $(jq -c -r .nsx.config.segments_overlay[] $jsonFile)
  do
    if [[ $(echo $item | jq -c .app_ips) != "null" ]] ; then
      if [[ $count -eq 1 ]] ; then
        type="nsx-group-based"
        pool_name=$(jq -c -r '.app.nsxt_group_name' /nestedVsphere8/08_app/variables.json)
        tier1=$(echo $item | jq -c -r .tier1)
        default_server_port=$(jq -c -r '.app.hello_world_app_tcp_port' /nestedVsphere8/08_app/variables.json)
        avi_pool="{\"name\": \"$(echo $pool_name)\", \"tier1\": \"$(echo $tier1)\", \"default_server_port\": $(echo $default_server_port), \"type\": \"$(echo $type)\"}"
        avi_pools=$(echo $avi_pools | jq '. += ['$(echo $avi_pool)']')
        vs_name="app$count-hello-world-nsx-group"
        for network_data in $(jq -c -r .avi.config.cloud.networks_data[] $jsonFile)
        do
          for segment_data in $(jq -c -r .nsx.config.segments_overlay[] $jsonFile)
          do
            if [[ $(echo $network_data | jq -c .name) == $(echo $segment_data | jq -c .display_name) ]] ; then
              tier1_segment_data=$(echo $segment_data | jq -c -r  .tier1)
              if [[ $tier1_segment_data == $tier1 ]] ; then
                segment_name=$(echo $segment_data | jq -c -r .display_name)
              fi
            fi
          done
        done
        avi_virtual_service_http="{\"name\": \"$(echo $vs_name)\", \"network_ref\": \"$(echo $segment_name)\", \"pool_ref\": \"$(echo $pool_name)\", \"se_group_ref\": \"Default-Group\", \"services\": [{\"port\": 80, \"enable_ssl\": false}, {\"port\": 443, \"enable_ssl\": true}]}"
        avi_virtual_services_http=$(echo $avi_virtual_services_http | jq '. += ['$(echo $avi_virtual_service_http)']')
        ((count++))
      fi
      tier1=$(echo $item | jq -c -r .tier1)
      avi_app_server_ips=$(echo $item | jq -c -r .app_ips)
      #
      pool_name="pool$count-hello"
      default_server_port=$(jq -c -r '.app.hello_world_app_tcp_port' /nestedVsphere8/08_app/variables.json)
      type="ip-based"
      avi_pool="{\"name\": \"$(echo $pool_name)\", \"tier1\": \"$(echo $tier1)\", \"default_server_port\": $(echo $default_server_port), \"type\": \"$(echo $type)\", \"avi_app_server_ips\": $(echo $avi_app_server_ips)}"
      avi_pools=$(echo $avi_pools | jq '. += ['$(echo $avi_pool)']')
      vs_name="app$count-hello-world"
      for network_data in $(jq -c -r .avi.config.cloud.networks_data[] $jsonFile)
      do
        for segment_data in $(jq -c -r .nsx.config.segments_overlay[] $jsonFile)
        do
          if [[ $(echo $network_data | jq -c .name) == $(echo $segment_data | jq -c .display_name) ]] ; then
            tier1_segment_data=$(echo $segment_data | jq -c -r  .tier1)
            if [[ $tier1_segment_data == $tier1 ]] ; then
              segment_name=$(echo $segment_data | jq -c -r .display_name)
            fi
          fi
        done
      done
      avi_virtual_service_http="{\"name\": \"$(echo $vs_name)\", \"network_ref\": \"$(echo $segment_name)\", \"pool_ref\": \"$(echo $pool_name)\", \"se_group_ref\": \"Default-Group\", \"services\": [{\"port\": 80, \"enable_ssl\": false}, {\"port\": 443, \"enable_ssl\": true}]}"
      avi_virtual_services_http=$(echo $avi_virtual_services_http | jq '. += ['$(echo $avi_virtual_service_http)']')
      ((count++))
      pool_name="pool$count-avi"
      default_server_port=$(jq -c -r '.app.avi_app_tcp_port' /nestedVsphere8/08_app/variables.json)
      avi_pool="{\"name\": \"$(echo $pool_name)\", \"tier1\": \"$(echo $tier1)\", \"default_server_port\": $(echo $default_server_port), \"type\": \"$(echo $type)\", \"avi_app_server_ips\": $(echo $avi_app_server_ips)}"
      avi_pools=$(echo $avi_pools | jq '. += ['$(echo $avi_pool)']')
      vs_name="app$count-avi"
      for network_data in $(jq -c -r .avi.config.cloud.networks_data[] $jsonFile)
      do
        for segment_data in $(jq -c -r .nsx.config.segments_overlay[] $jsonFile)
        do
          if [[ $(echo $network_data | jq -c .name) == $(echo $segment_data | jq -c .display_name) ]] ; then
            tier1_segment_data=$(echo $segment_data | jq -c -r  .tier1)
            if [[ $tier1_segment_data == $tier1 ]] ; then
              segment_name=$(echo $segment_data | jq -c -r .display_name)
            fi
          fi
        done
      done
      avi_virtual_service_http="{\"name\": \"$(echo $vs_name)\", \"network_ref\": \"$(echo $segment_name)\", \"pool_ref\": \"$(echo $pool_name)\", \"se_group_ref\": \"Default-Group\", \"services\": [{\"port\": 80, \"enable_ssl\": false}, {\"port\": 443, \"enable_ssl\": true}]}"
      avi_virtual_services_http=$(echo $avi_virtual_services_http | jq '. += ['$(echo $avi_virtual_service_http)']')
      ((count++))
      #
      pool_name="pool$count-waf"
      default_server_port=$(jq -c -r '.app.hackazon_tcp_port' /nestedVsphere8/08_app/variables.json)
      avi_pool="{\"name\": \"$(echo $pool_name)\", \"tier1\": \"$(echo $tier1)\", \"default_server_port\": $(echo $default_server_port), \"type\": \"$(echo $type)\", \"avi_app_server_ips\": $(echo $avi_app_server_ips)}"
      avi_pools=$(echo $avi_pools | jq '. += ['$(echo $avi_pool)']')
      vs_name="app$count-waf"
      for network_data in $(jq -c -r .avi.config.cloud.networks_data[] $jsonFile)
      do
        for segment_data in $(jq -c -r .nsx.config.segments_overlay[] $jsonFile)
        do
          if [[ $(echo $network_data | jq -c .name) == $(echo $segment_data | jq -c .display_name) ]] ; then
            tier1_segment_data=$(echo $segment_data | jq -c -r  .tier1)
            if [[ $tier1_segment_data == $tier1 ]] ; then
              segment_name=$(echo $segment_data | jq -c -r .display_name)
            fi
          fi
        done
      done
      avi_virtual_service_http="{\"name\": \"$(echo $vs_name)\", \"network_ref\": \"$(echo $segment_name)\", \"pool_ref\": \"$(echo $pool_name)\", \"se_group_ref\": \"Default-Group\", \"services\": [{\"port\": 80, \"enable_ssl\": false}, {\"port\": 443, \"enable_ssl\": true}]}"
      avi_virtual_services_http=$(echo $avi_virtual_services_http | jq '. += ['$(echo $avi_virtual_service_http)']')
      ((count++))
    fi
  done
  if [[ $(echo $avi_pools | jq '. | length') -gt 0 ]] ; then
    avi_json=$(echo $avi_json | jq '.avi.config.cloud += {"pools": '$(echo $avi_pools)'}')
    avi_json=$(echo $avi_json | jq '.avi.config.cloud.virtual_services += {"http": '$(echo $avi_virtual_services_http)'}')
  fi
  #
  if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_tanzu_alb" ]] ; then
    echo "   +++ Updating dhcp_enabled on .avi.config.cloud"
    dhcp_enabled=$(jq -c -r '.dhcp_enabled_if_vsphere_nsx_tanzu_alb' $localJsonFile)
    avi_json=$(echo $avi_json | jq '. | del (.avi.config.cloud.dhcp_enabled)')
    avi_json=$(echo $avi_json | jq '.avi.config.cloud += {"dhcp_enabled": "'$(echo $dhcp_enabled)'"}')
  fi
fi
#
# ALB with vCenter Cloud use cases
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_alb_wo_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_tanzu_alb_wo_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_telco" ]]; then
  #
  echo "   +++ Adding avi.config.avi_config_tag..."
  avi_config_tag=$(jq -c -r '.avi_config_tag_vcenter_cloud' $localJsonFile)
  avi_json=$(echo $avi_json | jq '.avi.config += {"avi_config_tag": "'$(echo $avi_config_tag)'"}')
  #
  echo "   +++ Adding avi.config.playbook..."
  playbook_env_vcenter_cloud=$(jq -c -r '.playbook_env_vcenter_cloud' $localJsonFile)
  avi_json=$(echo $avi_json | jq '.avi.config += {"playbook": "'$(echo $playbook_env_vcenter_cloud)'"}')
  #
  echo "   +++ Adding avi.config.cloud.name..."
  avi_json=$(echo $avi_json | jq '.avi.config.cloud += {"name": "'$(jq -c -r '.vcenter_default_cloud_name' $localJsonFile)'"}')
  #
  # Avi Telco use case
  #
  if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_telco" ]]; then
    #
    # .avi.config.tenants
    #
    avi_json=$(echo $avi_json | jq '. | del (.avi.config.tenants)')
    tenants=[]
    for cluster in $(jq -c -r .tkg.clusters.workloads[] $jsonFile)
    do
      name=$(echo $cluster | jq -c -r .name)
      echo "   +++ adding tenant called ${name} for TKG workload clusters"
      tenants=$(echo $tenants | jq -c -r '. += [{"name": "'${name}'",
                                                   "local": true,
                                                   "config_settings" : {
                                                     "tenant_vrf": false,
                                                     "se_in_provider_context": true,
                                                     "tenant_access_to_provider_se": true
                                                   }
                                                 }]')
    done
    avi_json=$(echo $avi_json | jq '.avi.config += {"tenants": '$(echo $tenants)'}')
    #
    # .avi.config.users
    #
    avi_json=$(echo $avi_json | jq '. | del (.avi.config.users)')
    users=[]
    users=$(echo $users | jq -c -r '. += [{"access": [
                                            {
                                              "role_ref": "/api/role?name=System-Admin",
                                              "tenant_ref": "/api/tenant?name=admin",
                                              "all_tenants": false
                                            }
                                           ],
                                           "username": "'$(jq -r .tkgm_user $localJsonFile)'",
                                           "name": "'$(jq -r .tkgm_user $localJsonFile)'",
                                           "is_superuser": true,
                                           "default_tenant_ref": "/api/tenant?name=admin",
                                           "user_profile_ref": "/api/useraccountprofile?name=Default-User-Account-Profile"
                                          }]')
    avi_json=$(echo $avi_json | jq '.avi.config += {"users": '$(echo $users)'}')
    #
    # .avi.config.cloud.networks_data[]
    #
    networks_data="[]"
    ipam_networks="[]"
    avi_pools="[]"
    for network_data in $(jq -c -r .avi.config.cloud.networks[] $jsonFile)
    do
      network_data=$(echo $network_data | jq '. += {"dhcp_enabled": "'$(jq -r .networks_data_default.dhcp_enabled $localJsonFile)'"}')
      network_data=$(echo $network_data | jq '. += {"exclude_discovered_subnets": "'$(jq -r .networks_data_default.exclude_discovered_subnets $localJsonFile)'"}')
      network_data=$(echo $network_data | jq '. += {"type": "'$(jq -r .networks_data_default.type $localJsonFile)'"}')
      if [[ $(echo $network_data | jq -c -r .external) == false ]] ; then
        cidr=$(jq -r --arg network_name "$(echo $network_data | jq -c -r .name)" '.nsx.config.segments_overlay[] | select(.display_name == $network_name).cidr' $jsonFile)
        ipam_networks=$(echo $ipam_networks | jq '. += ["'$(echo $network_data | jq -r '.name')'"]')
        if [[ $(echo $network_data | jq -c -r .management) == true ]] ; then
          avi_json=$(echo $avi_json | jq '.vsphere_underlay.networks += {"alb": {"se": { "external_gw_ip": "'$(nextip $(echo $cidr | cut -d"/" -f1 ))'"}}}')
        fi
      fi
      if [[ $(echo $network_data | jq -c -r .external) == true ]] ; then
        cidr=$(jq -r -c .vsphere_underlay.networks.nsx.external.cidr $jsonFile)
        network_data=$(echo $network_data | jq '. | del (.name)')
        network_data=$(echo $network_data | jq '. += {"name": "'$(jq -r .networks.nsx.nsx_external.port_group_name /nestedVsphere8/02_external_gateway/variables.json)'"}')
        ipam_networks=$(echo $ipam_networks | jq '. += ["'$(jq -r .networks.nsx.nsx_external.port_group_name /nestedVsphere8/02_external_gateway/variables.json)'"]')
      fi
      if [ -z "$cidr" ] ; then echo "   +++ variable cidr is empty" ; exit 255 ; fi
      network_data=$(echo $network_data | jq '. += {"cidr": "'${cidr}'"}')
      networks_data=$(echo $networks_data | jq '. += ['$(echo $network_data)']')
    done
    avi_json=$(echo $avi_json | jq '.avi.config.cloud += {"ipam": {"networks": '$(echo $ipam_networks)'}}')
    avi_json=$(echo $avi_json | jq '.avi.config.cloud += {"pools": '$(echo $avi_pools)'}')
    avi_json=$(echo $avi_json | jq '. | del (.avi.config.cloud.networks)')
    avi_json=$(echo $avi_json | jq '.avi.config.cloud += {"networks": '$(echo $networks_data)'}')
    #
    # .avi.config.cloud.additional_subnets // rewriting additional_subnets to feed proper Avi formatting
    #
    avi_json=$(echo $avi_json | jq '. | del (.avi.config.cloud.additional_subnets)')
    additional_subnets="[]"
    for network in $(jq -c -r '.avi.config.cloud.additional_subnets[]' $jsonFile)
    do
      configured_subnets="[]"
      for subnet in $(echo $network | jq -c -r .subnets[])
      do
        configured_subnets=$(echo $configured_subnets | jq -c -r '. +=  [
                                                                          {
                                                                            "prefix":
                                                                                      {
                                                                                        "mask": "'$(echo $subnet | jq -c -r .cidr | cut -d"/" -f2 )'",
                                                                                        "ip_addr":
                                                                                          {
                                                                                            "type": "'$(echo $subnet | jq -c -r .type )'",
                                                                                            "addr": "'$(echo $subnet | jq -c -r .cidr | cut -d"/" -f1 )'"
                                                                                          },
                                                                                      },
                                                                            "static_ip_ranges":
                                                                              [
                                                                                {
                                                                                  "range":
                                                                                    {
                                                                                      "begin":
                                                                                        {
                                                                                          "type": "'$(echo $subnet | jq -c -r .type )'",
                                                                                          "addr": "'$(echo $subnet | jq -c -r .range | cut -d"-" -f1 )'"
                                                                                        },
                                                                                        "end":
                                                                                          {
                                                                                            "type": "'$(echo $subnet | jq -c -r .type )'",
                                                                                            "addr": "'$(echo $subnet | jq -c -r .range | cut -d"-" -f2 )'"
                                                                                          }
                                                                                    },
                                                                                  "type": "'$(echo $subnet | jq -c -r .range_type )'"
                                                                                }
                                                                              ]
                                                                          }
                                                                        ]')
      done
      if [[ $(jq -c -r --arg arg_name "$(echo $network | jq -c -r .name_ref)" '.avi.config.cloud.networks[] | select(.name == $arg_name).external' $jsonFile) == true ]] ; then
        additional_subnets=$(echo $additional_subnets | jq -c -r '. +=  [ {"name_ref": "'$(jq -r .networks.nsx.nsx_external.port_group_name /nestedVsphere8/02_external_gateway/variables.json)'", "configured_subnets": '$(echo $configured_subnets)'}]')
      else
        additional_subnets=$(echo $additional_subnets | jq -c -r '. +=  [ {"name_ref": "'$(echo $network | jq -c -r .name_ref )'", "configured_subnets": '$(echo $configured_subnets)'}]')
      fi
    done
    avi_json=$(echo $avi_json | jq '.avi.config.cloud.additional_subnets += '$(echo $additional_subnets | jq -c -r)'')
    #
    # .avi.config.cloud.contexts
    #
    ip_if_edge_index=0
    peers="[]"
    network_ref_bgp=$(jq -c -r '.avi.config.cloud.networks[] | select(.external == true).name' $jsonFile)
    network_ref_bgp_addr=$(jq -c -r .vsphere_underlay.networks.nsx.external.cidr $jsonFile | cut -d"/" -f1)
    network_ref_bgp_mask=$(jq -c -r .vsphere_underlay.networks.nsx.external.cidr $jsonFile | cut -d"/" -f2)
    for tier0 in $(jq -c -r .nsx.config.tier0s[] /root/nsx.json)
    do
      if [[ $(echo $tier0 | jq 'has("bgp")') == "true" ]] ; then
        remote_as=$(echo $tier0 | jq -c -r .bgp.local_as_num)
        label=$(echo $tier0 | jq -c -r .bgp.avi_peer_label)
        contexts="[]"
        for context in $(jq -c -r '.avi.config.cloud.contexts[]' $jsonFile)
        do
          for interface in $(echo $tier0 | jq -c -r '.interfaces[]')
          do
            peer_ip_addr=$(jq -c -r '.vsphere_underlay.networks.nsx.external.tier0_ips['$ip_if_edge_index']' $jsonFile)
            peers=$(echo $peers | jq -c -r '. += [{"advertise_snat_ip": true,
                                                  "advertise_vip": true,
                                                  "advertisement_interval": 5,
                                                  "bfd": false,
                                                  "connect_timer": 10,
                                                  "ebgp_multihop": 0,
                                                  "label": "'${label}'",
                                                  "network_ref": "/api/network/?name='${network_ref_bgp}'",
                                                  "peer_ip": {"addr": "'${peer_ip_addr}'", "type": "V4"},
                                                  "remote_as": "'${remote_as}'",
                                                  "shutdown": false,
                                                  "subnet": {"ip_addr": {"addr": "'${network_ref_bgp_addr}'","type": "V4"}, "mask": "'${network_ref_bgp_mask}'"}
                                                  }]')
            ((ip_if_edge_index++))
          done
          context=$(echo $context | jq '.peers += '$(echo $peers)'')
          contexts=$(echo $contexts | jq '. += ['$(echo $context)']')
        done
      else
        ip_if_edge_index=$((ip_if_edge_index+$(echo $tier0 | jq -c -r '.interfaces | length')))
      fi
    done
    avi_json=$(echo $avi_json | jq '. | del (.avi.config.contexts)')
    avi_json=$(echo $avi_json | jq '.avi.config.cloud += {"contexts": '$(echo $contexts | jq -c -r)})
    #
    # .avi.config.cloud.service_engine_groups // adding service engine group for tkg workload clusters
    #
    for cluster in $(jq -c -r .tkg.clusters.workloads[] $jsonFile)
    do
      name=$(echo $cluster | jq -c -r .name)
      echo "   +++ adding Service Engine Group called ${name} for TKG workload clusters"
      seg_list=$(echo $seg_list | jq -c -r '. += [{"name": "'${name}'",
                                                                             "ha_mode": "HA_MODE_SHARED",
                                                                             "min_scaleout_per_vs": 2,
                                                                             "buffer_se": 0,
                                                                             "vcenter_folder": "'$(jq -c -r .seg_folder_basename /nestedVsphere8/07_nsx_alb/variables.json)'-'${name}'",
                                                                             "extra_shared_config_memory": 0,
                                                                             "vcpus_per_se": 2,
                                                                             "memory_per_se": 2048,
                                                                             "disk_per_se": 25,
                                                                             "realtime_se_metrics": {
                                                                               "enabled": true,
                                                                               "duration": 0
                                                                             }
                                                                            }]')
    done
    #
    # .avi.config.cloud.virtual_services
    #
    avi_json=$(echo $avi_json | jq '. | del (.avi.config.cloud.virtual_services.http)')
    avi_json=$(echo $avi_json | jq '.avi.config.cloud.virtual_services += {"http" : []}')
    avi_dns_vs=[]
    for vs in $(jq -c -r .avi.config.cloud.virtual_services.dns[] $jsonFile)
    do
      cidr=$(echo $avi_json | jq -c -r --arg network_name "$(echo $vs | jq -r .network_ref)" '.avi.config.cloud.networks[] | select(.name == $network_name).cidr')
      type=$(echo $avi_json | jq -c -r --arg network_name "$(echo $vs | jq -r .network_ref)" '.avi.config.cloud.networks[] | select(.name == $network_name).type')
      new_vs_dns=$(echo $vs | jq '. += {"cidr": "'$(echo $cidr)'", "type": "'$(echo $type)'", "services": [{"port": 53}]}')
      avi_dns_vs=$(echo $avi_dns_vs | jq '. += ['$(echo $new_vs_dns)']')
    done
    echo "   +++ Updating .avi.config.cloud.virtual_services..."
    avi_json=$(echo $avi_json | jq '.avi.config.cloud.virtual_services += {"dns": '$(echo $avi_dns_vs)'}')
  fi
  #
  # Avi wo NSX use cases
  #
  if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_alb_wo_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_tanzu_alb_wo_nsx" ]]; then
    alb_networks='["se", "backend", "vip", "tanzu"]'
    ipam_networks="[]"
    networks="[]"
    #
    echo "   +++ Creating Avi pools and VS"
    avi_pools="[]"
    avi_virtual_services_http="[]"
    avi_virtual_services_dns="[]"
    count=1
    #
    for network in $(echo $alb_networks | jq -c -r .[])
    do
      ipam_networks=$(echo $ipam_networks | jq '. += ["'$(jq -c -r .networks.alb.$network.port_group_name /nestedVsphere8/02_external_gateway/variables.json)'"]')
      avi_ipam_pool=$(jq -c -r '.vsphere_underlay.networks.alb.'$network'.avi_ipam_pool' $jsonFile)
      cidr=$(jq -c -r '.vsphere_underlay.networks.alb.'$network'.cidr' $jsonFile)
      dhcp_enabled="false"
      exclude_discovered_subnets="true"
      if [[ $network == "se" ]] ; then management="true" ; else management="false" ; fi
      name=$(jq -c -r .networks.alb.$network.port_group_name /nestedVsphere8/02_external_gateway/variables.json)
      type="V4"
      networks=$(echo $networks | jq '. += [{"avi_ipam_pool": "'$(echo $avi_ipam_pool)'", "cidr": "'$(echo $cidr)'", "dhcp_enabled": '$(echo $dhcp_enabled)', "exclude_discovered_subnets": '$(echo $exclude_discovered_subnets)', "management": '$(echo $management)', "name": "'$(echo $name)'", "type": "'$(echo $type)'"}]')
      #
      if [[ $(jq -c -r .vsphere_underlay.networks.alb.$network.k8s_clusters $jsonFile) != "null" ]]; then
        for cluster in $(jq -c -r .vsphere_underlay.networks.alb.$network.k8s_clusters[] $jsonFile)
          do
            echo "   +++ Updating avi.config.cloud.service_engine_groups for unmanaged k8s cluster(s)..."
            seg_list=$(echo $seg_list | jq '. += [{"name": "'$(echo $cluster | jq -c -r .cluster_name)'", "vcenter_folder": "'$(jq -c -r .seg_folder_basename /nestedVsphere8/07_nsx_alb/variables.json)'-'$(echo $cluster | jq -c -r .cluster_name)'", "ha_mode": "HA_MODE_SHARED_PAIR", "min_scaleout_per_vs": 2, "buffer_se": 0, "extra_shared_config_memory": 0, "vcpus_per_se": 2, "memory_per_se": 2048, "disk_per_se": 25, "realtime_se_metrics": {"enabled": true,"duration": 0}}]')
          done
      fi
      #
      if [[ $(jq -c -r  '.vsphere_underlay.networks.alb.'$network'.app_ips' $jsonFile) != "null" ]] ; then
        type="V4"
        pool_name="pool$count-hello"
        default_server_port=$(jq -c -r '.app.hello_world_app_tcp_port' /nestedVsphere8/08_app/variables.json)
        avi_pool="{\"name\": \"$(echo $pool_name)\", \"default_server_port\": $(echo $default_server_port), \"type\": \"$(echo $type)\", \"avi_app_server_ips\": $(jq -c -r  '.vsphere_underlay.networks.alb.'$network'.app_ips' $jsonFile)}"
        avi_pools=$(echo $avi_pools | jq '. += ['$(echo $avi_pool)']')
        vs_name="app$count-hello-world"
        avi_virtual_service_http="{\"name\": \"$(echo $vs_name)\", \"type\": \"$(echo $type)\", \"cidr\": \"$(jq -c -r '.vsphere_underlay.networks.alb.vip.cidr' $jsonFile)\", \"network_ref\": \"$(jq -c -r .networks.alb.vip.port_group_name /nestedVsphere8/02_external_gateway/variables.json)\", \"pool_ref\": \"$(echo $pool_name)\", \"se_group_ref\": \"Default-Group\", \"services\": [{\"port\": 80, \"enable_ssl\": false}, {\"port\": 443, \"enable_ssl\": true}]}"
        avi_virtual_services_http=$(echo $avi_virtual_services_http | jq '. += ['$(echo $avi_virtual_service_http)']')
        ((count++))
        #
        pool_name="pool$count-avi"
        default_server_port=$(jq -c -r '.app.avi_app_tcp_port' /nestedVsphere8/08_app/variables.json)
        avi_pool="{\"name\": \"$(echo $pool_name)\", \"default_server_port\": $(echo $default_server_port), \"type\": \"$(echo $type)\", \"avi_app_server_ips\": $(jq -c -r  '.vsphere_underlay.networks.alb.'$network'.app_ips' $jsonFile)}"
        avi_pools=$(echo $avi_pools | jq '. += ['$(echo $avi_pool)']')
        vs_name="app$count-alb"
        avi_virtual_service_http="{\"name\": \"$(echo $vs_name)\", \"type\": \"$(echo $type)\", \"cidr\": \"$(jq -c -r '.vsphere_underlay.networks.alb.vip.cidr' $jsonFile)\", \"network_ref\": \"$(jq -c -r .networks.alb.vip.port_group_name /nestedVsphere8/02_external_gateway/variables.json)\", \"pool_ref\": \"$(echo $pool_name)\", \"se_group_ref\": \"Default-Group\", \"services\": [{\"port\": 80, \"enable_ssl\": false}, {\"port\": 443, \"enable_ssl\": true}]}"
        avi_virtual_services_http=$(echo $avi_virtual_services_http | jq '. += ['$(echo $avi_virtual_service_http)']')
        ((count++))
        #
        pool_name="pool$count-waf"
        default_server_port=$(jq -c -r '.app.hackazon_tcp_port' /nestedVsphere8/08_app/variables.json)
        avi_pool="{\"name\": \"$(echo $pool_name)\", \"default_server_port\": $(echo $default_server_port), \"type\": \"$(echo $type)\", \"avi_app_server_ips\": $(jq -c -r  '.vsphere_underlay.networks.alb.'$network'.app_ips' $jsonFile)}"
        avi_pools=$(echo $avi_pools | jq '. += ['$(echo $avi_pool)']')
        vs_name="app$count-waf"
        avi_virtual_service_http="{\"name\": \"$(echo $vs_name)\", \"type\": \"$(echo $type)\", \"cidr\": \"$(jq -c -r '.vsphere_underlay.networks.alb.vip.cidr' $jsonFile)\", \"network_ref\": \"$(jq -c -r .networks.alb.vip.port_group_name /nestedVsphere8/02_external_gateway/variables.json)\", \"pool_ref\": \"$(echo $pool_name)\", \"se_group_ref\": \"Default-Group\", \"services\": [{\"port\": 80, \"enable_ssl\": false}, {\"port\": 443, \"enable_ssl\": true}]}"
        avi_virtual_services_http=$(echo $avi_virtual_services_http | jq '. += ['$(echo $avi_virtual_service_http)']')
        ((count++))
      fi
      #
    done
    #
    echo "   +++ Adding avi.config.cloud.ipam.networks..."
    avi_json=$(echo $avi_json | jq '.avi.config.cloud += {"ipam": {"networks": '$(echo $ipam_networks)'}}')
    #
    echo "   +++ Adding avi.config.cloud.networks..."
    avi_json=$(echo $avi_json | jq '.avi.config.cloud += {"networks": '$(echo $networks)'}')
    #
    if [[ $(echo $avi_pools | jq '. | length') -gt 0 ]] ; then
      echo "   ++++++ Adding Avi pools..."
      avi_json=$(echo $avi_json | jq '.avi.config.cloud += {"pools": '$(echo $avi_pools)'}')
      echo "   ++++++ Adding Avi HTTP virtual services..."
      avi_json=$(echo $avi_json | jq '.avi.config.cloud.virtual_services += {"http": '$(echo $avi_virtual_services_http)'}')
    fi
    #
    avi_virtual_service_dns="{\"name\": \"app-dns\", \"type\": \"$(echo $type)\", \"cidr\": \"$(jq -c -r '.vsphere_underlay.networks.alb.vip.cidr' $jsonFile)\", \"network_ref\": \"$(jq -c -r .networks.alb.vip.port_group_name /nestedVsphere8/02_external_gateway/variables.json)\", \"se_group_ref\": \"Default-Group\", \"services\": [{\"port\": 53}]}"
    avi_virtual_services_dns=$(echo $avi_virtual_services_dns | jq '. += ['$(echo $avi_virtual_service_dns)']')
    echo "   ++++++ Adding Avi DNS virtual services..."
    avi_json=$(echo $avi_json | jq '.avi.config.cloud.virtual_services += {"dns": '$(echo $avi_virtual_services_dns)'}')
    avi_json=$(echo $avi_json | jq '.avi.config.cloud += {"contexts": []}')
    avi_json=$(echo $avi_json | jq '.avi.config.cloud += {"additional_subnets": []}')
  fi
fi
#
sslkeyandcertificate="[]"
avi_fqdn="$(jq -c -r .alb_controller_name /nestedVsphere8/02_external_gateway/variables.json).$(jq -c -r .external_gw.bind.domain $jsonFile)"
sslkeyandcertificate=$(echo $sslkeyandcertificate | jq '. += [{"name": "'$(jq -c -r .tanzu_cert_name /nestedVsphere8/07_nsx_alb/variables.json)'", "format": "SSL_PEM", "certificate_base64": true, "enable_ocsp_stapling": false, "import_key_to_hsm": false, "is_federated": false, "key_base64": true, "type": "SSL_CERTIFICATE_TYPE_SYSTEM", "certificate": {"days_until_expire": 365, "self_signed": true, "version": "2", "signature_algorithm":"sha256WithRSAEncryption", "subject_alt_names": ["'$(jq -c -r .vsphere_underlay.networks.vsphere.management.avi_nested_ip $jsonFile)'"], "issuer": {"common_name": "https://'$(echo $avi_fqdn)'", "distinguished_name": "CN='$(echo $avi_fqdn)'"}, "subject": {"common_name": "'$(echo $avi_fqdn)'", "distinguished_name": "CN='$(echo $avi_fqdn)'"}}, "key_params": {"algorithm": "SSL_KEY_ALGORITHM_RSA", "rsa_params": {"exponent": 65537, "key_size": "SSL_KEY_2048_BITS"}}, "ocsp_config": {"failed_ocsp_jobs_retry_interval": 3600, "max_tries": 10, "ocsp_req_interval": 86400, "url_action": "OCSP_RESPONDER_URL_FAILOVER"} }]')
echo "   +++ Adding avi.config.sslkeyandcertificate... for tanzu deployment"
avi_json=$(echo $avi_json | jq '.avi.config += {"sslkeyandcertificate": '$(echo $sslkeyandcertificate)'}')
echo "   +++ Adding avi.config.portal_configuration.sslkeyandcertificate_ref... for tanzu deployment"
avi_json=$(echo $avi_json | jq '.avi.config += {"portal_configuration": {"sslkeyandcertificate_ref": "'$(jq -c -r .tanzu_cert_name /nestedVsphere8/07_nsx_alb/variables.json)'"}}')
#
echo "   +++ Updating avi.config.cloud.service_engine_groups..."
avi_json=$(echo $avi_json | jq '. | del (.avi.config.cloud.service_engine_groups)')
avi_json=$(echo $avi_json | jq '.avi.config.cloud += {"service_engine_groups": '$(echo $seg_list)'}')
#
echo $avi_json | jq . | tee /root/avi.json > /dev/null
#
download_file_from_url_to_location "$(jq -c -r .avi.ova_url $jsonFile)" "$(jq -c -r .avi_ova_path $localJsonFile)" "Avi ova"