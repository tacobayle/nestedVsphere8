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
#
#
#
IFS=$'\n'
echo ""
echo "==> Checking vSphere Underlay Variables"
test_if_json_variable_is_defined .vcenter_underlay.dc $jsonFile "   "
test_if_json_variable_is_defined .vcenter_underlay.cluster $jsonFile "   "
test_if_json_variable_is_defined .vcenter_underlay.datastore $jsonFile "   "
test_if_json_variable_is_defined .vcenter_underlay.folder $jsonFile "   "
test_if_json_variable_is_defined .vcenter_underlay.server $jsonFile "   "
test_if_json_variable_is_defined .vcenter_underlay.networks.vsphere.management.name $jsonFile "   "
test_if_json_variable_is_defined .vcenter_underlay.networks.vsphere.management.netmask $jsonFile "   "
test_if_json_variable_is_defined .vcenter_underlay.networks.vsphere.management.gateway $jsonFile "   "
test_if_json_variable_is_defined .vcenter_underlay.networks.vsphere.management.external_gw_ip $jsonFile "   "
test_if_variable_is_valid_ip $(jq -c -r .vcenter_underlay.networks.vsphere.management.external_gw_ip $jsonFile) "   "
test_if_json_variable_is_defined .vcenter_underlay.networks.vsphere.management.esxi_ips $jsonFile "   "
for ip in $(jq -c -r .vcenter_underlay.networks.vsphere.management.esxi_ips[] $jsonFile)
do
  test_if_variable_is_valid_ip $ip "   "
done
test_if_json_variable_is_defined .vcenter_underlay.networks.vsphere.management.esxi_ips_temp $jsonFile "   "
for ip in $(jq -c -r .vcenter_underlay.networks.vsphere.management.esxi_ips_temp[] $jsonFile)
do
  test_if_variable_is_valid_ip $ip "   "
done
test_if_json_variable_is_defined .vcenter_underlay.networks.vsphere.management.vcenter_ip $jsonFile "   "
test_if_variable_is_valid_ip $(jq -c -r .vcenter_underlay.networks.vsphere.management.vcenter_ip $jsonFile) "   "
test_if_json_variable_is_defined .vcenter_underlay.networks.vsphere.vmotion.name $jsonFile "   "
test_if_json_variable_is_defined .vcenter_underlay.networks.vsphere.vmotion.esxi_ips $jsonFile "   "
for ip in $(jq -c -r .vcenter_underlay.networks.vsphere.vmotion.esxi_ips[] $jsonFile)
do
  test_if_variable_is_valid_ip $ip "   "
done
test_if_json_variable_is_defined .vcenter_underlay.networks.vsphere.vsan.name $jsonFile "   "
test_if_json_variable_is_defined .vcenter_underlay.networks.vsphere.vsan.esxi_ips $jsonFile "   "
for ip in $(jq -c -r .vcenter_underlay.networks.vsphere.vsan.esxi_ips[] $jsonFile)
do
  test_if_variable_is_valid_ip $ip "   "
done
if [[ $(jq -c -r .nsx $jsonFile) != "null" ]]; then
  test_if_variable_is_valid_ip $(jq -c -r .vcenter_underlay.networks.vsphere.management.nsx_ip $jsonFile) "   "
  test_if_json_variable_is_defined .vcenter_underlay.networks.vsphere.management.nsx_edge $jsonFile "   "
  for ip in $(jq -c -r .vcenter_underlay.networks.vsphere.management.nsx_edge[] $jsonFile)
  do
    test_if_variable_is_valid_ip $ip "   "
  done
  test_if_json_variable_is_defined .vcenter_underlay.networks.nsx.external.name $jsonFile "   "
  test_if_json_variable_is_defined .vcenter_underlay.networks.nsx.external.netmask $jsonFile "   "
  test_if_json_variable_is_defined .vcenter_underlay.networks.nsx.external.tier0_ips $jsonFile "   "
  for ip in $(jq -c -r .vcenter_underlay.networks.nsx.external.tier0_ips[] $jsonFile)
  do
    test_if_variable_is_valid_ip $ip "   "
  done
  if [[ $(jq -c -r '.vcenter_underlay.networks.nsx.external.tier0_ips | length' $jsonFile) -lt $(jq -c -r '.nsx.config.tier0s | length' $jsonFile) ]] ; then
    echo "   +++ not enough IP defined in .vcenter_underlay.networks.nsx.external.tier0_ips for the amount of tier0s defined in .nsx.config.tier0s"
    exit 255
  fi
  test_if_json_variable_is_defined .vcenter_underlay.networks.nsx.external.tier0_vips $jsonFile "   "
  for ip in $(jq -c -r .vcenter_underlay.networks.nsx.external.tier0_vips[] $jsonFile)
  do
    test_if_variable_is_valid_ip $ip "   "
  done
  if [[ $(jq -c -r '.vcenter_underlay.networks.nsx.external.tier0_vips | length' $jsonFile) -lt $(jq -c -r '.nsx.config.edge_clusters | length' $jsonFile) ]] ; then
    echo "   +++ not enough IP defined in .vcenter_underlay.networks.nsx.external.tier0_vips for the amount of edge_cluster defined in .nsx.config.edge_clusters"
    exit 255
  fi
  test_if_variable_is_valid_ip $(jq -c -r .vcenter_underlay.networks.nsx.external.external_gw_ip $jsonFile) "   "
  test_if_json_variable_is_defined .vcenter_underlay.networks.nsx.overlay.name $jsonFile "   "
  test_if_variable_is_valid_cidr "$(jq -c -r .vcenter_underlay.networks.nsx.overlay.nsx_pool.cidr $jsonFile)" "   "
  test_if_variable_is_valid_ip "$(jq -c -r .vcenter_underlay.networks.nsx.overlay.nsx_pool.gateway $jsonFile)" "   "
  test_if_variable_is_valid_ip "$(jq -c -r .vcenter_underlay.networks.nsx.overlay.nsx_pool.start $jsonFile)" "   "
  test_if_variable_is_valid_ip "$(jq -c -r .vcenter_underlay.networks.nsx.overlay.nsx_pool.end $jsonFile)" "   "
  #test_if_json_variable_is_defined .vcenter_underlay.networks.nsx.overlay.netmask $jsonFile "   "
  #test_if_variable_is_valid_ip "$(jq -c -r .vcenter_underlay.networks.nsx.overlay.network_prefix $jsonFile)" "   "
  #test_if_variable_is_valid_ip $(jq -c -r .vcenter_underlay.networks.nsx.overlay.external_gw_ip $jsonFile) "   "
  test_if_json_variable_is_defined .vcenter_underlay.networks.nsx.overlay_edge.name $jsonFile "   "
  test_if_variable_is_valid_cidr "$(jq -c -r .vcenter_underlay.networks.nsx.overlay_edge.nsx_pool.cidr $jsonFile)" "   "
  test_if_variable_is_valid_ip "$(jq -c -r .vcenter_underlay.networks.nsx.overlay_edge.nsx_pool.gateway $jsonFile)" "   "
  test_if_variable_is_valid_ip "$(jq -c -r .vcenter_underlay.networks.nsx.overlay_edge.nsx_pool.start $jsonFile)" "   "
  test_if_variable_is_valid_ip "$(jq -c -r .vcenter_underlay.networks.nsx.overlay_edge.nsx_pool.end $jsonFile)" "   "
  #test_if_json_variable_is_defined .vcenter_underlay.networks.nsx.overlay_edge.netmask $jsonFile "   "
  #test_if_variable_is_valid_ip "$(jq -c -r .vcenter_underlay.networks.nsx.overlay_edge.network_prefix $jsonFile)" "   "
  #test_if_variable_is_valid_ip $(jq -c -r .vcenter_underlay.networks.nsx.overlay_edge.external_gw_ip $jsonFile) "   "
fi
#
#
#
echo ""
echo "==> Checking External Gateway Variables"
test_if_json_variable_is_defined .external_gw.cpu $jsonFile "   "
test_if_json_variable_is_defined .external_gw.memory $jsonFile "   "
test_if_json_variable_is_defined .external_gw.disk $jsonFile "   "
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
test_if_json_variable_is_defined .vcenter.name $jsonFile "   "
test_if_json_variable_is_defined .vcenter.iso_url $jsonFile "   "
test_if_json_variable_is_defined .vcenter.esxi.iso_url $jsonFile "   "
test_if_json_variable_is_defined .vcenter.datacenter $jsonFile "   "
test_if_json_variable_is_defined .vcenter.cluster $jsonFile "   "
test_if_json_variable_is_defined .vcenter.timezone $jsonFile "   "
test_if_json_variable_is_defined .vcenter.esxi.iso_url $jsonFile "   "
test_if_json_variable_is_defined .vcenter.esxi.basename $jsonFile "   "
test_if_json_variable_is_defined .vcenter.esxi.cpu $jsonFile "   "
test_if_json_variable_is_defined .vcenter.esxi.memory $jsonFile "   "
test_if_json_variable_is_defined .vcenter.esxi.disks $jsonFile "   "
if [[ $(jq -c -r '.vcenter.esxi.disks | length' $jsonFile) -ne 3 ]] ; then echo "   +++ 3 ESXi host's disks must be configured" ; exit 255 ; fi
#
#
#
if [[ $(jq -c -r .nsx $jsonFile) != "null" ]]; then
  echo ""
  echo "==> Checking NSX Variables"
  test_if_json_variable_is_defined .nsx.ova_url $jsonFile "   "
  edge_list=[]
  echo "   +++ testing if there is enough IP for edge node defined in .nsx.config.edge_clusters[].member_name[]"
  edge_amount=$(jq -c -r '.vcenter_underlay.networks.vsphere.management.nsx_edge | length' $jsonFile)
  for edge_cluster in $(jq -c -r .nsx.config.edge_clusters[] $jsonFile)
  do
    for member_name in $(echo $edge_cluster | jq -c -r .members_name[])
    do
      edge_list=$(echo $edge_list | jq '. += ["'$(echo $member_name)'"]')
    done
  done
  if [[ $(echo $edge_list | jq -c -r '. | length') -gt $(echo $edge_amount | jq -c -r '. | length') ]] ; then echo "   +++ Amount of Edge clusters defined in edge cluster greater than the amount of IPs defined in .vcenter_underlay.networks.vsphere.management.nsx_edge " ; exit 255 ; fi
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
  for item in $(jq -c -r .nsx.config.tier0s[] $jsonFile)
  do
    test_if_variable_is_defined $(echo $item | jq -c .display_name) "   " "testing if each .nsx.config.tier0s[] have a display_name defined"
    test_if_ref_from_list_exists_in_another_list ".nsx.config.tier0s[].edge_cluster_name" \
                                                 ".nsx.config.edge_clusters[].display_name" \
                                                 "$jsonFile" \
                                                 "   +++ Checking edge_cluster_name in tiers 0" \
                                                 "   ++++++  edge_cluster_name" \
                                                 "   ++++++ERROR++++++ edge_cluster_name not found: "
  done
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

  test_if_json_variable_is_defined .nsx.config.tier0s $jsonFile "   "
  for item in $(jq -c -r .nsx.config.tier0s[] $jsonFile)
  do
    test_if_variable_is_defined "$(echo $item | jq -c .display_name)" "   " "testing if each .nsx.config.tier0s[] have a display_name defined"
  done

  #
  #
  if [[ $(jq -c -r .nsx.avi $jsonFile) != "null" ]]; then
  echo ""
  echo "==> Checking NSX ALB Variables"
  test_if_json_variable_is_defined .nsx.avi.ova_url $jsonFile "   "
  test_if_json_variable_is_defined .nsx.avi.config.cloud.networks_data $jsonFile "   "
  for item in $(jq -c -r .nsx.avi.config.cloud.networks_data[] $jsonFile)
  do
    test_if_variable_is_valid_cidr "$(echo $item | jq -c -r .avi_ipam_vip.cidr)" "   "
  done
  fi
fi