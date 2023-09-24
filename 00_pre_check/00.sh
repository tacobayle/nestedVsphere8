#!/bin/bash
#
source /nestedVsphere8/bash/test_if_variables.sh
source /nestedVsphere8/bash/ip.sh
#
jsonFile="/etc/config/variables.json"
#
#
#
test_nsx_alb_variables () {
  echo ""
  echo "==> Checking NSX ALB Variables with or without NSX"
  test_if_json_variable_is_defined .avi.ova_url "$1" "   "
  test_if_json_variable_is_defined .avi.cpu "$1" "   "
  test_if_json_variable_is_defined .avi.memory "$1" "   "
  test_if_json_variable_is_defined .avi.disk "$1" "   "
  test_if_json_variable_is_defined .avi.version "$1" "   "
  test_if_json_variable_is_defined .avi.config.cloud.service_engine_groups "$1" "   "
  test_if_json_variable_is_defined .avi.config.domain "$1" "   "
  test_if_variable_is_valid_ip $(jq -c -r .vsphere_underlay.networks.vsphere.management.avi_nested_ip "$1") "   "
  echo "   +++ testing if environment variable TF_VAR_docker_registry_username is not empty" ; if [ -z "$TF_VAR_docker_registry_username" ] ; then exit 255 ; fi
  echo "   +++ testing if environment variable TF_VAR_docker_registry_password is not empty" ; if [ -z "$TF_VAR_docker_registry_password" ] ; then exit 255 ; fi
  echo "   +++ testing if environment variable TF_VAR_docker_registry_email is not empty" ; if [ -z "$TF_VAR_docker_registry_email" ] ; then exit 255 ; fi
  echo "   +++ testing if environment variable TF_VAR_avi_password is not empty" ; if [ -z "$TF_VAR_avi_password" ] ; then exit 255 ; fi
  echo "   +++ testing if environment variable TF_VAR_avi_old_password is not empty" ; if [ -z "$TF_VAR_avi_old_password" ] ; then exit 255 ; fi
}
#
#
#
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
#
#
#
test_nsx_k8s_variables () {
  echo ""
  echo "==> Checking unmanaged_k8s with NSX"
  # .nsx.config.segments_overlay[].k8s_clusters
  for item in $(jq -c -r .nsx.config.segments_overlay[] "$1")
  do
    if [[ $(echo $item | jq -c .k8s_clusters) != "null" ]] ; then
      placement_k8s=0
      for network in $(jq -c -r .avi.config.cloud.networks_data[] "$1")
      do
        if [[ $(echo $item | jq -r -c .display_name) == $(echo $network | jq -c -r .name) ]] ; then
          placement_k8s=1
        fi
      done
      if [[ $placement_k8s -ne 1 ]] ; then
        echo "With NSX: k8s_clusters is supported only on vip segments defined .avi.config.cloud.networks_data[]"
        exit 255
      fi
      variables_json=$(echo $variables_json | jq '. += {"unmanaged_k8s_status": true}')
      for cluster in $(echo $item | jq -c -r .k8s_clusters[])
      do
        test_if_variable_is_defined $(echo $cluster | jq -c .cluster_name) "   " "testing if each .nsx.config.segments_overlay.$(echo $item | jq -r -c .display_name).k8s_clusters[] have a cluster_name defined"
        test_if_variable_is_defined $(echo $cluster | jq -c .k8s_version) "   " "testing if each .nsx.config.segments_overlay.$(echo $item | jq -r -c .display_name).k8s_clusters[] have a k8s_version defined"
        test_if_variable_is_defined $(echo $cluster | jq -c .cni) "   " "testing if each .nsx.config.segments_overlay.$(echo $item | jq -r -c .display_name).k8s_clusters[] have a cni defined"
        if [[ $(echo $cluster | jq -c -r .cni) == "antrea" || $(echo $cluster | jq -c -r .cni) == "calico" || $(echo $cluster | jq -c -r .cni) == "cilium" ]] ; then
          echo "   +++ cni is $(echo $cluster | jq -c -r .cni) which is supported"
        else
          echo "   +++ cni $(echo $cluster | jq -c -r .cni) is not supported - cni should be either \"calico\" or \"antrea\" or \"cilium\""
          exit 255
        fi
        test_if_variable_is_defined $(echo $cluster | jq -c .cni_version) "   " "testing if each .nsx.config.segments_overlay.$(echo $item | jq -r -c .display_name).k8s_clusters[] have a cni_version defined"
        test_if_variable_is_defined $(echo $cluster | jq -c .ako_version) "   " "testing if each .nsx.config.segments_overlay.$(echo $item | jq -r -c .display_name).k8s_clusters[] have a ako_version defined"
        if [[ $(echo $cluster | jq -c -r .ako_version) == "1.10.1" ]] ; then
          echo "   +++ ako_version is $(echo $cluster | jq -c -r .ako_version) which is supported"
        else
          echo "   +++ ako_version $(echo $cluster | jq -c -r .ako_version) is not supported"
          exit 255
        fi
        test_if_variable_is_defined $(echo $cluster | jq -c .cluster_ips) "   " ".nsx.config.segments_overlay.$(echo $item | jq -r -c .display_name).k8s_clusters[] have a cluster_ips defined"
        if [[ $(echo $cluster | jq -c -r '.cluster_ips | length') -lt 3 ]] ; then echo "   +++ Amount of cluster_ips should be higher than 3" ; exit 255 ; fi
        for ip in $(echo $cluster | jq -c -r .cluster_ips[])
        do
          test_if_variable_is_valid_ip "$ip" "   "
        done
      done
    fi
  done
}
#
#
#
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
  # .avi.config.cloud.service_engine_groups
  #
  test_if_json_variable_is_defined .avi.config.cloud.service_engine_groups "$1" "   "
  for item in $(jq -c -r .avi.config.cloud.service_engine_groups[] "$1")
  do
    test_if_variable_is_defined $(echo $item | jq -c .name) "   " "testing if each .avi.config.cloud.service_engine_groups[] have a name defined"
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
    test_if_variable_is_defined $(echo $item | jq -c .se_group_ref) "   " "testing if each .avi.config.cloud.virtual_services.dns[] have a se_group_ref defined"
    if [[ $(jq -c -r --arg arg_name "$(echo $item | jq -r .se_group_ref)" '.avi.config.cloud.service_engine_groups[] | select(.name == $arg_name).name' "$1") == "" ]] ; then
      echo "      ++++++ ERROR $(echo $item | jq -r .se_group_ref) was not found in .avi.config.cloud.service_engine_groups[].name"
      exit 255
    fi
  done
}
#
#
#
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
    # .avi.config.cloud.service_engine_groups[]
    for item in $(jq -c -r .avi.config.cloud.service_engine_groups[] "$1")
    do
      test_if_variable_is_defined $(echo $item | jq -c .name) "   " "testing if each .avi.config.cloud.service_engine_groups[] have a name defined"
    done
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
      test_if_ref_from_list_exists_in_another_list ".avi.config.cloud.virtual_services.dns[].se_group_ref" \
                                                   ".avi.config.cloud.service_engine_groups[].name" \
                                                   "$1" \
                                                   "   +++ Checking se_group_ref in .avi.config.cloud.virtual_services.dns" \
                                                   "   ++++++ Service Engine Group " \
                                                   "   ++++++ERROR++++++ ervice Engine Group not found: "
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
#
#
#
rm -f /root/variables.json
variables_json=$(jq -c -r . $jsonFile | jq .)
#
#
#
IFS=$'\n'
#
echo ""
echo "==> Checking required environment variables"
echo "   +++ testing if environment variable TF_VAR_vsphere_underlay_username is not empty" ; if [ -z "$TF_VAR_vsphere_underlay_username" ] ; then exit 255 ; fi
echo "   +++ testing if environment variable TF_VAR_vsphere_underlay_password is not empty" ; if [ -z "$TF_VAR_vsphere_underlay_password" ] ; then exit 255 ; fi
echo "   +++ testing if environment variable TF_VAR_ubuntu_password is not empty" ; if [ -z "$TF_VAR_ubuntu_password" ] ; then exit 255 ; fi
echo "   +++ testing if environment variable TF_VAR_bind_password is not empty" ; if [ -z "$TF_VAR_bind_password" ] ; then exit 255 ; fi
echo "   +++ testing if environment variable TF_VAR_nested_esxi_root_password is not empty" ; if [ -z "$TF_VAR_nested_esxi_root_password" ] ; then exit 255 ; fi
echo "   +++ testing if environment variable TF_VAR_vsphere_nested_password is not empty" ; if [ -z "$TF_VAR_vsphere_nested_password" ] ; then exit 255 ; fi
#
echo ""
echo "==> Checking vSphere Underlay Variables"
test_if_json_variable_is_defined .vsphere_underlay.datacenter $jsonFile "   "
test_if_json_variable_is_defined .vsphere_underlay.cluster $jsonFile "   "
test_if_json_variable_is_defined .vsphere_underlay.datastore $jsonFile "   "
test_if_json_variable_is_defined .vsphere_underlay.folder $jsonFile "   "
test_if_json_variable_is_defined .vsphere_underlay.vcsa $jsonFile "   "
test_if_json_variable_is_defined .vsphere_underlay.networks_vsphere_dual_attached $jsonFile "   "
#
vsphere_networks='["management", "vmotion", "vsan"]'
for network in $(echo $vsphere_networks | jq -c -r .[])
do
  test_if_json_variable_is_defined .vsphere_underlay.networks.vsphere.$network.name $jsonFile "   "
  test_if_variable_is_netmask "$(jq -c -r .vsphere_underlay.networks.vsphere.$network.cidr $jsonFile)" "   "
  test_if_json_variable_is_defined .vsphere_underlay.networks.vsphere.$network.esxi_ips $jsonFile "   "
  for ip in $(jq -c -r .vsphere_underlay.networks.vsphere.$network.esxi_ips[] $jsonFile)
  do
    test_if_variable_is_valid_ip $ip "   "
  done
  #
  echo "   +++ Adding prefix for $network network..."
  prefix=$(jq -c -r .vsphere_underlay.networks.vsphere.$network.cidr $jsonFile | cut -d"/" -f2)
  variables_json=$(echo $variables_json | jq '.vsphere_underlay.networks.vsphere.'$network' += {"prefix": "'$(echo $prefix)'"}')
  #
  echo "   +++ Adding netmask for $network network..."
  netmask=$(ip_netmask_by_prefix $(jq -c -r .vsphere_underlay.networks.vsphere.$network.cidr $jsonFile | cut -d"/" -f2) "   ++++++")
  variables_json=$(echo $variables_json | jq '.vsphere_underlay.networks.vsphere.'$network' += {"netmask": "'$(echo $netmask)'"}')
  #
done
#
test_if_json_variable_is_defined .vsphere_underlay.networks.vsphere.management.gateway $jsonFile "   "
test_if_variable_is_valid_ip $(jq -c -r .vsphere_underlay.networks.vsphere.management.gateway $jsonFile) "   "
test_if_json_variable_is_defined .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile "   "
test_if_variable_is_valid_ip $(jq -c -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile) "   "
test_if_json_variable_is_defined .vsphere_underlay.networks.vsphere.management.esxi_ips_temp $jsonFile "   "
for ip in $(jq -c -r .vsphere_underlay.networks.vsphere.management.esxi_ips_temp[] $jsonFile)
do
  test_if_variable_is_valid_ip $ip "   "
done
test_if_json_variable_is_defined .vsphere_underlay.networks.vsphere.management.vcsa_nested_ip $jsonFile "   "
test_if_variable_is_valid_ip $(jq -c -r .vsphere_underlay.networks.vsphere.management.vcsa_nested_ip $jsonFile) "   "
#
#
#
echo ""
echo "==> Checking External Gateway Variables"
test_if_json_variable_is_defined .external_gw.bind.forwarders $jsonFile "   "
for ip in $(jq -c -r .external_gw.bind.forwarders[] $jsonFile)
do
  test_if_variable_is_valid_ip $ip "   "
done
test_if_json_variable_is_defined .external_gw.bind.domain $jsonFile "   "
test_if_json_variable_is_defined .external_gw.ntp $jsonFile "   "
#
#
#
echo ""
echo "==> Checking vCenter Variables"
test_if_json_variable_is_defined .vsphere_nested.vcsa_name $jsonFile "   "
test_if_json_variable_is_defined .vsphere_nested.iso_url $jsonFile "   "
test_if_json_variable_is_defined .vsphere_nested.esxi.iso_url $jsonFile "   "
test_if_json_variable_is_defined .vsphere_nested.datacenter $jsonFile "   "
test_if_json_variable_is_defined .vsphere_nested.cluster $jsonFile "   "
test_if_json_variable_is_defined .vsphere_nested.sso.domain_name $jsonFile "   "
test_if_json_variable_is_defined .vsphere_nested.timezone $jsonFile "   "
test_if_json_variable_is_defined .vsphere_nested.esxi.iso_url $jsonFile "   "
test_if_json_variable_is_defined .vsphere_nested.esxi.basename $jsonFile "   "
test_if_json_variable_is_defined .vsphere_nested.esxi.cpu $jsonFile "   "
test_if_json_variable_is_defined .vsphere_nested.esxi.memory $jsonFile "   "
test_if_json_variable_is_defined .vsphere_nested.esxi.disks $jsonFile "   "
if [[ $(jq -c -r '.vsphere_nested.esxi.disks | length' $jsonFile) -ne 3 ]] ; then echo "   +++ 3 ESXi host's disks must be configured" ; exit 255 ; fi
test_if_json_variable_is_defined .vsphere_nested.esxi.disks[0].size $jsonFile "   "
test_if_json_variable_is_defined .vsphere_nested.esxi.disks[1].size $jsonFile "   "
test_if_json_variable_is_defined .vsphere_nested.esxi.disks[2].size $jsonFile "   "
test_if_json_variable_is_defined .vsphere_nested.esxi.disks[0].thin_provisioned $jsonFile "   "
test_if_json_variable_is_defined .vsphere_nested.esxi.disks[1].thin_provisioned $jsonFile "   "
test_if_json_variable_is_defined .vsphere_nested.esxi.disks[2].thin_provisioned $jsonFile "   "
#
# Nested vSphere wo NSX wo Avi
#
if [[ $(jq -c -r .vsphere_underlay.networks.alb $jsonFile) == "null" && $(jq -c -r .nsx $jsonFile) == "null" ]]; then
  if [[ $(jq -c -r .avi $jsonFile) != "null" ]]; then
    echo "   ++++++ ERROR: cannot get .avi defined with .nsx or .vsphere_underlay.networks.alb undefined"
    exit 255
  fi
  echo ""
  echo "==> Adding .deployment: vsphere_wo_nsx"
  variables_json=$(echo $variables_json | jq '. += {"deployment": "vsphere_wo_nsx"}')
  mv /nestedVsphere8/02_external_gatewayexternal_gw.tf.disabled /nestedVsphere8/02_external_gatewayexternal_gw.tf
fi
#
# Nested vSphere wo NSX with Avi
#
if [[ $(jq -c -r .vsphere_underlay.networks.alb $jsonFile) != "null" ]]; then
  # vSphere alb vSphere networks with NSX config.
  if [[ $(jq -c -r .nsx $jsonFile) != "null" ]]; then
    echo "   ++++++ ERROR: cannot get .vsphere_underlay.networks.alb defined and .nsx defined: must be one or the other"
    exit 255
  fi
  # vSphere alb vSphere networks without Avi config.
  if [[ $(jq -c -r .avi $jsonFile) == "null" ]]; then
    echo "   ++++++ ERROR: cannot get .vsphere_underlay.networks.alb defined without .avi defined: must be one and the other"
    exit 255
  fi
  # setting unmanaged_k8s_status disabled by default
  variables_json=$(echo $variables_json | jq '. += {"unmanaged_k8s_status": false}')
  #
  if [[ $(jq -c -r .vsphere_underlay.networks.alb.se.app_ips $jsonFile) != "null" || $(jq -c -r .vsphere_underlay.networks.alb.se.k8s_clusters $jsonFile) != "null" ]] ; then
    echo "app_ips or k8s_clusters is not supported on Port Group SE - because NAT is disabled hence no Internet Access"
    exit 255
  fi
  #
  alb_networks='["se", "backend", "vip", "tanzu"]'
  for network in $(echo $alb_networks | jq -c -r .[])
  do
    test_if_json_variable_is_defined .vsphere_underlay.networks.alb.$network.name $jsonFile "   "
    test_if_variable_is_valid_cidr "$(jq -c -r .vsphere_underlay.networks.alb.$network.cidr $jsonFile)" "   "
    test_if_variable_is_valid_ip "$(jq -c -r .vsphere_underlay.networks.alb.$network.external_gw_ip $jsonFile)" "   "
    test_if_variable_is_valid_ip "$(jq -c -r .vsphere_underlay.networks.alb.$network.avi_ipam_pool $jsonFile | cut -d"-" -f1 )" "   "
    test_if_variable_is_valid_ip "$(jq -c -r .vsphere_underlay.networks.alb.$network.avi_ipam_pool $jsonFile | cut -d"-" -f2 )" "   "
    #
    if [[ $(jq -c -r .vsphere_underlay.networks.alb.$network.app_ips $jsonFile) != "null" ]] ; then
      for ip in $(jq -c -r .vsphere_underlay.networks.alb.$network.app_ips[] $jsonFile)
      do
        test_if_variable_is_valid_ip "$ip" "   "
      done
    fi
    #
    if [[ $(jq -c -r .vsphere_underlay.networks.alb.$network.k8s_clusters $jsonFile) != "null" ]] ; then
      for cluster in $(jq -c -r .vsphere_underlay.networks.alb.$network.k8s_clusters[] $jsonFile)
      do
        test_if_variable_is_defined $(echo $cluster | jq -c .cluster_name) "   " "testing if each .vsphere_underlay.networks.alb.$network.k8s_clusters[] have a cluster_name defined"
        test_if_variable_is_defined $(echo $cluster | jq -c .k8s_version) "   " "testing if each .vsphere_underlay.networks.alb.$network.k8s_clusters[] have a k8s_version defined"
        test_if_variable_is_defined $(echo $cluster | jq -c .cni) "   " "testing if each .vsphere_underlay.networks.alb.$network.k8s_clusters[] have a cni defined"
        if [[ $(echo $cluster | jq -c -r .cni) == "antrea" || $(echo $cluster | jq -c -r .cni) == "calico" || $(echo $cluster | jq -c -r .cni) == "cilium" ]] ; then
          echo "   +++ cni is $(echo $cluster | jq -c -r .cni) which is supported"
        else
          echo "   +++ cni $(echo $cluster | jq -c -r .cni) is not supported - cni should be either \"calico\" or \"antrea\" or \"cilium\""
          exit 255
        fi
        test_if_variable_is_defined $(echo $cluster | jq -c .cni_version) "   " "testing if each .vsphere_underlay.networks.alb.$network.k8s_clusters[] have a cni_version defined"
        test_if_variable_is_defined $(echo $cluster | jq -c .ako_version) "   " "testing if each .vsphere_underlay.networks.alb.$network.k8s_clusters[] have a ako_version defined"
        if [[ $(echo $cluster | jq -c -r .ako_version) == "1.10.1" ]] ; then
          echo "   +++ ako_version is $(echo $cluster | jq -c -r .ako_version) which is supported"
        else
          echo "   +++ ako_version $(echo $cluster | jq -c -r .ako_version) is not supported"
          exit 255
        fi
        test_if_variable_is_defined $(echo $cluster | jq -c .cluster_ips) "   " "testing if each .vsphere_underlay.networks.alb.$network.k8s_clusters[] have a cluster_ips defined"
        if [[ $(echo $cluster | jq -c -r '.cluster_ips | length') -lt 3 ]] ; then echo "   +++ Amount of cluster_ips should be higher than 3" ; exit 255 ; fi
        for ip in $(echo $cluster | jq -c -r .cluster_ips[])
        do
          test_if_variable_is_valid_ip "$ip" "   "
        done
      done
      variables_json=$(echo $variables_json | jq '. += {"unmanaged_k8s_status": true}')
    fi
  done
  #
  # vsphere_alb_wo_nsx
  #
  if [[ $(jq -c -r .avi $jsonFile) != "null" && $(jq -c -r .tanzu $jsonFile) == "null" ]]; then
    test_nsx_alb_variables "/etc/config/variables.json"
    echo ""
    echo "==> Adding .deployment: vsphere_alb_wo_nsx"
    variables_json=$(echo $variables_json | jq '. += {"deployment": "vsphere_alb_wo_nsx"}')
    mv /nestedVsphere8/02_external_gateway/external_gw_vsphere_tanzu_alb.tf.disabled /nestedVsphere8/02_external_gateway/external_gw_vsphere_tanzu_alb.tf
  fi
  #
  # vsphere_tanzu_alb_wo_nsx
  #
  if [[ $(jq -c -r .avi $jsonFile) != "null" && $(jq -c -r .tanzu $jsonFile) != "null" ]]; then
    test_nsx_alb_variables "/etc/config/variables.json"
    echo ""
    echo "==> Adding .deployment: vsphere_tanzu_alb_wo_nsx"
    variables_json=$(echo $variables_json | jq '. += {"deployment": "vsphere_tanzu_alb_wo_nsx"}')
    mv /nestedVsphere8/02_external_gateway/external_gw_vsphere_tanzu_alb.tf.disabled /nestedVsphere8/02_external_gateway/external_gw_vsphere_tanzu_alb.tf
  fi
fi
#
# Nested vSphere with NSX
#
if [[ $(jq -c -r .vsphere_underlay.networks.alb $jsonFile) == "null" && $(jq -c -r .nsx $jsonFile) != "null" ]]; then
  echo ""
  echo "==> Checking NSX Variables"
  echo "   +++ testing if environment variable TF_VAR_nsx_password is not empty" ; if [ -z "$TF_VAR_nsx_password" ] ; then  exit 255 ; fi
  echo "   +++ testing if environment variable TF_VAR_nsx_license is not empty" ; if [ -z "$TF_VAR_nsx_license" ] ; then exit 255 ; fi
  test_if_variable_is_valid_ip $(jq -c -r .vsphere_underlay.networks.vsphere.management.nsx_nested_ip $jsonFile) "   "
  test_if_json_variable_is_defined .vsphere_underlay.networks.vsphere.management.nsx_edge_nested_ips $jsonFile "   "
  for ip in $(jq -c -r .vsphere_underlay.networks.vsphere.management.nsx_edge_nested_ips[] $jsonFile)
  do
    test_if_variable_is_valid_ip $ip "   "
  done
  test_if_json_variable_is_defined .vsphere_underlay.networks.nsx.external.name $jsonFile "   "
  test_if_json_variable_is_defined .vsphere_underlay.networks.nsx.external.tier0_ips $jsonFile "   "
  test_if_variable_is_valid_cidr "$(jq -c -r .vsphere_underlay.networks.nsx.external.cidr $jsonFile)" "   "
  for ip in $(jq -c -r .vsphere_underlay.networks.nsx.external.tier0_ips[] $jsonFile)
  do
    test_if_variable_is_valid_ip $ip "   "
  done
  if [[ $(jq -c -r '.vsphere_underlay.networks.nsx.external.tier0_ips | length' $jsonFile) -lt $(jq -c -r '.nsx.config.tier0s | length' $jsonFile) ]] ; then
    echo "   +++ not enough IP defined in .vsphere_underlay.networks.nsx.external.tier0_ips for the amount of tier0s defined in .nsx.config.tier0s"
    exit 255
  fi
  test_if_json_variable_is_defined .vsphere_underlay.networks.nsx.external.tier0_vips $jsonFile "   "
  for ip in $(jq -c -r .vsphere_underlay.networks.nsx.external.tier0_vips[] $jsonFile)
  do
    test_if_variable_is_valid_ip $ip "   "
  done
  if [[ $(jq -c -r '.vsphere_underlay.networks.nsx.external.tier0_vips | length' $jsonFile) -lt $(jq -c -r '.nsx.config.edge_clusters | length' $jsonFile) ]] ; then
    echo "   +++ not enough IP defined in .vsphere_underlay.networks.nsx.external.tier0_vips for the amount of edge_cluster defined in .nsx.config.edge_clusters"
    exit 255
  fi
  test_if_variable_is_valid_ip $(jq -c -r .vsphere_underlay.networks.nsx.external.external_gw_ip $jsonFile) "   "
  test_if_json_variable_is_defined .vsphere_underlay.networks.nsx.overlay.name $jsonFile "   "
  test_if_variable_is_valid_cidr "$(jq -c -r .vsphere_underlay.networks.nsx.overlay.cidr $jsonFile)" "   "
  test_if_variable_is_valid_ip "$(jq -c -r .vsphere_underlay.networks.nsx.overlay.external_gw_ip $jsonFile)" "   "
  test_if_variable_is_valid_ip "$(jq -c -r .vsphere_underlay.networks.nsx.overlay.nsx_pool.start $jsonFile)" "   "
  test_if_variable_is_valid_ip "$(jq -c -r .vsphere_underlay.networks.nsx.overlay.nsx_pool.end $jsonFile)" "   "
  test_if_json_variable_is_defined .vsphere_underlay.networks.nsx.overlay_edge.name $jsonFile "   "
  test_if_variable_is_valid_cidr "$(jq -c -r .vsphere_underlay.networks.nsx.overlay_edge.cidr $jsonFile)" "   "
  test_if_variable_is_valid_ip "$(jq -c -r .vsphere_underlay.networks.nsx.overlay_edge.external_gw_ip $jsonFile)" "   "
  test_if_variable_is_valid_ip "$(jq -c -r .vsphere_underlay.networks.nsx.overlay_edge.nsx_pool.start $jsonFile)" "   "
  test_if_variable_is_valid_ip "$(jq -c -r .vsphere_underlay.networks.nsx.overlay_edge.nsx_pool.end $jsonFile)" "   "
  test_if_json_variable_is_defined .nsx.ova_url $jsonFile "   "
  test_if_json_variable_is_defined .nsx.config.edge_node.size $jsonFile "   "
  if [[ $(jq -c -r '.nsx.config.edge_node.size' $jsonFile | tr '[:upper:]' [:lower:]) != "small" \
        && $(jq -c -r '.nsx.config.edge_node.size' $jsonFile | tr '[:upper:]' [:lower:]) != "medium" \
        && $(jq -c -r '.nsx.config.edge_node.size' $jsonFile | tr '[:upper:]' [:lower:]) != "large" \
        && $(jq -c -r '.nsx.config.edge_node.size' $jsonFile | tr '[:upper:]' [:lower:]) != "extra_large" ]] ; then
          echo "   +++ .nsx.config.edge_node.size should equal to one of the following: 'small, medium, large, extra_large'"
          echo "   +++ https://docs.vmware.com/en/VMware-NSX/4.1/installation/GUID-22F87CA8-01A9-4F2E-B7DB-9350CA60EA4E.html#GUID-22F87CA8-01A9-4F2E-B7DB-9350CA60EA4E"
          exit 255
  fi
  # .nsx.config.edge_node
  test_if_json_variable_is_defined .nsx.config.edge_node.basename $jsonFile "   "
  edge_list=[]
  echo "   +++ testing if there is enough IP for edge node defined in .nsx.config.edge_clusters[].member_name[]"
  edge_amount=$(jq -c -r '.vsphere_underlay.networks.vsphere.management.nsx_edge_nested_ips | length' $jsonFile)
  for edge_cluster in $(jq -c -r .nsx.config.edge_clusters[] $jsonFile)
  do
    for member_name in $(echo $edge_cluster | jq -c -r .members_name[])
    do
      edge_list=$(echo $edge_list | jq '. += ["'$(echo $member_name)'"]')
    done
  done
  if [[ $(echo $edge_list | jq -c -r '. | length') -gt $(echo $edge_amount | jq -c -r '. | length') ]] ; then echo "   +++ Amount of Edge clusters defined in edge cluster greater than the amount of IPs defined in .vsphere_underlay.networks.vsphere.management.nsx_edge_nested_ips " ; exit 255 ; fi
  echo "   +++ testing if there is no duplicate in edge node in .nsx.config.edge_clusters[].member_name[]"
  for item in $(echo $edge_list | jq -c -r '. | group_by(.) | .[]')
  do
    if [[ $(echo $item | jq '.| length') -gt 1 ]]; then
      echo "   +++ Duplicate found in .nsx.config.edge_clusters[].member_name[] " ; exit 255 ; fi
  done
  echo "   +++ testing if .nsx.config.edge_clusters[].member_name[] are consistent with .nsx.config.edge_node.basename"
  for item in $(echo $edge_list | jq -c -r .[])
  do
    check_status=0
    for (( edge=1; edge<=$edge_amount ; edge++ ))
    do
      if [[ $item == "$(jq -c -r .nsx.config.edge_node.basename $jsonFile)$edge" ]] ; then check_status=1 ; fi
    done
    if [[ $check_status -eq 0 ]] ; then echo "   +++ Unable to find ref to edge node $item" ; exit 255 ; fi
  done
  # .nsx.config.tier0s
  test_if_json_variable_is_defined .nsx.config.tier0s $jsonFile "   "
  edge_cluster_name_list=[]
  for item in $(jq -c -r .nsx.config.tier0s[] $jsonFile)
  do
    test_if_variable_is_defined $(echo $item | jq -c .display_name) "   " "testing if each .nsx.config.tier0s[] have a display_name defined"
    edge_cluster_name_list=$(echo $edge_cluster_name_list | jq '. += ['$(echo $item | jq -c .edge_cluster_name)']')
  done
  echo "   +++ testing if each .nsx.config.tier0s[].edge_cluster_name is unique"
  for item in $(echo $edge_cluster_name_list | jq -c -r '. | group_by(.) | .[]')
  do
    if [[ $(echo $item | jq '.| length') -gt 1 ]]; then
      echo "   +++ Duplicate found in .nsx.config.tier0s[].edge_cluster_name " ; exit 255 ; fi
  done
  test_if_ref_from_list_exists_in_another_list ".nsx.config.tier0s[].edge_cluster_name" \
                                               ".nsx.config.edge_clusters[].display_name" \
                                               "$jsonFile" \
                                               "   +++ Checking edge_cluster_name in tiers 0" \
                                               "   ++++++  edge_cluster_name" \
                                               "   ++++++ERROR++++++ edge_cluster_name not found: "
  # .nsx.config.tier1s
  test_if_json_variable_is_defined .nsx.config.tier1s $jsonFile "   "
  for item in $(jq -c -r .nsx.config.tier1s[] $jsonFile)
  do
    test_if_variable_is_defined $(echo $item | jq -c .display_name) "   " "testing if each .nsx.config.tier1s[] have a display_name defined"
    test_if_variable_is_defined $(echo $item | jq -c .tier0) "   " "testing if each .nsx.config.tier1s[] have a tier0 defined"
  done
  test_if_ref_from_list_exists_in_another_list ".nsx.config.tier1s[].tier0" \
                                               ".nsx.config.tier0s[].display_name" \
                                               "$jsonFile" \
                                               "   +++ Checking Tiers 0 in tiers 1" \
                                               "   ++++++ Tier0 " \
                                               "   ++++++ERROR++++++ Tier0 not found: "
  # .nsx.config.segments_overlay
  test_if_json_variable_is_defined .nsx.config.segments_overlay $jsonFile "   "
  for item in $(jq -c -r .nsx.config.segments_overlay[] $jsonFile)
  do
    test_if_variable_is_defined $(echo $item | jq -c .display_name) "   " "testing if each .nsx.config.segments_overlay[] have a display_name defined"
    test_if_variable_is_defined $(echo $item | jq -c .tier1) "   " "testing if each .nsx.config.segments_overlay[] have a tier1 defined"
    test_if_variable_is_valid_cidr "$(echo $item | jq -c -r .cidr)" "   "
    test_if_variable_is_defined $(echo $item | jq -c .dhcp_ranges) "   " "testing if each .nsx.config.segments_overlay[] have a dhcp_ranges defined"
    for dhcp_range in $(echo $item | jq -c -r .dhcp_ranges[])
    do
      test_if_variable_is_valid_ip "$(echo $dhcp_range | cut -d"-" -f1 )" "   "
      test_if_variable_is_valid_ip "$(echo $dhcp_range | cut -d"-" -f2 )" "   "
    done
  done
  if [[ $(jq -c -r '.nsx.config.segments_overlay[].display_name' $jsonFile | uniq -d) != "" ]] ; then
    echo "      ++++++ ERROR .nsx.config.segments_overlay[].display_name has a duplicate value"
    exit 255
  fi
  test_if_ref_from_list_exists_in_another_list ".nsx.config.segments_overlay[].tier1" \
                                               ".nsx.config.tier1s[].display_name" \
                                               "$jsonFile" \
                                               "   +++ Checking Tiers 1 in segments_overlay" \
                                               "   ++++++ Tier1 " \
                                               "   ++++++ERROR++++++ Tier1 not found: "
  #
  # vsphere_nsx
  #
  if [[ $(jq -c -r .avi $jsonFile) == "null" ]]; then
    echo ""
    echo "==> Adding .deployment: vsphere_nsx"
    variables_json=$(echo $variables_json | jq '. += {"deployment": "vsphere_nsx"}')
  fi
  #
  # vsphere_nsx_alb_telco
  #
  if [[ $(jq -c -r .avi.config.cloud.type $jsonFile) == "CLOUD_VCENTER" && $(jq -c -r .vcd $jsonFile) == "null" && $(jq -c -r .tkg $jsonFile) != "null" ]]; then
    test_nsx_alb_variables "/etc/config/variables.json"
    test_nsx_k8s_variables "/etc/config/variables.json"
    test_alb_variables_if_vsphere_nsx_alb_telco "/etc/config/variables.json"
    echo ""
    echo "==> Adding .deployment: vsphere_nsx_alb_telco"
    variables_json=$(echo $variables_json | jq '. += {"deployment": "vsphere_nsx_alb_telco"}')
  fi
  #
  # vsphere_nsx_alb
  #
  if [[ $(jq -c -r .avi.config.cloud.type $jsonFile) == "CLOUD_NSXT" && $(jq -c -r .tanzu $jsonFile) == "null" && $(jq -c -r .vcd $jsonFile) == "null" ]]; then
    test_nsx_alb_variables "/etc/config/variables.json"
    test_nsx_app_variables "/etc/config/variables.json"
    test_nsx_k8s_variables "/etc/config/variables.json"
    test_alb_variables_if_nsx_cloud "/etc/config/variables.json"
    echo ""
    echo "==> Adding .deployment: vsphere_nsx_alb"
    variables_json=$(echo $variables_json | jq '. += {"deployment": "vsphere_nsx_alb"}')
  fi
  #
  # vsphere_nsx_tanzu_alb
  #
  if [[ $(jq -c -r .avi.config.cloud.type $jsonFile) == "CLOUD_NSXT" && $(jq -c -r .tanzu $jsonFile) != "null" && $(jq -c -r .vcd $jsonFile) == "null" ]]; then
    test_nsx_alb_variables "/etc/config/variables.json"
    test_nsx_app_variables "/etc/config/variables.json"
    test_nsx_k8s_variables "/etc/config/variables.json"
    test_alb_variables_if_nsx_cloud "/etc/config/variables.json"
    echo ""
    echo "==> Adding .deployment: vsphere_nsx_tanzu_alb"
    variables_json=$(echo $variables_json | jq '. += {"deployment": "vsphere_nsx_tanzu_alb"}')
  fi
  #
  # vsphere_nsx_alb_vcd
  #
  if [[ $(jq -c -r .avi.config.cloud.type $jsonFile) == "CLOUD_NSXT" && $(jq -c -r .tanzu $jsonFile) == "null" && $(jq -c -r .vcd $jsonFile) != "null" ]]; then
    test_nsx_alb_variables "/etc/config/variables.json"
    test_nsx_app_variables "/etc/config/variables.json"
    test_nsx_k8s_variables "/etc/config/variables.json"
    test_alb_variables_if_nsx_cloud "/etc/config/variables.json"
    echo ""
    echo "==> Checking VCD Variables"
    test_if_variable_is_valid_ip $(jq -c -r .vsphere_underlay.networks.vsphere.management.avi_nested_ip $jsonFile) "   "
    test_if_variable_is_valid_ip $(jq -c -r .vsphere_underlay.networks.vsphere.management.vcd_nested_ip $jsonFile) "   "
    test_if_variable_is_valid_ip $(jq -c -r .vsphere_underlay.networks.vsphere.vsan.vcd_nested_ip $jsonFile) "   "
    test_if_json_variable_is_defined .vcd.ova_url $jsonFile "   "
    echo ""
    echo "==> Adding .deployment: vsphere_nsx_alb_vcd"
    variables_json=$(echo $variables_json | jq '. += {"deployment": "vsphere_nsx_alb_vcd"}')
  fi
fi
#
echo $variables_json | jq . | tee /root/variables.json > /dev/null