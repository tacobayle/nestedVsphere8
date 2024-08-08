
test_nsx_alb_variables () {
  echo ""
  echo "==> Checking NSX ALB Variables with or without NSX"
  test_if_json_variable_is_defined .avi.ova_url "$1" "   "
  test_if_json_variable_is_defined .avi.cpu "$1" "   "
  test_if_json_variable_is_defined .avi.memory "$1" "   "
  test_if_json_variable_is_defined .avi.disk "$1" "   "
  test_if_json_variable_is_defined .avi.version "$1" "   "
  test_if_json_variable_is_defined .avi.config.domain "$1" "   "
  test_if_variable_is_valid_ip $(jq -c -r .vsphere_underlay.networks.vsphere.management.avi_nested_ip "$1") "   "
  echo "   +++ testing if environment variable TF_VAR_docker_registry_username is not empty" ; if [ -z "$TF_VAR_docker_registry_username" ] ; then exit 255 ; fi
  echo "   +++ testing if environment variable TF_VAR_docker_registry_password is not empty" ; if [ -z "$TF_VAR_docker_registry_password" ] ; then exit 255 ; fi
  echo "   +++ testing if environment variable TF_VAR_docker_registry_email is not empty" ; if [ -z "$TF_VAR_docker_registry_email" ] ; then exit 255 ; fi
  echo "   +++ testing if environment variable TF_VAR_avi_password is not empty" ; if [ -z "$TF_VAR_avi_password" ] ; then exit 255 ; fi
  echo "   +++ testing if environment variable TF_VAR_avi_old_password is not empty" ; if [ -z "$TF_VAR_avi_old_password" ] ; then exit 255 ; fi
  if $(jq -e '.avi | has("cluster_ref")' "${1}") ; then
    if $(echo $variables_json | jq -e -c -r --arg arg "$(jq -c -r '.avi.cluster_ref' "${1}")" '.vsphere_nested.cluster_list[] | select( . == $arg )'> /dev/null) ; then
      echo "   +++ .avi.cluster_ref found"
    else
      echo "   +++ ERROR .avi.cluster_ref not found in .vsphere_nested.cluster_list[]"
      exit 255
    fi
  fi
}

test_nsx_app_variables () {
  echo ""
  echo "==> Checking NSX Apps with NSX"
  # .nsx.config.segments_overlay[].app_ips
  count=0
  for item in $(jq -c -r .nsx.config.segments_overlay[] "$1")
  do
    if [[ $(echo $item | jq -c .app_ips) != "null" ]] ; then
      if [[ $(echo $item | jq -r -c .display_name) == $(jq -c -r .avi.config.cloud.network_management.name "$1") ]] ; then
        echo "app_ips is not supported on overlay segment $(echo $item | jq -r -c .display_name) because it's defined at .avi.config.cloud.network_management.name - NAT is disabled hence no Internet Access"
        exit 255
      fi
      ((count++))
      for ip in $(echo $item | jq .app_ips[] -c -r)
      do
        test_if_variable_is_valid_ip "$ip" "   "
      done
    fi
  done
  if [[ $count -eq 0 ]] ; then echo "   +++ .nsx.config.segments_overlay[].app_ips has to be defined at least once to locate where the App servers will be installed" ; exit 255 ; fi
}

test_alb_variables_if_vsphere_nsx_alb_telco () {
  echo ""
  echo "==> Checking ALB variables for Telco Use case (NSX with vCenter cloud with BGP)"
  #
  # .avi.config.cloud.networks[]
  #
  test_if_json_variable_is_defined .avi.config.cloud.networks "$1" "   "
  for item in $(jq -c -r .avi.config.cloud.networks[] "$1")
  do
    test_if_variable_is_defined $(echo $item | jq -c .name) "   " "testing if each .avi.config.cloud.networks have a name defined"
    test_if_variable_is_defined $(echo $item | jq -c .avi_ipam_pool) "   " "testing if each .avi.config.cloud.networks[] have a avi_ipam_pool defined"
    test_if_variable_is_valid_ip "$(echo $item | jq -c -r .avi_ipam_pool | cut -d"-" -f1 )" "   "
    test_if_variable_is_valid_ip "$(echo $item | jq -c -r .avi_ipam_pool | cut -d"-" -f2 )" "   "
    test_if_variable_is_defined $(echo $item | jq -c .management) "   " "testing if each .avi.config.cloud.networks[] have a management defined"
    if [[ $(jq '.avi.config.cloud.networks[].management' "$1" | grep -c true) != 1 ]] ; then
      echo "      ++++++ ERROR only one network with management == true  is supported in .avi.config.cloud.networks[]"
      exit 255
    fi
    test_if_variable_is_defined $(echo $item | jq -r .external) "   " "testing if each .avi.config.cloud.networks[] have a external defined"
    if [[ $(jq '.avi.config.cloud.networks[].external' "$1" | grep -c true) != 1 ]] ; then
      echo "      ++++++ ERROR only one network with external == true  is supported in .avi.config.cloud.networks[]"
      exit 255
    fi
    if [[ $(echo $item | jq -c .external) == false ]] ; then
      if [[ $(jq -c -r --arg network_name "$(echo $item | jq -r .name)" '.nsx.config.segments_overlay[] | select(.display_name == $network_name).display_name' "$1") == "" ]] ; then
        echo "      ++++++ ERROR $(echo $item | jq -r .name) was not found in .nsx.config.segments_overlay[].display_name"
        exit 255
      fi
    fi
    if [[ $(jq -c -r '.nsx.config.tier0s | map(select(has("bgp"))) | .[].bgp.avi_peer_label' "$1" | uniq -d) != "" ]] ; then
      echo "      ++++++ ERROR .nsx.config.tier0s[].bgp.avi_peer_label has a duplicate value"
      exit 255
    fi
    if [[ $(jq '.avi.config.cloud.contexts[].routing_options[].label' "$1" | uniq -d ) != "" ]] ; then
      echo "      ++++++ ERROR .avi.config.cloud.contexts[].routing_options[].label has a duplicate value"
      exit 255
    fi
    for tier0_bgp in $(jq -c -r '.nsx.config.tier0s | map(select(has("bgp"))) | .[].bgp' "$1")
    do
      if [[ $(jq -c -r --arg context "$(echo $tier0_bgp | jq -r .avi_context_ref)" '.avi.config.cloud.contexts[] | select(.name == $context).name' "$1") == "" ]] ; then
        echo "      ++++++ ERROR $(echo $tier0_bgp | jq -r .avi_context_ref) was not found in .avi.config.cloud.contexts[].name"
        exit 255
      fi
      if [[ $(jq --arg context "$(echo $tier0_bgp | jq -r .avi_context_ref)" '.avi.config.cloud.contexts[] | select(.name == $context).routing_options | map(select(.label == "'$(echo $tier0_bgp | jq -r .avi_peer_label)'"))[].label ' "$1") == "" ]] ; then
        echo "      ++++++ ERROR $(echo $tier0_bgp | jq -r .avi_peer_label) was not found in .avi.config.cloud.contexts[].routing_options[].label"
        exit 255
      fi
    done
  done
  #
  # .avi.config.cloud.additional_subnets[]
  #
  test_if_json_variable_is_defined .avi.config.cloud.additional_subnets "$1" "   "
  for item in $(jq -c -r .avi.config.cloud.additional_subnets[] "$1")
  do
    test_if_variable_is_defined $(echo $item | jq -c -r .name_ref) "   " "testing if each .avi.config.cloud.additional_subnets have a name_ref defined"
    if [[ $(jq -c -r --arg network_name "$(echo $item | jq -c -r .name_ref)" '.avi.config.cloud.networks[] | select(.name == $network_name).name' "$1") == "" ]] ; then
      echo "      ++++++ ERROR $(echo $item | jq -c -r .name_ref) was not found in .avi.config.cloud.networks[].name"
      exit 255
    fi
    for subnet in $(echo $item | jq -c -r .subnets[])
    do
      test_if_variable_is_defined $(echo $subnet | jq -c -r .cidr) "   " "testing if each .avi.config.cloud.additional_subnets[].subnets have a cidr defined"
      test_if_variable_is_valid_cidr "$(echo $subnet | jq -c -r .cidr)" "   "
      test_if_variable_is_defined $(echo $subnet | jq -c -r .range) "   " "testing if each .avi.config.cloud.additional_subnets[].subnets have a range defined"
      test_if_variable_is_valid_ip "$(echo $subnet | jq -c -r .range | cut -d"-" -f1)" "   "
      test_if_variable_is_valid_ip "$(echo $subnet | jq -c -r .range | cut -d"-" -f2)" "   "
      test_if_variable_is_defined $(echo $subnet | jq -c -r .type) "   " "testing if each .avi.config.cloud.additional_subnets[].subnets have a type defined"
      test_if_variable_is_defined $(echo $subnet | jq -c -r .range_type) "   " "testing if each .avi.config.cloud.additional_subnets[].subnets have a range_type defined"
    done
  done
  #
  # .avi.config.cloud.contexts
  #
  echo "   +++ testing avi.config.cloud.contexts"
  test_if_json_variable_is_defined .avi.config.cloud.contexts "$1" "   "
  if [[ $(jq '.avi.config.cloud.contexts | length' "$1") != 1 ]] ; then echo "      ++++++ ERROR only one context is supported in .avi.config.cloud.contexts" ; exit 255 ; fi
  for item in $(jq -c -r .avi.config.cloud.contexts[] "$1")
  do
    test_if_variable_is_defined $(echo $item | jq -c .name) "   " "testing if each .avi.config.cloud.contexts have a name defined"
    test_if_variable_is_defined $(echo $item | jq -c .ibgp) "   " "testing if each .avi.config.cloud.contexts have a ibgp defined"
    test_if_variable_is_defined $(echo $item | jq -c .keepalive_interval) "   " "testing if each .avi.config.cloud.contexts have a keepalive_interval defined"
    test_if_variable_is_defined $(echo $item | jq -c .hold_time) "   " "testing if each .avi.config.cloud.contexts have a hold_time defined"
    test_if_variable_is_defined $(echo $item | jq -c .local_as) "   " "testing if each .avi.config.cloud.contexts have a local_as defined"
    test_if_variable_is_defined $(echo $item | jq -c .send_community) "   " "testing if each .avi.config.cloud.contexts have a send_community defined"
    test_if_variable_is_defined $(echo $item | jq -c .shutdown) "   " "testing if each .avi.config.cloud.contexts have a shutdown defined"
    test_if_variable_is_defined $(echo $item | jq -c .routing_options) "   " "testing if each .avi.config.cloud.contexts have a routing_options defined"
    for routing_option in $(echo $item | jq -c -r .routing_options[])
      do
        test_if_variable_is_defined $(echo $routing_option | jq -c .advertise_learned_routes) "   " "testing if each .avi.config.cloud.contexts[].routing_options have a advertise_learned_routes defined"
        test_if_variable_is_defined $(echo $routing_option | jq -c .label) "   " "testing if each .avi.config.cloud.contexts[].routing_options have a label defined"
        test_if_variable_is_defined $(echo $routing_option | jq -c .max_learn_limit) "   " "testing if each .avi.config.cloud.contexts[].routing_options have a max_learn_limit defined"
      done
  done
  #
  #
  # .avi.config.cloud.virtual_services
  #
  test_if_json_variable_is_defined .avi.config.cloud.virtual_services.dns "$1" "   "
  for item in $(jq -c -r .avi.config.cloud.virtual_services.dns[] "$1")
  do
    test_if_variable_is_defined $(echo $item | jq -c .name) "   " "testing if each .avi.config.cloud.virtual_services.dns[] have a name defined"
    test_if_variable_is_defined $(echo $item | jq -c .network_ref) "   " "testing if each .avi.config.cloud.virtual_services.dns[] have a network_ref defined"
    if [[ $(jq -c -r --arg network_name "$(echo $item | jq -r .network_ref)" '.avi.config.cloud.networks[] | select(.name == $network_name).name' "$1") == "" ]] ; then
      echo "      ++++++ ERROR $(echo $item | jq -r .network_ref) was not found in .avi.config.cloud.networks[].name"
      exit 255
    fi
  done
}

test_alb_variables_if_nsx_cloud () {
  echo ""
  echo "==> Checking ALB with NSX Cloud type"
  test_if_json_variable_is_defined .avi.config.cloud.type "$1" "   "
  if [[ $(jq -c -r .avi.config.cloud.type "$1") == "CLOUD_NSXT" ]]; then
    test_if_json_variable_is_defined .avi.config.cloud.networks_data "$1" "   "
    test_if_json_variable_is_defined .avi.config.cloud.obj_name_prefix "$1" "   "
    # .avi.config.cloud.network_management
    test_if_json_variable_is_defined .avi.config.cloud.network_management.name "$1" "   "
    avi_cloud_network=0
    for segment in $(jq -c -r .nsx.config.segments_overlay[] "$1")
    do
      if [[ $(echo $segment | jq -r .display_name) == $(jq -c -r .avi.config.cloud.network_management.name "$1") ]] ; then
        avi_cloud_network=1
        echo "   ++++++ Avi cloud network found in NSX overlay segments: $(echo $segment | jq -r .display_name), OK"
      fi
    done
    if [[ $avi_cloud_network -eq 0 ]] ; then
      echo "   ++++++ERROR++++++ $(echo $network | jq -c -r .name) segment not found!!"
      exit 255
    fi
    test_if_variable_is_valid_ip "$(jq -c -r .avi.config.cloud.network_management.avi_ipam_pool_se "$1" | cut -d"-" -f1 )" "   "
    test_if_variable_is_valid_ip "$(jq -c -r .avi.config.cloud.network_management.avi_ipam_pool_se "$1" | cut -d"-" -f2 )" "   "
    # .avi.config.cloud.networks_data[]
    for item in $(jq -c -r .avi.config.cloud.networks_data[] "$1")
    do
      test_if_variable_is_defined $(echo $item | jq -c .name) "   " "testing if each .avi.config.cloud.networks_data[] have a name defined"
      test_if_variable_is_valid_ip "$(echo $item | jq -c -r .avi_ipam_pool_se | cut -d"-" -f1 )" "   "
      test_if_variable_is_valid_ip "$(echo $item | jq -c -r .avi_ipam_pool_se | cut -d"-" -f2 )" "   "
      test_if_variable_is_valid_cidr "$(echo $item | jq -c -r .avi_ipam_vip.cidr)" "   "
      test_if_variable_is_valid_ip "$(echo $item | jq -c -r .avi_ipam_vip.pool | cut -d"-" -f1 )" "   "
      test_if_variable_is_valid_ip "$(echo $item | jq -c -r .avi_ipam_vip.pool | cut -d"-" -f2 )" "   "
    done
    #
    test_if_ref_from_list_exists_in_another_list ".avi.config.cloud.networks_data[].name" \
                                                 ".nsx.config.segments_overlay[].display_name" \
                                                 "$1" \
                                                 "   +++ Checking name in .avi.config.cloud.networks_data" \
                                                 "   ++++++ Segment " \
                                                 "   ++++++ERROR++++++ Segment not found: "
    # checking that there is a network data with the proper tier1 for each .nsx.config.segments_overlay[].app_ips
    echo "   +++ Checking that there is a network data with the proper tier1 for each .nsx.config.segments_overlay[].app_ips"
    for segment in $(jq -c -r .nsx.config.segments_overlay[] "$1")
    do
      if [[ $(echo $segment | jq -c .app_ips) != "null" ]] ; then
        tier1_app_ips=$(echo $segment | jq -c -r .tier1)
        tier1_app_ips_segment_data=0
        for network_data in $(jq -c -r .avi.config.cloud.networks_data[] "$1")
        do
          for segment_data in $(jq -c -r .nsx.config.segments_overlay[] "$1")
          do
            if [[ $(echo $network_data | jq -c .name) == $(echo $segment_data | jq -c .display_name) ]] ; then
              tier1_segment_data=$(echo $segment_data | jq -c -r .tier1)
              if [[ $tier1_segment_data == $tier1_app_ips ]] ; then
                echo "   ++++++ Avi network data found for pool segment $(echo $segment | jq -c .display_name), tier1 $tier1_app_ips: $(echo $network_data | jq -c .name) with tier1: $tier1_segment_data"
                tier1_app_ips_segment_data=1
              fi
            fi
          done
        done
      fi
    done
    if [[ $tier1_app_ips_segment_data -eq 0 ]] ; then echo "   ++++++ERROR++++++ no Avi network_data found for $(echo $segment | jq -c .display_name)" ; exit 255 ; fi
    #
    if [[ $(jq -c -r .avi.config.cloud.virtual_services.dns "$1") != "null" ]]; then
      for item in $(jq -c -r .avi.config.cloud.virtual_services.dns[] "$1")
      do
        test_if_variable_is_defined $(echo $item | jq -c .name) "   " "testing if each .avi.config.cloud.virtual_services.dns[] have a name defined"
        test_if_variable_is_defined $(echo $item | jq -c .network_ref) "   " "testing if each .avi.config.cloud.virtual_services.dns[] have a network_ref defined"

        test_if_variable_is_defined $(echo $item | jq -c .se_group_ref) "   " "testing if each .avi.config.cloud.virtual_services.dns[] have a se_group_ref defined"
        for service in $(echo $item | jq -c -r .services[])
        do
          test_if_variable_is_defined $(echo $service | jq -c .port) "   " "testing if each .avi.config.cloud.virtual_services.dns[].services have a port defined"
        done
      done
      #
      test_if_ref_from_list_exists_in_another_list ".avi.config.cloud.virtual_services.dns[].network_ref" \
                                                   ".nsx.config.segments_overlay[].display_name" \
                                                   "$1" \
                                                   "   +++ Checking network_ref in .avi.config.cloud.virtual_services.dns" \
                                                   "   ++++++ Segment " \
                                                   "   ++++++ERROR++++++ Segment not found: "
    fi
  fi
}