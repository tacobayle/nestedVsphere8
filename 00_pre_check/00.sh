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
  test_if_json_variable_is_defined .vcenter_underlay.networks.vsphere.management.nsx_ip $jsonFile "   "
  test_if_json_variable_is_defined .vcenter_underlay.networks.nsx.external.name $jsonFile "   "
  test_if_json_variable_is_defined .vcenter_underlay.networks.nsx.external.netmask $jsonFile "   "
  test_if_json_variable_is_defined .vcenter_underlay.networks.nsx.external.tier0_vips $jsonFile "   "
  for ip in $(jq -c -r .vcenter_underlay.networks.nsx.external.tier0_vips[] $jsonFile)
  do
    test_if_variable_is_valid_ip $ip "   "
  done
  test_if_variable_is_valid_ip $(jq -c -r .vcenter_underlay.networks.nsx.external.external_gw_ip $jsonFile) "   "
  test_if_json_variable_is_defined .vcenter_underlay.networks.nsx.overlay.name $jsonFile "   "
  #test_if_json_variable_is_defined .vcenter_underlay.networks.nsx.overlay.netmask $jsonFile "   "
  #test_if_variable_is_valid_ip "$(jq -c -r .vcenter_underlay.networks.nsx.overlay.network_prefix $jsonFile)" "   "
  #test_if_variable_is_valid_ip $(jq -c -r .vcenter_underlay.networks.nsx.overlay.external_gw_ip $jsonFile) "   "
  test_if_json_variable_is_defined .vcenter_underlay.networks.nsx.overlay_edge.name $jsonFile "   "
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
test_if_json_variable_is_defined .vcenter.datacenter $jsonFile "   "
test_if_json_variable_is_defined .vcenter.cluster $jsonFile "   "
test_if_json_variable_is_defined .vcenter.timezone $jsonFile "   "
test_if_json_variable_is_defined .vcenter.esxi.iso_url $jsonFile "   "
test_if_json_variable_is_defined .vcenter.esxi.basename $jsonFile "   "
test_if_json_variable_is_defined .vcenter.esxi.cpu $jsonFile "   "
test_if_json_variable_is_defined .vcenter.esxi.memory $jsonFile "   "
test_if_json_variable_is_defined .vcenter.esxi.disks $jsonFile "   "
if [[ $(jq -c -r '.vcenter.esxi.disks | length' $jsonFile) -ne 3 ]] ; then echo "   +++ 3 ESXi host's disks must be configured" ; exut 255 ; fi
#
#
#
if [[ $(jq -c -r .nsx $jsonFile) != "null" ]]; then
  echo ""
  echo "==> Checking NSX Variables"
  test_if_json_variable_is_defined .nsx.config.uplink_profiles $jsonFile "   "
  test_if_json_variable_is_defined .nsx.config.transport_zones $jsonFile "   "
  test_if_json_variable_is_defined .nsx.config.ip_pools $jsonFile "   "
  if [[ $(jq -c -r '.nsx.config.ip_pools | length' $jsonFile) -ne 2 ]] ; then echo "   +++ 2 NSX ip_pools must be configured" ; exut 255 ; fi
  for item in $(jq -c -r .nsx.config.ip_pools[] $jsonFile)
  do
    test_if_variable_is_defined $(echo $item | jq -c .name) "   " "testing if each .nsx.config.ip_pools[] have a name defined"
    test_if_variable_is_valid_cidr "$(echo $item | jq -c -r .cidr)" "   "
    test_if_variable_is_valid_ip "$(echo $item | jq -c -r .gateway)" "   "
    test_if_variable_is_valid_ip "$(echo $item | jq -c -r .start)" "   "
    test_if_variable_is_valid_ip "$(echo $item | jq -c -r .end)" "   "

  done
  test_if_json_variable_is_defined .nsx.config.segments_overlay $jsonFile "   "
  for item in $(jq -c -r .nsx.config.segments_overlay[] $jsonFile)
  do
    test_if_variable_is_defined $(echo $item | jq -c .tier1) "   " "testing if each .nsx.config.segments_overlay[] have a tier1 defined"
  done
  test_if_json_variable_is_defined .nsx.config.tier1s $jsonFile "   "
  for item in $(jq -c -r .nsx.config.tier1s[] $jsonFile)
  do
    test_if_variable_is_defined $(echo $item | jq -c .display_name) "   " "testing if each .nsx.config.tier1s[] have a display_name defined"
    test_if_variable_is_defined $(echo $item | jq -c .tier0) "   " "testing if each .nsx.config.tier1s[] have a tier0 defined"
  done
  test_if_json_variable_is_defined .nsx.config.tier0s $jsonFile "   "
  for item in $(jq -c -r .nsx.config.tier0s[] $jsonFile)
  do
    test_if_variable_is_defined "$(echo $item | jq -c .display_name)" "   " "testing if each .nsx.config.tier0s[] have a display_name defined"
  done
  test_if_ref_from_list_exists_in_another_list ".nsx.config.tier1s[].tier0" \
                                               ".nsx.config.tier0s[].display_name" \
                                               "$jsonFile" \
                                               "   +++ Checking Tiers 0 in tiers 1" \
                                               "   ++++++ Tier0 " \
                                               "   ++++++ERROR++++++ Tier0 not found: "
  test_if_ref_from_list_exists_in_another_list ".nsx.config.segments_overlay[].tier1" \
                                               ".nsx.config.tier1s[].display_name" \
                                               "$jsonFile" \
                                               "   +++ Checking Tiers 1 in segments_overlay" \
                                               "   ++++++ Tier1 " \
                                               "   ++++++ERROR++++++ Tier1 not found: "
  #
  #
  if [[ $(jq -c -r .avi $jsonFile) != "null" ]]; then
  echo ""
  echo "==> Checking NSX ALB Variables"
  test_if_json_variable_is_defined .avi.config.cloud.networks_data $jsonFile "   "
  for item in $(jq -c -r .avi.config.cloud.networks_data[] $jsonFile)
  do
    test_if_variable_is_valid_cidr "$(echo $item | jq -c -r .avi_ipam_vip.cidr)" "   "
  done
  fi
fi