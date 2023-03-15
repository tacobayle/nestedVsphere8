#!/bin/bash
#
jsonFile="/etc/config/variables.json"
localJsonFile="/nestedVsphere8/07_nsx_alb/variables.json"
#
IFS=$'\n'
#
if [[ $(jq -c -r .avi $jsonFile) != "null" ]]; then
  echo ""
  echo "==> Creating /root/avi.json file..."
  rm -f /root/avi.json
  avi_json=$(jq -c -r . $jsonFile | jq .)
  #
  echo "   +++ Adding avi.config.cloud.name..."
  avi_json=$(echo $avi_json | jq '.avi.config.cloud += {"name": "dc1_nsx"}')
  #
  echo "   +++ Adding avi.config.avi_config_repo..."
  avi_config_repo=$(jq -c -r '.avi_config_repo' $localJsonFile)
  avi_json=$(echo $avi_json | jq '.avi.config += {"avi_config_repo": "'$(echo $avi_config_repo)'"}')
  #
  echo "   +++ Adding avi.config.avi_config_tag..."
  avi_config_tag=$(jq -c -r '.avi_config_tag' $localJsonFile)
  avi_json=$(echo $avi_json | jq '.avi.config += {"avi_config_tag": "'$(echo $avi_config_tag)'"}')
  #
  echo "   +++ Adding avi.config.playbook_nsx_env_nsx_cloud..."
  playbook_nsx_env_nsx_cloud=$(jq -c -r '.playbook_nsx_env_nsx_cloud' $localJsonFile)
  avi_json=$(echo $avi_json | jq '.avi.config += {"playbook_nsx_env_nsx_cloud": "'$(echo $playbook_nsx_env_nsx_cloud)'"}')
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
  if [[ $(jq -c -r .nsx $jsonFile) != "null" && $(jq -c -r .avi.config.cloud.type $jsonFile) == "CLOUD_NSXT" ]]; then
    echo "   +++ Adding transport_zone details..."
    transport_zone=$(jq -c -r '.transport_zones[0].name' /nestedVsphere8/06_nsx_config/variables.json)
    avi_json=$(echo $avi_json | jq '. += {"transport_zone": "'$(echo $transport_zone)'"}')
  fi
  #
  if [[ $(jq -c -r .nsx $jsonFile) != "null" ]]; then
    if [[ $(jq -c -r '.nsx.config.segments_overlay | length' $jsonFile) -gt 0 ]] ; then
      echo "   +++ Creating External routes to subnet overlay segments..."
      static_routes="[]"
      count=0
      for segment in $(jq -c -r .nsx.config.segments_overlay[] $jsonFile)
      do
        static_routes=$(echo $static_routes | jq '. += [{"prefix": "'$(echo $segment | jq -c -r .cidr)'", "next_hop": "'$(jq -c -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile)'", "if_name": "'$(jq -c -r .nsx_alb_controller_if_name $localJsonFile)'", "route_id": "'$(echo $count)'"}]')
        ((count++))
      done
    fi
  fi
  #
  avi_json=$(echo $avi_json | jq '.avi.config += {"static_routes": '$(echo $static_routes)'}')
  #
  if [[ $(jq -c -r .avi.config.cloud.type $jsonFile) == "CLOUD_NSXT" ]]; then
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
          pool_name=$(jq -c -r '.app.nsxt_group_name' /nestedVsphere8/08_nsx_app/variables.json)
          tier1=$(echo $item | jq -c -r .tier1)
          default_server_port=$(jq -c -r '.app.hello_world_app_tcp_port' /nestedVsphere8/08_nsx_app/variables.json)
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
        default_server_port=$(jq -c -r '.app.hello_world_app_tcp_port' /nestedVsphere8/08_nsx_app/variables.json)
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
        default_server_port=$(jq -c -r '.app.avi_app_tcp_port' /nestedVsphere8/08_nsx_app/variables.json)
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
        default_server_port=$(jq -c -r '.app.hackazon_tcp_port' /nestedVsphere8/08_nsx_app/variables.json)
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
  fi
  #
  echo $avi_json | jq . | tee /root/avi.json > /dev/null
  #
  echo ""
  echo "==> Downloading Avi ova file"
  if [ -s "$(jq -c -r .avi_ova_path $localJsonFile)" ]; then echo "   +++ Avi ova file $(jq -c -r .avi_ova_path $localJsonFile) is not empty" ; else curl -s -o $(jq -c -r .avi_ova_path $localJsonFile) $(jq -c -r .avi.ova_url $jsonFile) ; fi
  if [ -s "$(jq -c -r .avi_ova_path $localJsonFile)" ]; then echo "   +++ Avi ova file $(jq -c -r .avi_ova_path $localJsonFile) is not empty" ; else echo "   +++ NSX ova $(jq -c -r .avi_ova_path $localJsonFile) is empty" ; exit 255 ; fi
  #
fi
