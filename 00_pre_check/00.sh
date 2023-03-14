#!/bin/bash
#
source /nestedVsphere8/bash/test_if_variables.sh
#
jsonFile="/etc/config/variables.json"
#
#
echo ""
echo "==> Checking Environment Variables"
if [ -z "$TF_VAR_vsphere_underlay_username" ] ; then  echo "   +++ testing if '$TF_VAR_vsphere_underlay_username' is not empty" ; exit 255 ; fi
if [ -z "$TF_VAR_vsphere_underlay_password" ] ; then  echo "   +++ testing if '$TF_VAR_vsphere_underlay_password' is not empty" ; exit 255 ; fi
if [ -z "$TF_VAR_ubuntu_password" ] ; then  echo "   +++ testing if '$TF_VAR_ubuntu_password' is not empty" ; exit 255 ; fi
if [ -z "$TF_VAR_bind_password" ] ; then  echo "   +++ testing if '$TF_VAR_bind_password' is not empty" ; exit 255 ; fi
if [ -z "$TF_VAR_nested_esxi_root_password" ] ; then  echo "   +++ testing if '$TF_VAR_nested_esxi_root_password' is not empty" ; exit 255 ; fi
if [ -z "$TF_VAR_vsphere_nested_password" ] ; then  echo "   +++ testing if '$TF_VAR_vsphere_nested_password' is not empty" ; exit 255 ; fi
if [[ $(jq -c -r .nsx $jsonFile) != "null" ]]; then
  if [ -z "$TF_VAR_nsx_password" ] ; then  echo "   +++ testing if '$TF_VAR_nsx_password' is not empty" ; exit 255 ; fi
  if [ -z "$TF_VAR_nsx_license" ] ; then  echo "   +++ testing if '$TF_VAR_nsx_license' is not empty" ; exit 255 ; fi
fi
if [[ $(jq -c -r .avi $jsonFile) != "null" ]]; then
  if [ -z "$TF_VAR_avi_password" ] ; then  echo "   +++ testing if '$TF_VAR_avi_password' is not empty" ; exit 255 ; fi
  if [ -z "$TF_VAR_avi_old_password" ] ; then  echo "   +++ testing if '$TF_VAR_avi_old_password' is not empty" ; exit 255 ; fi
fi
#
#
#
IFS=$'\n'
echo ""
echo "==> Checking vSphere Underlay Variables"
test_if_json_variable_is_defined .vsphere_underlay.datacenter $jsonFile "   "
test_if_json_variable_is_defined .vsphere_underlay.cluster $jsonFile "   "
test_if_json_variable_is_defined .vsphere_underlay.datastore $jsonFile "   "
test_if_json_variable_is_defined .vsphere_underlay.folder $jsonFile "   "
test_if_json_variable_is_defined .vsphere_underlay.vcsa $jsonFile "   "
test_if_json_variable_is_defined .vsphere_underlay.networks.vsphere.management.name $jsonFile "   "
test_if_json_variable_is_defined .vsphere_underlay.networks.vsphere.management.netmask $jsonFile "   "
test_if_json_variable_is_defined .vsphere_underlay.networks.vsphere.management.gateway $jsonFile "   "
test_if_json_variable_is_defined .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile "   "
test_if_variable_is_valid_ip $(jq -c -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile) "   "
test_if_json_variable_is_defined .vsphere_underlay.networks.vsphere.management.esxi_ips $jsonFile "   "
for ip in $(jq -c -r .vsphere_underlay.networks.vsphere.management.esxi_ips[] $jsonFile)
do
  test_if_variable_is_valid_ip $ip "   "
done
test_if_json_variable_is_defined .vsphere_underlay.networks.vsphere.management.esxi_ips_temp $jsonFile "   "
for ip in $(jq -c -r .vsphere_underlay.networks.vsphere.management.esxi_ips_temp[] $jsonFile)
do
  test_if_variable_is_valid_ip $ip "   "
done
test_if_json_variable_is_defined .vsphere_underlay.networks.vsphere.management.vcsa_nested_ip $jsonFile "   "
test_if_variable_is_valid_ip $(jq -c -r .vsphere_underlay.networks.vsphere.management.vcsa_nested_ip $jsonFile) "   "
test_if_json_variable_is_defined .vsphere_underlay.networks.vsphere.vmotion.name $jsonFile "   "
test_if_json_variable_is_defined .vsphere_underlay.networks.vsphere.vmotion.esxi_ips $jsonFile "   "
for ip in $(jq -c -r .vsphere_underlay.networks.vsphere.vmotion.esxi_ips[] $jsonFile)
do
  test_if_variable_is_valid_ip $ip "   "
done
test_if_json_variable_is_defined .vsphere_underlay.networks.vsphere.vsan.name $jsonFile "   "
test_if_json_variable_is_defined .vsphere_underlay.networks.vsphere.vsan.esxi_ips $jsonFile "   "
for ip in $(jq -c -r .vsphere_underlay.networks.vsphere.vsan.esxi_ips[] $jsonFile)
do
  test_if_variable_is_valid_ip $ip "   "
done
# NSX
if [[ $(jq -c -r .nsx $jsonFile) != "null" ]]; then
  test_if_variable_is_valid_ip $(jq -c -r .vsphere_underlay.networks.vsphere.management.nsx_nested_ip $jsonFile) "   "
  test_if_json_variable_is_defined .vsphere_underlay.networks.vsphere.management.nsx_edge_nested_ips $jsonFile "   "
  for ip in $(jq -c -r .vsphere_underlay.networks.vsphere.management.nsx_edge_nested_ips[] $jsonFile)
  do
    test_if_variable_is_valid_ip $ip "   "
  done
  test_if_json_variable_is_defined .vsphere_underlay.networks.nsx.external.name $jsonFile "   "
  test_if_json_variable_is_defined .vsphere_underlay.networks.nsx.external.netmask $jsonFile "   "
  test_if_json_variable_is_defined .vsphere_underlay.networks.nsx.external.tier0_ips $jsonFile "   "
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
  test_if_variable_is_valid_cidr "$(jq -c -r .vsphere_underlay.networks.nsx.overlay.nsx_pool.cidr $jsonFile)" "   "
  test_if_variable_is_valid_ip "$(jq -c -r .vsphere_underlay.networks.nsx.overlay.nsx_pool.gateway $jsonFile)" "   "
  test_if_variable_is_valid_ip "$(jq -c -r .vsphere_underlay.networks.nsx.overlay.nsx_pool.start $jsonFile)" "   "
  test_if_variable_is_valid_ip "$(jq -c -r .vsphere_underlay.networks.nsx.overlay.nsx_pool.end $jsonFile)" "   "
  test_if_json_variable_is_defined .vsphere_underlay.networks.nsx.overlay_edge.name $jsonFile "   "
  test_if_variable_is_valid_cidr "$(jq -c -r .vsphere_underlay.networks.nsx.overlay_edge.nsx_pool.cidr $jsonFile)" "   "
  test_if_variable_is_valid_ip "$(jq -c -r .vsphere_underlay.networks.nsx.overlay_edge.nsx_pool.gateway $jsonFile)" "   "
  test_if_variable_is_valid_ip "$(jq -c -r .vsphere_underlay.networks.nsx.overlay_edge.nsx_pool.start $jsonFile)" "   "
  test_if_variable_is_valid_ip "$(jq -c -r .vsphere_underlay.networks.nsx.overlay_edge.nsx_pool.end $jsonFile)" "   "
fi
# AVI
if [[ $(jq -c -r .avi $jsonFile) != "null" ]]; then
  test_if_variable_is_valid_ip $(jq -c -r .vsphere_underlay.networks.vsphere.management.avi_nested_ip $jsonFile) "   "
fi
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
#
#
if [[ $(jq -c -r .nsx $jsonFile) != "null" ]]; then
  echo ""
  echo "==> Checking NSX Variables"
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
  done
  test_if_ref_from_list_exists_in_another_list ".nsx.config.segments_overlay[].tier1" \
                                               ".nsx.config.tier1s[].display_name" \
                                               "$jsonFile" \
                                               "   +++ Checking Tiers 1 in segments_overlay" \
                                               "   ++++++ Tier1 " \
                                               "   ++++++ERROR++++++ Tier1 not found: "
fi
#
#
#
if [[ $(jq -c -r .avi $jsonFile) != "null" ]]; then
  echo ""
  echo "==> Checking NSX ALB Variables with or without NSX"
  test_if_json_variable_is_defined .avi.ova_url $jsonFile "   "
  test_if_json_variable_is_defined .avi.cpu $jsonFile "   "
  test_if_json_variable_is_defined .avi.memory $jsonFile "   "
  test_if_json_variable_is_defined .avi.disk $jsonFile "   "
  test_if_json_variable_is_defined .avi.version $jsonFile "   "
  #
  if [[ $(jq -c -r .nsx $jsonFile) != "null" ]]; then
    echo ""
    echo "==> Checking NSX Apps with NSX"
    # .nsx.config.segments_overlay[].app_ips
    count=0
    for item in $(jq -c -r .nsx.config.segments_overlay[] $jsonFile)
    do
      if [[ $(echo $item | jq -c .app_ips) != "null" ]] ; then
        ((count++))
        for ip in $(echo $item | jq .app_ips[] -c -r)
        do
          test_if_variable_is_valid_ip "$ip" "   "
        done
      fi
    done
    if [[ $count -eq 0 ]] ; then echo "   +++ .nsx.config.segments_overlay[].app_ips has to be defined at least once to locate where the App servers will be installed" ; exit 255 ; fi
    echo ""
    echo "==> Checking ALB with NSX Cloud type"
    if [[ $(jq -c -r .avi.config.cloud.type $jsonFile) == "CLOUD_NSXT" ]]; then
      test_if_json_variable_is_defined .avi.config.cloud.networks_data $jsonFile "   "
      test_if_json_variable_is_defined .avi.config.cloud.name $jsonFile "   "
      test_if_json_variable_is_defined .avi.config.cloud.type $jsonFile "   "
      test_if_json_variable_is_defined .avi.config.cloud.obj_name_prefix $jsonFile "   "
      # .avi.config.cloud.network_management
      test_if_json_variable_is_defined .avi.config.cloud.network_management.name $jsonFile "   "
      avi_cloud_network=0
      for segment in $(jq -c -r .nsx.config.segments_overlay[] $jsonFile)
      do
        if [[ $(echo $segment | jq -r .display_name) == $(jq -c -r .avi.config.cloud.network_management.name $jsonFile) ]] ; then
          avi_cloud_network=1
          echo "   ++++++ Avi cloud network found in NSX overlay segments: $(echo $segment | jq -r .display_name), OK"
        fi
      done
      if [[ $avi_cloud_network -eq 0 ]] ; then
        echo "   ++++++ERROR++++++ $(echo $network | jq -c -r .name) segment not found!!"
        exit 255
      fi
      test_if_variable_is_valid_ip "$(jq -c -r .avi.config.cloud.network_management.avi_ipam_pool_se $jsonFile | cut -d"-" -f1 )" "   "
      test_if_variable_is_valid_ip "$(jq -c -r .avi.config.cloud.network_management.avi_ipam_pool_se $jsonFile | cut -d"-" -f2 )" "   "
      # .avi.config.cloud.networks_data[]
      for item in $(jq -c -r .avi.config.cloud.networks_data[] $jsonFile)
      do
        test_if_variable_is_defined $(echo $item | jq -c .name) "   " "testing if each .avi.config.cloud.networks_data[] have a name defined"
        test_if_variable_is_valid_ip "$(echo $item | jq -c -r .avi_ipam_pool_se | cut -d"-" -f1 )" "   "
        test_if_variable_is_valid_ip "$(echo $item | jq -c -r .avi_ipam_pool_se | cut -d"-" -f2 )" "   "
        test_if_variable_is_valid_cidr "$(echo $item | jq -c -r .avi_ipam_vip.cidr)" "   "
        test_if_variable_is_valid_ip "$(echo $item | jq -c -r .avi_ipam_vip.pool | cut -d"-" -f1 )" "   "
        test_if_variable_is_valid_ip "$(echo $item | jq -c -r .avi_ipam_vip.pool | cut -d"-" -f2 )" "   "
      done
      test_if_ref_from_list_exists_in_another_list ".avi.config.cloud.networks_data[].name" \
                                                   ".nsx.config.segments_overlay[].display_name" \
                                                   "$jsonFile" \
                                                   "   +++ Checking name in .avi.config.cloud.networks_data" \
                                                   "   ++++++ Segment " \
                                                   "   ++++++ERROR++++++ Segment not found: "
      # .avi.config.cloud.service_engine_groups[]
      for item in $(jq -c -r .avi.config.cloud.service_engine_groups[] $jsonFile)
      do
        test_if_variable_is_defined $(echo $item | jq -c .name) "   " "testing if each .avi.config.cloud.service_engine_groups[] have a name defined"
      done
      #
      if [[ $(jq -c -r .avi.config.cloud.virtual_services.dns $jsonFile) != "null" ]]; then
        for item in $(jq -c -r .avi.config.cloud.virtual_services.dns[] $jsonFile)
        do
          test_if_variable_is_defined $(echo $item | jq -c .name) "   " "testing if each .avi.config.cloud.virtual_services.dns[] have a name defined"
          test_if_variable_is_defined $(echo $item | jq -c .network_ref) "   " "testing if each .avi.config.cloud.virtual_services.dns[] have a network_ref defined"
          test_if_ref_from_list_exists_in_another_list ".avi.config.cloud.virtual_services.dns[].network_ref" \
                                                       ".nsx.config.segments_overlay[].display_name" \
                                                       "$jsonFile" \
                                                       "   +++ Checking network_ref in .avi.config.cloud.virtual_services.dns" \
                                                       "   ++++++ Segment " \
                                                       "   ++++++ERROR++++++ Segment not found: "
          test_if_variable_is_defined $(echo $item | jq -c .se_group_ref) "   " "testing if each .avi.config.cloud.virtual_services.dns[] have a se_group_ref defined"
          test_if_ref_from_list_exists_in_another_list ".avi.config.cloud.virtual_services.dns[].se_group_ref" \
                                                       ".avi.config.cloud.service_engine_groups[].name" \
                                                       "$jsonFile" \
                                                       "   +++ Checking se_group_ref in .avi.config.cloud.virtual_services.dns" \
                                                       "   ++++++ Service Engine Group " \
                                                       "   ++++++ERROR++++++ ervice Engine Group not found: "
          for service in $(echo $item | jq -c -r .services[])
          do
            test_if_variable_is_defined $(echo $service | jq -c .port) "   " "testing if each .avi.config.cloud.virtual_services.dns[].services have a port defined"
          done
        done
      fi
    fi
  fi
fi

