#!/bin/bash
#type terraform >/dev/null 2>&1 || { echo >&2 "terraform is not installed - please visit: https://learn.hashicorp.com/tutorials/terraform/install-cli to install it - Aborting." ; exit 255; }
#type jq >/dev/null 2>&1 || { echo >&2 "jq is not installed - please install it - Aborting." ; exit 255; }
#type govc >/dev/null 2>&1 || { echo >&2 "govc is not installed - please install it - Aborting." ; exit 255; }
#type genisoimage >/dev/null 2>&1 || { echo >&2 "genisoimage is not installed - please install it - Aborting." ; exit 255; }
#type ansible-playbook >/dev/null 2>&1 || { echo >&2 "ansible-playbook is not installed - please install it - Aborting." ; exit 255; }
#if ! ansible-galaxy collection list | grep community.vmware > /dev/null ; then echo "ansible collection community.vmware is not installed - please install it - Aborting." ; exit 255 ; fi
#if ! ansible-galaxy collection list | grep ansible_for_nsxt > /dev/null ; then echo "ansible collection vmware.ansible_for_nsxt is not installed - please install it - Aborting." ; exit 255 ; fi
#if ! pip3 list | grep  pyvmomi > /dev/null ; then echo "python pyvmomi is not installed - please install it - Aborting." ; exit 255 ; fi
#
# Script to run before TF
#
#if [ -f "variables.json" ]; then
#  jsonFile="variables.json"
#else
#  echo "variables.json file not found!!"
#  exit 255
#fi
#IFS=$'\n'
#
#
#
test_if_file_exists () {
  # $1 file path to check
  # $2 message to display
  # $3 message to display if file is present
  # $4 error to display
  echo "$2"
  if [ -f $1 ]; then
    echo "$3$1: OK."
  else
    echo "$4$1: file not found!!"
    exit 255
  fi
}
#
test_if_ref_from_list_exists_in_another_list () {
  # $1 list + ref to check
  # $2 list + ref to check against
  # $3 json file
  # $4 message to display
  # $5 message to display if match
  # $6 error to display
  echo $4
  for ref in $(jq -c -r $1 $3)
  do
    check_status=0
    for item_name in $(jq -c -r $2 $3)
    do
      if [[ $ref = $item_name ]] ; then check_status=1 ; echo "$5found: $ref, OK"; fi
    done
  done
  if [[ $check_status -eq 0 ]] ; then echo "$6$ref" ; exit 255 ; fi
}
#
test_if_ref_exists_in_another_list () {
  # $1 ref to check
  # $2 list + ref to check against
  # $3 json file
  # $4 message to display
  # $5 message to display if match
  # $6 error to display
  echo $4; check_status=0
  for item_name in $(jq -c -r $2 $3)
  do
    if [[ $1 = $item_name ]] ; then check_status=1 ; echo "$5found: $1, OK"; fi
  done
  if [[ $check_status -eq 0 ]] ; then echo "$6$1" ; exit 255 ; fi
}
#
test_if_ref_exists_in_another_list_sent () {
  # $1 ref to check
  # $2 list + ref to check against
  # $3 json file
  # $4 message to display
  # $5 message to display if match
  # $6 error to display
  echo $4; check_status=0
  for item_name in $(echo $2 | jq -c -r .[]$3)
  do
    if [[ $1 = $item_name ]] ; then check_status=1 ; echo "$5found: $1, OK"; fi
  done
  if [[ $check_status -eq 0 ]] ; then echo "$6$1" ; exit 255 ; fi
}
#
get_value_from_list_when_match () {
  # $1 value to check
  # $2 key to check
  # $3 list + ref to check against
  # $4 associated key to return
  # $5 json file
  # $6 message to display
  # $7 message to display in case of success
  # $8 message to display in case of failure
  # $value_to_return
  echo $6 ; check_status=0
  for item in $(jq -c -r $3 $5)
  do
    if [[ $1 = $(echo $item | jq -c -r .$2) ]] ; then check_status=1 ; value_to_return=$(echo $item | jq -c -r .$4) ; fi
  done
  if [[ $check_status -eq 0 ]] || [[ $value_to_return == "null" ]] ; then echo $8 ; exit 255 ; fi
  echo $7 $value_to_return
}
#
nextip(){
    IFS=$' \t\n'
    IP=$1
    IP_HEX=$(printf '%.2X%.2X%.2X%.2X\n' `echo $IP | sed -e 's/\./ /g'`)
    NEXT_IP_HEX=$(printf %.8X `echo $(( 0x$IP_HEX + 1 ))`)
    NEXT_IP=$(printf '%d.%d.%d.%d\n' `echo $NEXT_IP_HEX | sed -r 's/(..)/0x\1 /g'`)
    echo "$NEXT_IP"
    IFS=$'\n'
}
#
# Sanity checks
#
#echo ""
#echo "==> Checking Ubuntu Settings for dns/ntp and external gw..."
#test_if_file_exists $(jq -c -r .vcenter_underlay.cl.ubuntu_focal_file_path $jsonFile) "   +++ Checking Ubuntu OVA..." "   ++++++ " "   ++++++ERROR++++++ "
##
##
#echo ""
#echo "==> Checking Ubuntu Settings for dns/ntp and external gw..."
#test_if_file_exists $(jq -c -r .vcenter_underlay.cl.ubuntu_focal_file_path $jsonFile) "   +++ Checking Ubuntu OVA..." "   ++++++ " "   ++++++ERROR++++++ "
##
##
#echo ""
#echo "==> Checking SSH Keys for dns_ntp server..."
#test_if_file_exists $(jq -c -r .dns_ntp.public_key_path $jsonFile) "   +++ Checking SSH public key path..." "   ++++++ " "   ++++++ERROR++++++ "
#test_if_file_exists $(jq -c -r .dns_ntp.private_key_path $jsonFile) "   +++ Checking SSH private key path..." "   ++++++ " "   ++++++ERROR++++++ "
##
##
#echo ""
#echo "==> Checking SSH Keys for external_gw server..."
#test_if_file_exists $(jq -c -r .external_gw.public_key_path $jsonFile) "   +++ Checking SSH public key path..." "   ++++++ " "   ++++++ERROR++++++ "
#test_if_file_exists $(jq -c -r .external_gw.private_key_path $jsonFile) "   +++ Checking SSH private key path..." "   ++++++ " "   ++++++ERROR++++++ "
#
#
#echo ""
#echo "==> Creating External gateway routes..."
#rm -f external_gw.json
#new_routes="[]"
#external_gw_json=$(jq -c -r . $jsonFile | jq .)
## adding routes to external gw from nsx.config.segments_overlay
#if [[ $(jq -c -r '.nsx.config.segments_overlay | length' $jsonFile) -gt 0 ]] ; then
#  for segment in $(jq -c -r .nsx.config.segments_overlay[] $jsonFile)
#  do
#    for tier1 in $(jq -c -r .nsx.config.tier1s[] $jsonFile)
#    do
#      if [[ $(echo $segment | jq -c -r .tier1) == $(echo $tier1 | jq -c -r .display_name) ]] ; then
#        count=0
#        for tier0 in $(jq -c -r .nsx.config.tier0s[] $jsonFile)
#        do
#          if [[ $(echo $tier1 | jq -c -r .tier0) == $(echo $tier0 | jq -c -r .display_name) ]] ; then
#            new_routes=$(echo $new_routes | jq '. += [{"to": "'$(echo $segment | jq -c -r .cidr)'", "via": "'$(jq -c -r .vcenter.dvs.portgroup.nsx_external.tier0_vips["$count"] $jsonFile)'"}]')
#            echo "   +++ Route to $(echo $segment | jq -c -r .cidr) via $(jq -c -r .vcenter.dvs.portgroup.nsx_external.tier0_vips["$count"] $jsonFile) added: OK"
#          fi
#          ((count++))
#        done
#      fi
#    done
#  done
#fi
# adding routes to external gw from .avi.config.cloud.additional_subnets
#if [[ $(jq -c -r '.avi.config.cloud.additional_subnets | length' $jsonFile) -gt 0 ]] ; then
#  for network in $(jq -c -r .avi.config.cloud.additional_subnets[] $jsonFile)
#  do
#    for subnet in $(echo $network | jq -c -r '.subnets[]')
#    do
#      count=0
#      for tier0 in $(jq -c -r .nsx.config.tier0s[] $jsonFile)
#      do
#        if [[ $(echo $tier0 | jq 'has("bgp")') == "true" ]] ; then
#          if [[ $(echo $subnet | jq -c -r .bgp_label) == $(echo $tier0 | jq -c -r .bgp.avi_peer_label) ]] ; then
#            new_routes=$(echo $new_routes | jq '. += [{"to": "'$(echo $subnet | jq -c -r .cidr)'", "via": "'$(jq -c -r .vcenter.dvs.portgroup.nsx_external.tier0_vips["$count"] $jsonFile)'"}]')
#            echo "   +++ Route to $(echo $subnet | jq -c -r .cidr) via $(jq -c -r .vcenter.dvs.portgroup.nsx_external.tier0_vips["$count"] $jsonFile) added: OK"
#          fi
#        fi
#        ((count++))
#      done
#    done
#  done
#fi
#external_gw_json=$(echo $external_gw_json | jq '.external_gw += {"routes": '$(echo $new_routes)'}')
#echo $external_gw_json | jq . | tee external_gw.json > /dev/null
#
#
#echo ""
#echo "==> Checking ESXi Settings..."
#test_if_file_exists $(jq -c -r .esxi.iso_source_location $jsonFile) "   +++ Checking ESXi ISO..." "   ++++++ " "   ++++++ERROR++++++ "
#
#
#echo ""
#echo "==> Checking NSX Settings..."
#test_if_file_exists $(jq -c -r .nsx.content_library.ova_location $jsonFile) "   +++ Checking NSX OVA..." "   ++++++ " "   ++++++ERROR++++++ "
#rm -f nsx.json
#IFS=$'\n'
#nsx_json=""
#nsx_segments="[]"
#nsx_segment_external=0
#echo "   +++ Checking NSX external segments..."
#for segment in $(jq -c -r .nsx.config.segments[] $jsonFile)
#do
#  if [[ $(echo $segment | jq -c -r .nsx_external) == true ]] ; then
#    ((nsx_segment_external++))
#    cidr=$(jq -c -r .vcenter.dvs.portgroup.nsx_external.cidr $jsonFile)
#    echo "   ++++++ Adding CIDR to external segment called $(echo $segment | jq -c -r .name): $(jq -c -r .vcenter.dvs.portgroup.nsx_external.cidr $jsonFile)"
#    new_segment=$(echo $segment | jq '. += {"cidr": "'$(echo $cidr)'"}')
#  else
#    new_segment=$(echo $segment)
#  fi
#  if [[ $nsx_segment_external -gt 1 ]] ; then
#    echo "   ++++++ERROR++++++ only one segment can be nsx_external network in .nsx.config.segments[] - found: $nsx_segment_external !!"
#    exit 255
#  fi
#  nsx_segments=$(echo $nsx_segments | jq '. += ['$(echo $new_segment)']')
#done
#nsx_json=$(jq -c -r . $jsonFile | jq '. | del (.nsx.config.segments)')
#nsx_json=$(echo $nsx_json | jq '.nsx.config += {"segments": '$(echo $nsx_segments)'}')
##
#echo "   +++ Checking NSX if the amount of mgmt edge IP(s) are enough for all the edge node(s)..."
#ip_count_mgmt_edge=$(jq -c -r '.vcenter.dvs.portgroup.management.nsx_edge | length' $jsonFile)
#edge_node_count=0
#for edge_cluster in $(jq -c -r .nsx.config.edge_clusters[] $jsonFile)
#do
#  edge_node_count=$(($edge_node_count + $(echo $edge_cluster | jq -c -r '.members_name | length' )))
#done
#if [[ ip_count_mgmt_edge -ge $edge_node_count ]] ; then
#  echo "   ++++++ Found mgmt edge IP(s): $ip_count_mgmt_edge required: $edge_node_count, OK"
#else
#  echo "   ++++++ERROR++++++ Found mgmt edge IP(s): $ip_count_mgmt_edge required: $edge_node_count"
#  exit 255
#fi
#
#echo "   +++ Checking NSX if the amount of external IP(s) are enough for all the interfaces of the tier0(s)..."
#ip_count_external_tier0=$(jq -c -r '.vcenter.dvs.portgroup.nsx_external.tier0_ips | length' $jsonFile)
#tier0_ifaces=0
#for tier0 in $(jq -c -r .nsx.config.tier0s[] $jsonFile)
#do
#  tier0_ifaces=$((tier0_ifaces+$(echo $tier0 | jq -c -r '.interfaces | length')))
#done
#if [[ $tier0_ifaces -gt $ip_count_external_tier0 ]] ; then
#  echo "   ++++++ERROR++++++ Amount of IPs (.vcenter.dvs.portgroup.nsx_external.tier0_ips) cannot cover the amount of tier0 interfaces defined in .nsx.config.tier0s[].interfaces"
#  exit 255
#fi
#echo "   ++++++ Amount of tier0(s) interfaces: $tier0_ifaces, Amount of of IP(s): $ip_count_external_tier0, OK"
##
##
#echo "   +++ Checking NSX if if the amount of interfaces in vip config is equal to two for each tier0..."
#for tier0 in $(jq -c -r .nsx.config.tier0s[] $jsonFile)
#do
#  for vip in $(echo $tier0 | jq -c -r .ha_vips[])
#  do
#    if [[ $(echo $vip | jq -c -r '.interfaces | length') -ne 2 ]] ; then
#      echo "   ++++++ERROR++++++ Amount of interfaces (.nsx.config.tier0s[].ha_vips[].interfaces) needs to be equal to 2; tier0 called $(echo $tier0 | jq -c -r .display_name) has $(echo $vip | jq -c -r '.interfaces | length') interfaces for its ha_vips"
#      exit 255
#    fi
#    echo "   ++++++ Amount of interfaces for $(echo $tier0 | jq -c -r .display_name): $(echo $vip | jq -c -r '.interfaces | length'), OK"
#  done
#done
#
#
#echo "   +++ Checking NSX if the amount of external vip is enough for all the vips of the tier0s..."
#tier0_vips=0
#for tier0 in $(jq -c -r .nsx.config.tier0s[] $jsonFile)
#do
#  for vip in $(echo $tier0 | jq -c -r .ha_vips[])
#  do
#    tier0_vips=$((tier0_vips+$(echo $tier0 | jq -c -r '.ha_vips | length')))
#  done
#  if [[ $tier0_vips -gt $(jq -c -r '.vcenter.dvs.portgroup.nsx_external.tier0_vips | length' $jsonFile) ]] ; then
#    echo "   ++++++ERROR++++++ Amount of VIPs (.vcenter.dvs.portgroup.nsx_external.tier0_vips) cannot cover the amount of ha_vips defined in .nsx.config.tier0s[].ha_vips"
#    exit 255
#  fi
#done
#echo "   ++++++ Amount of external vip is $(jq -c -r '.vcenter.dvs.portgroup.nsx_external.tier0_vips | length' $jsonFile), amount of vip needed: $tier0_vips, OK"
#
#
#nsx_tiers0="[]"
#echo "   +++ Creating BGP neighbors on each tier0..."
#for tier0 in $(jq -c -r .nsx.config.tier0s[] $jsonFile)
#do
#  if [[ $(echo $tier0 | jq 'has("bgp")') == "true" ]] ; then
#    test_if_ref_exists_in_another_list "$(echo $tier0 | jq -c -r .bgp.avi_context_ref)" \
#                                                 ".avi.config.cloud.contexts[].name" \
#                                                 "$jsonFile" \
#                                                 "   ++++++ Checking Context ref in tier0 BGP config" \
#                                                 "   +++++++++ Context " \
#                                                 "   +++++++++ERROR+++++++++ Avi Context not found: "
#    get_value_from_list_when_match  "$(echo $tier0 | jq -c -r .bgp.avi_context_ref)" \
#                                    "name" \
#                                    ".avi.config.cloud.contexts[]" \
#                                    "local_as" \
#                                    "$jsonFile" \
#                                    "   ++++++ Searching for 'local_as' value in '.avi.config.cloud.contexts[]' when 'name' value equals '$(echo $tier0 | jq -c -r .bgp.avi_context_ref)'" \
#                                    "   +++++++++ found 'local_as' value equals to" \
#                                    "   +++++++++ERROR+++++++++ 'local_as' not found"
#    local_as=$value_to_return
#    get_value_from_list_when_match  "$(echo $(jq -c -r .vcenter.dvs.portgroup.nsx_external.name $jsonFile)-pg)" \
#                                        "name" \
#                                        ".avi.config.cloud.networks[]" \
#                                        "avi_ipam_pool" \
#                                        "$jsonFile" \
#                                        "   ++++++ Searching for 'avi_ipam_pool' value in '.avi.config.cloud.networks[]' when 'name' value equals '$(echo $(jq -c -r .vcenter.dvs.portgroup.nsx_external.name $jsonFile)-pg)'" \
#                                        "   +++++++++ found 'avi_ipam_pool' value equals to" \
#                                        "   +++++++++ERROR+++++++++ 'avi_ipam_pool' not found"
#    avi_ipam_pool_ip=$(echo $value_to_return | cut -d"-" -f1)
#    avi_ipam_pool_end=$(echo $value_to_return | cut -d"-" -f2)
#    neighbors="{\"neighbors\": []}"
#    neighbors=$(echo $neighbors | jq -c -r '.neighbors += [{"neighbor_address": "'$(echo $avi_ipam_pool_ip)'", "remote_as_num": "'$(echo $local_as)'"}]')
#    while [[ $avi_ipam_pool_ip != $avi_ipam_pool_end ]]
#    do
#      avi_ipam_pool_ip=$(nextip $avi_ipam_pool_ip)
#      neighbors=$(echo $neighbors | jq -c -r '.neighbors += [{"neighbor_address": "'$(echo $avi_ipam_pool_ip)'", "remote_as_num": "'$(echo $local_as)'"}]')
#    done
#    tier0=$(echo $tier0 | jq -c -r '.bgp += '$(echo $neighbors | jq -c -r)'')
#    nsx_tiers0=$(echo $nsx_tiers0 | jq '. += ['$(echo $tier0)']')
#  else
#    nsx_tiers0=$(echo $nsx_tiers0 | jq '. += ['$(echo $tier0)']')
#  fi
#done
#nsx_json=$(jq -c -r . $jsonFile | jq '. | del (.nsx.config.tier0s)')
#nsx_json=$(echo $nsx_json | jq '.nsx.config += {"tier0s": '$(echo $nsx_tiers0)'}')
#
#test_if_ref_from_list_exists_in_another_list ".nsx.config.tier1s[].tier0" \
#                                             ".nsx.config.tier0s[].display_name" \
#                                             "$jsonFile" \
#                                             "   +++ Checking Tiers 0 in tiers 1" \
#                                             "   ++++++ Tier0 " \
#                                             "   ++++++ERROR++++++ Tier0 not found: "
##
#test_if_ref_from_list_exists_in_another_list ".nsx.config.segments_overlay[].tier1" \
#                                             ".nsx.config.tier1s[].display_name" \
#                                             "$jsonFile" \
#                                             "   +++ Checking Tiers 1 in segments_overlay" \
#                                             "   ++++++ Tier1 " \
#                                             "   ++++++ERROR++++++ Tier1 not found: "
#echo $nsx_json | jq . | tee nsx.json > /dev/null
#
# check Avi Parameters
rm -f avi.json
IFS=$'\n'
avi_json=""
avi_networks="[]"
echo ""
echo "==> Checking Avi Settings..."
test_if_file_exists $(jq -c -r .avi.content_library.ova_location $jsonFile) "   +++ Checking Avi OVA" "   ++++++ " "   ++++++ERROR++++++ "
# check Avi Controller Network
# copying segment info (ip, cidr, and gw keys) to avi.controller
echo "   +++ Checking Avi Controller network settings"
avi_controller_network=0
for segment in $(jq -c -r .nsx.config.segments_overlay[] $jsonFile)
do
  if [[ $(echo $segment | jq -r .display_name) == $(jq -c -r .avi.controller.network_ref $jsonFile) ]] ; then
    avi_controller_network=1
    echo "   ++++++ Avi Controller segment found: $(echo $segment | jq -r .display_name), OK"
    echo "   ++++++ Avi Controller CIDR is: $(echo $segment | jq -r .cidr), OK"
    echo "   ++++++ Avi Controller IP is: $(echo $segment | jq -r .avi_controller), OK"
    avi_json=$(jq -c -r . $jsonFile | jq '.avi.controller += {"ip": '$(echo $segment | jq .avi_controller)'}' | jq '.avi.controller += {"cidr": '$(echo $segment | jq .cidr)'}' | jq '.avi.controller += {"gw": '$(echo $segment | jq .gw)'}')
  fi
done
if [[ $avi_controller_network -eq 0 ]] ; then
  echo "   ++++++ERROR++++++ $(jq -c -r .avi.controller.network_ref $jsonFile) segment not found!!"
  exit 255
fi
# check Avi Cloud Networks against NSX segments
# copy cidr from nsx.config.segments_overlay to avi.config.cloud.networks (useful for vCenter cloud as we can't retrieve the CIDR through API)
echo "   +++ Checking Avi Cloud networks settings"
avi_cloud_network_mgmt=0
for network in $(jq -c -r .avi.config.cloud.networks[] $jsonFile)
do
  network_name=$(echo $network | jq -c -r .name)
  avi_cloud_network=0
  for segment in $(jq -c -r .nsx.config.segments_overlay[] $jsonFile)
  do
    if [[ $(echo $segment | jq -r .display_name) == $(echo $network | jq -c -r .name) ]] ; then
      avi_cloud_network=1
      echo "   ++++++ Avi cloud network found in NSX overlay segments: $(echo $segment | jq -r .display_name), OK"
      cidr=$(echo $segment | jq -r .cidr)
    fi
  done
  if [[ $(echo $(jq -c -r .vcenter.dvs.portgroup.nsx_external.name $jsonFile)-pg) == $(echo $network | jq -c -r .name) ]] ; then
    avi_cloud_network=1
    echo "   ++++++ Avi cloud network found in NSX external segment: $(echo $network | jq -c -r .name), OK"
    cidr=$(jq -c -r .vcenter.dvs.portgroup.nsx_external.cidr $jsonFile)
  fi
  if [[ $avi_cloud_network -eq 0 ]] ; then
    echo "   ++++++ERROR++++++ $(echo $network | jq -c -r .name) segment not found!!"
    exit 255
  fi
  new_network=$(echo $network | jq '. += {"cidr": "'$(echo $cidr)'"}')
  avi_networks=$(echo $avi_networks | jq '. += ['$(echo $new_network)']')
  if [[ $(echo $network | jq -c -r .management) == true ]] ; then
    ((avi_cloud_network_mgmt++))
  fi
  if [[ $avi_cloud_network_mgmt -gt 1 ]] ; then
    echo "   ++++++ERROR++++++ only one network can be management network in .avi.config.cloud.networks[] - found: $avi_cloud_network_mgmt !!"
    exit 255
  fi
done
avi_json=$(echo $avi_json | jq '. | del (.avi.config.cloud.networks)')
avi_json=$(echo $avi_json | jq '.avi.config.cloud += {"networks": '$(echo $avi_networks)'}')
# copy cidr from avi.config.cloud.networks to avi.config.virtual_services.http
if [[ $(echo $avi_json | jq -c -r '.avi.config.virtual_services.http | length') -gt 0 ]] ; then
  avi_http_vs=[]
  for vs in $(echo $avi_json | jq -c -r .avi.config.virtual_services.http[])
  do
    for network in $(echo $avi_json | jq -c -r .avi.config.cloud.networks[])
    do
      if [[ $(echo $network | jq -c -r .name) == $(echo $vs | jq -c -r '.network_ref') ]] ; then
        cidr=$(echo $network | jq -r .cidr)
      fi
      if [[ $(echo $network | jq -c -r .name) == $(echo $vs | jq -c -r '.network_ref') ]] ; then
        type=$(echo $network | jq -r .type)
      fi
    done
    new_vs_http=$(echo $vs | jq '. += {"cidr": "'$(echo $cidr)'", "type": "'$(echo $type)'"}')
    avi_http_vs=$(echo $avi_dns_vs | jq '. += ['$(echo $new_vs_http)']')
  done
fi
# copy cidr from avi.config.cloud.networks to avi.config.virtual_services.dns
if [[ $(echo $avi_json | jq -c -r '.avi.config.virtual_services.dns | length') -gt 0 ]] ; then
  avi_dns_vs=[]
  for vs in $(echo $avi_json | jq -c -r .avi.config.virtual_services.dns[])
  do
    for network in $(echo $avi_json | jq -c -r .avi.config.cloud.networks[])
    do
      if [[ $(echo $network | jq -c -r .name) == $(echo $vs | jq -c -r '.network_ref') ]] ; then
        cidr=$(echo $network | jq -r .cidr)
      fi
      if [[ $(echo $network | jq -c -r .name) == $(echo $vs | jq -c -r '.network_ref') ]] ; then
        type=$(echo $network | jq -r .type)
      fi
    done
    new_vs_dns=$(echo $vs | jq '. += {"cidr": "'$(echo $cidr)'", "type": "'$(echo $type)'"}')
    avi_dns_vs=$(echo $avi_dns_vs | jq '. += ['$(echo $new_vs_dns)']')
  done
fi
avi_json=$(echo $avi_json | jq '. | del (.avi.config.virtual_services.dns)')
avi_json=$(echo $avi_json | jq '.avi.config.virtual_services += {"dns": '$(echo $avi_dns_vs)'}')
#
avi_json=$(echo $avi_json | jq '. | del (.avi.config.cloud.contexts)')
ip_if_edge_index=0
peers="[]"
for tier0 in $(jq -c -r .nsx.config.tier0s[] $jsonFile)
do
  if [[ $(echo $tier0 | jq 'has("bgp")') == "true" ]] ; then
    remote_as=$(echo $tier0 | jq -r -c .bgp.local_as_num)
    for context in $(jq -c -r '.avi.config.cloud.contexts[]' $jsonFile)
    do
      context_index=0
      if [[ $(echo $context | jq -c -r .name) == $(echo $tier0 | jq -c -r .bgp.avi_context_ref) ]] ; then
        test_if_ref_exists_in_another_list_sent      "$(echo $tier0 | jq -r -c .bgp.avi_peer_label)" \
                                                     "$(echo $context | jq -c -r .routing_options)" \
                                                     ".label" \
                                                     "   ++++++ Checking label ref in tier0 BGP config" \
                                                     "   +++++++++ label " \
                                                     "   +++++++++ERROR+++++++++ Avi BGP label  not found: "
      fi
      for interface in $(echo $tier0 | jq -c -r '.interfaces[]')
      do
        peers=$(echo $peers | jq -c -r '. += [{"advertise_snat_ip": true,
                                              "advertise_vip": true,
                                              "advertisement_interval": 5,
                                              "bfd": false,
                                              "connect_timer": 10,
                                              "ebgp_multihop": 0,
                                              "label": "'$(echo $tier0 | jq -r -c .bgp.avi_peer_label)'",
                                              "network_ref": "/api/network/?name='$(echo $(jq -c -r .vcenter.dvs.portgroup.nsx_external.name $jsonFile)-pg)'",
                                              "peer_ip": {"addr": "'$(echo $(jq -c -r '.vcenter.dvs.portgroup.nsx_external.tier0_ips['$ip_if_edge_index']' $jsonFile))'", "type": "V4"},
                                              "remote_as": "'$(echo $remote_as)'",
                                              "shutdown": false,
                                              "subnet": {"ip_addr": {"addr": "'$(echo $(jq -c -r .vcenter.dvs.portgroup.nsx_external.cidr $jsonFile) | cut -d"/" -f1 )'","type": "V4"},"mask": "'$(echo $(jq -c -r .vcenter.dvs.portgroup.nsx_external.cidr $jsonFile) | cut -d"/" -f2 )'"}
                                              }]')
        ((ip_if_edge_index++))
      done
      ((context_index++))
      context=$(echo $context | jq '.peers += '$(echo $peers)'')
    done
  else
    ip_if_edge_index=$((ip_if_edge_index+$(echo $tier0 | jq -c -r '.interfaces | length')))
  fi
done
avi_json=$(echo $avi_json | jq '.avi.config.cloud.contexts += ['$(echo $context | jq -c -r)']')
#
# rewriting additional_subnets to feed proper Avi formatting
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
  additional_subnets=$(echo $additional_subnets | jq -c -r '. +=  [ {"name_ref": "'$(echo $network | jq -c -r .name_ref )'", "configured_subnets": '$(echo $configured_subnets)'}]')
done
avi_json=$(echo $avi_json | jq '.avi.config.cloud.additional_subnets += '$(echo $additional_subnets | jq -c -r)'')
#
## checking if Avi IPAM Networks exists in Avi cloud networks
test_if_ref_from_list_exists_in_another_list ".avi.config.ipam.networks[]" \
                                             ".avi.config.cloud.networks[].name" \
                                             "$jsonFile" \
                                             "   +++ Checking IPAM networks" \
                                             "   ++++++ Avi IPAM network " \
                                             "   ++++++ERROR++++++ Network not found: "
# checking if seg ref in DNS VS exist in seg list
if [ $(jq -c -r '.avi.config.virtual_services.dns | length' $jsonFile) -gt 0 ] ; then
  test_if_ref_from_list_exists_in_another_list ".avi.config.virtual_services.dns[].se_group_ref" \
                                               ".avi.config.service_engine_groups[].name" \
                                               "$jsonFile" \
                                               "   +++ Checking Service Engine Group in DNS VS" \
                                               "   ++++++ Service Engine Group " \
                                               "   ++++++ERROR++++++ segment not found: "
fi
# checking if seg ref in HTTP VS exist in seg list
if [ $(jq -c -r '.avi.config.virtual_services.http | length' $jsonFile) -gt 0 ] ; then
  test_if_ref_from_list_exists_in_another_list ".avi.config.virtual_services.http[].se_group_ref" \
                                               ".avi.config.service_engine_groups[].name" \
                                               "$jsonFile" \
                                               "   +++ Checking Service Engine Group in HTTP VS" \
                                               "   ++++++ Service Engine Group " \
                                               "   ++++++ERROR++++++ segment not found: "
fi
echo $avi_json | jq . | tee avi.json > /dev/null
#
# check TKG Parameters
if [[ $(jq -c -r .tkg.prep $jsonFile) == true ]] ; then
  rm -f tkg.json
  IFS=$'\n'
  tkg_json=$(jq -c -r . $jsonFile)
  echo ""
  echo "==> Checking TKG Settings..."
  test_if_file_exists $(jq -c -r .tkg.tanzu_bin_location $jsonFile) "   +++ Checking TKG Binaries" "   ++++++ " "   ++++++ERROR++++++ "
  test_if_file_exists $(jq -c -r .tkg.k8s_bin_location $jsonFile) "   +++ Checking K8s Binaries" "   ++++++ " "   ++++++ERROR++++++ "
  test_if_file_exists $(jq -c -r .tkg.ova_location $jsonFile) "   +++ Checking TKG OVA" "   ++++++ " "   ++++++ERROR++++++ "
  #
  echo "   +++ Checking various settings for mgmt cluster"
  tkg_mgmt_network=0
  echo "   ++++++ Checking TKG network(s) for mgmt cluster"
  for segment in $(jq -c -r .nsx.config.segments_overlay[] $jsonFile)
  do
    if [[ $(echo $segment | jq -r .display_name) == $(jq -c -r .tkg.clusters.management.vsphere_network $jsonFile) ]] ; then
      tkg_mgmt_network=1
      echo "   +++++++++ TKG mgmt segment found: $(echo $segment | jq -r .display_name), OK"
    fi
    if [[ $(echo $segment | jq -r .display_name) == $(jq -c -r .avi.controller.network_ref $jsonFile) ]] ; then
      tkg_json=$(echo $tkg_json | jq '.tkg += {"avi_cidr": '$(echo $segment | jq .cidr)'}' | jq '.tkg += {"avi_ip": '$(echo $segment | jq .avi_controller)'}')
      echo "   +++++++++ Adding key avi_cidr: $(echo $segment | jq .cidr) to tkg.json: OK"
      echo "   +++++++++ Adding key avi_ip: $(echo $segment | jq .avi_controller) to tkg.json: OK"
    fi
  done
  if [[ $tkg_mgmt_network -eq 0 ]] ; then
    echo "   +++++++++ERROR+++++++++ $(jq -c -r .tkg.clusters.management.vsphere_network $jsonFile) segment not found!!"
    exit 255
  fi
  #
  test_if_file_exists $(jq -c -r .tkg.clusters.management.public_key_path $jsonFile) "   ++++++ Checking TKG SSH key(s) for the mgmt cluster" "   +++++++++ " "   +++++++++ERROR+++++++++ "
  #
  echo "   +++ Checking various settings for workload cluster(s)"
  for cluster in $(jq -c -r .tkg.clusters.workloads[] $jsonFile)
  do
    echo "   ++++++ Checking TKG network(s) for workload cluster(s)"
    tkg_workload_network=0
    for segment in $(jq -c -r .nsx.config.segments_overlay[] $jsonFile)
    do
      if [[ $(echo $segment | jq -r .display_name) == $(echo $cluster | jq -c -r .vsphere_network) ]] ; then
        tkg_workload_network=1
        echo "   +++++++++ TKG workload segment found: $(echo $segment | jq -r .display_name), OK"
        break
      fi
    done
    if [[ $tkg_workload_network -eq 0 ]] ; then
      echo "   +++++++++ERROR+++++++++ $(echo $cluster | jq -c -r .vsphere_network) segment not found!!"
      exit 255
    fi
    #
    test_if_file_exists $(echo $cluster | jq -c -r .public_key_path) "   ++++++ Checking TKG SSH key(s) for the workload cluster(s)" "   +++++++++ cluster $(echo $cluster | jq -c -r .name), key file " "   +++++++++ERROR+++++++++ cluster $(echo $cluster | jq -c -r .name), key file "
    #
  done
  echo "   +++ Checking various Avi/AKO settings for workload cluster(s)"
  if [[ $(jq -c -r .avi.config.ako.generate_values_yaml $jsonFile) == true ]] ; then
    echo "   ++++++ Checking TKG Tenant name"
    ako_tenant=0
    if [[ $(jq -c -r .tkg.clusters.ako_tenant_ref $jsonFile) == "admin" ]] ; then
      echo "   +++++++++ AKO tenant $(jq -c -r .tkg.clusters.ako_tenant_ref $jsonFile): OK."
      ako_tenant=1
    else
      for tenant_name in $(jq -c -r .avi.config.tenants[].name $jsonFile)
      do
        if [[ $(jq -c -r .tkg.clusters.ako_tenant_ref $jsonFile) == $(echo $tenant_name) ]] ; then
          ako_tenant=1
          echo "   +++++++++ AKO tenant $(jq -c -r .tkg.clusters.ako_tenant_ref $jsonFile): OK."
          break
        fi
      done
    fi
    if [[ $ako_tenant -eq 0 ]] ; then
      echo "   +++++++++ERROR+++++++++ AKO tenant $(jq -c -r .tkg.clusters.ako_tenant_ref $jsonFile) not found!!"
      exit 255
    fi
    #
    echo "   ++++++ Checking TKG Service Engine Group name"
    ako_seg=0
    if [[ $(jq -c -r .tkg.clusters.ako_service_engine_group_ref $jsonFile) == "Default-Group" ]] ; then
      echo "   +++++++++ AKO Service Engine Group $(jq -c -r .tkg.clusters.ako_service_engine_group_ref $jsonFile): OK."
      ako_seg=1
    else
      for seg in $(jq -c -r .avi.config.service_engine_groups[] $jsonFile)
      do
        if [[ $(echo $seg | jq -c -r .name) == $(jq -c -r .tkg.clusters.ako_service_engine_group_ref $jsonFile) ]] ; then
          ako_seg=1
          echo "   +++++++++ AKO Service Engine Group $(jq -c -r .tkg.clusters.ako_service_engine_group_ref $jsonFile): OK."
          break
        fi
      done
    fi
    if [[ $ako_seg -eq 0 ]] ; then
      echo "   +++++++++ERROR+++++++++ $(echo $cluster | jq -c -r .ako_service_engine_group_ref) seg not found!!"
      exit 255
    fi
    #
    echo "   ++++++ Checking default AKO BGP peer label"
    ako_bgp_peer=0
    for network in $(jq -c -r .avi.config.cloud.additional_subnets[] $jsonFile)
    do
      if [[ $(echo $network | jq -c -r .name_ref) == $(jq -c -r .tkg.clusters.ako_vip_network_name_ref $jsonFile) ]] ; then
        for subnet in $(echo $network | jq -c -r '.subnets[]')
        do
          echo "   +++++++++ AKO default BGP peer label $(echo $bgp_labels): OK"
          tkg_json=$(echo $tkg_json | jq '.tkg.clusters += {"ako_vip_network_cidr": "'$(echo $subnet | jq -c -r .cidr)'"}')
          echo "   +++++++++ Adding key ako_vip_network_cidr: $(echo $subnet | jq -c -r .cidr) to tkg.json: OK"
          ako_bgp_peer=1
          break
        done
      fi
    done
    if [[ $ako_bgp_peer -eq 0 ]] ; then
      echo "   +++++++++ERROR+++++++++  AKO BGP peer label $(jq -c -r .tkg.clusters.ako_vip_network_name_ref $jsonFile) not found!!"
      exit 255
    fi
    echo "   ++++++ Adding AKO BGP peer label list and CIDR to tkg.json"
    for network in $(jq -c -r .avi.config.cloud.additional_subnets[] $jsonFile)
    do
      if [[ $(echo $network | jq -c -r .name_ref) == $(jq -c -r .tkg.clusters.ako_vip_network_name_ref $jsonFile) ]] ; then
        bgp_labels="[]"
        ako_cidrs="[]"
        for subnet in $(echo $network | jq -c -r '.subnets[]')
        do
          bgp_labels=$(echo $bgp_labels | jq '. += ["'$(echo $subnet | jq -c -r .bgp_label)'"]')
          echo "   +++++++++ Adding Avi BGP peers labels $(echo $subnet | jq -c -r .bgp_label) : OK"
          ako_cidrs=$(echo $ako_cidrs | jq '. += ["'$(echo $subnet | jq -c -r .cidr)'"]')
          echo "   +++++++++ Adding CIDR $(echo $subnet | jq -c -r .cidr) : OK"
        done
        tkg_json=$(echo $tkg_json | jq '.tkg.clusters += {"ako_bgp_labels": '$(echo $bgp_labels | jq -c -r .)', "ako_vip_network_cidrs": '$(echo $ako_cidrs | jq -c -r .)'}')
      fi
    done
  fi
  #
  echo $tkg_json | jq . | tee tkg.json > /dev/null
fi
#
#
#
tf_init_apply () {
  # $1 messsage to display
  # $2 is the folder to init/apply tf
  # $3 is the log path file for tf stdout
  # $4 is the log path file for tf error
  # $5 is var-file to feed TF with variables
  echo "-----------------------------------------------------"
  echo $1
  echo "Starting timestamp: $(date)"
  cd $2
  terraform init > $3 2>$4
  if [ -s "$4" ] ; then
    echo "TF Init ERRORS:"
    cat $4
    exit 1
  else
    rm $3 $4
  fi
  terraform apply -auto-approve -var-file=$5 > $3 2>$4
  if [ -s "$4" ] ; then
    echo "TF Apply ERRORS:"
    cat $4
#    echo "Waiting for 30 seconds - retrying TF Apply..."
#    sleep 10
#    rm -f $3 $4
#    terraform apply -auto-approve -var-file=$5 > $3 2>$4
#    if [ -s "$4" ] ; then
#      echo "TF Apply ERRORS:"
#      cat $4
#      exit 1
#    fi
    exit 1
  fi
  echo "Ending timestamp: $(date)"
  cd - > /dev/null
}
echo ""
#
# Build of a folder on the underlay infrastructure
#
tf_init_apply "Build of a folder on the underlay infrastructure - This should take less than a minute" vsphere_underlay_folder ../logs/tf_vsphere_underlay_folder.stdout ../logs/tf_vsphere_underlay_folder.errors ../$jsonFile
#
# Build of a DNS/NTP server on the underlay infrastructure
#
if [[ $(jq -c -r .dns_ntp.create $jsonFile) == true ]] ; then
  tf_init_apply "Build of a DNS/NTP server on the underlay infrastructure - This should take less than 5 minutes" dns_ntp ../logs/tf_dns_ntp.stdout ../logs/tf_dns_ntp.errors ../$jsonFile
fi
#
# Build of an external GW server on the underlay infrastructure
#
if [[ $(jq -c -r .external_gw.create $jsonFile) == true ]] ; then
  tf_init_apply "Build of an external GW server on the underlay infrastructure - This should take less than 10 minutes" external_gw ../logs/tf_external_gw.stdout ../logs/tf_external_gw.errors ../external_gw.json
fi
#
# Build of the nested ESXi/vCenter infrastructure
#
tf_init_apply "Build of the nested ESXi/vCenter infrastructure - This should take less than 45 minutes" nested_vsphere ../logs/tf_nested_vsphere.stdout ../logs/tf_nested_vsphere.errors ../$jsonFile
echo "waiting for 20 minutes to finish the vCenter config..."
sleep 1200
#
# Build of the NSX Nested Networks
#
if [[ $(jq -c -r .nsx.networks.create $jsonFile) == true ]] ; then
  tf_init_apply "Build of NSX Nested Networks - This should take less than a minute" nsx/networks ../../logs/tf_nsx_networks.stdout ../../logs/tf_nsx_networks.errors ../../$jsonFile
fi
#
# Build of the nested NSXT Manager
#
if [[ $(jq -c -r .nsx.manager.create $jsonFile) == true ]] || [[ $(jq -c -r .nsx.content_library.create $jsonFile) == true ]] ; then
  tf_init_apply "Build of the nested NSXT Manager - This should take less than 20 minutes" nsx/manager ../../logs/tf_nsx.stdout ../../logs/tf_nsx.errors ../../$jsonFile
  if [[ $(jq -c -r .nsx.manager.create $jsonFile) == true ]] ; then
    echo "waiting for 5 minutes to finish the NSXT bootstrap..."
    sleep 300
  fi
fi
#
# Build of the config of NSX-T
#
if [[ $(jq -c -r .nsx.config.create $jsonFile) == true ]] ; then
  tf_init_apply "Build of the config of NSX-T - This should take less than 75 minutes" nsx/config ../../logs/tf_nsx_config.stdout ../../logs/tf_nsx_config.errors ../../$jsonFile
fi
#
# Build of the Nested Avi Controllers
#
if [[ $(jq -c -r .avi.controller.create $jsonFile) == true ]] || [[ $(jq -c -r .avi.content_library.create $jsonFile) == true ]] ; then
  tf_init_apply "Build of Nested Avi Controllers - This should take around 15 minutes" avi/controllers ../../logs/tf_avi_controller.stdout ../../logs/tf_avi_controller.errors ../../avi.json
  tf_init_apply "Build of Avi Cert for TKG - This should take less than a minute" avi/tkg_cert ../../logs/tf_avi_tkg_cert.stdout ../../logs/tf_avi_tkg_cert.errors ../../avi.json
fi
#
# Build of the config of Avi
#
if [[ $(jq -c -r .avi.controller.create $jsonFile) == true ]] && [[ $(jq -c -r .avi.config.create $jsonFile) == true ]] ; then
  tf_init_apply "Build of the config of Avi - This should take around 40 minutes" avi/config ../../logs/tf_avi_config.stdout ../../logs/tf_avi_config.errors ../../avi.json
fi
#
# TKG prep
#
if [[ $(jq -c -r .tkg.prep $jsonFile) == true ]] && [[ $(jq -c -r .external_gw.create $jsonFile) == true ]] ; then
  tf_init_apply "Prep of TKG - This should take less than 15 minutes" tkg/prep ../../logs/tf_tkg_prep.stdout ../../logs/tf_tkg_prep.errors ../../tkg.json
fi
#
# Templating of TKG mgmt-cluster
#
if [[ $(jq -c -r .external_gw.create $jsonFile) == true ]] && [[ $(jq -c -r .tkg.clusters.management_template $jsonFile) == true ]] ; then
  tf_init_apply "Templating of TKG mgmt cluster - This should take less than one minute" tkg/mgmt_cluster_template ../../logs/tf_tkg_mgmt_cluster_template.stdout ../../logs/tf_tkg_mgmt_cluster_template.errors ../../tkg.json
fi
#
# Build of TKG mgmt-cluster
#
if [[ $(jq -c -r .external_gw.create $jsonFile) == true ]] && [[ $(jq -c -r .tkg.clusters.management_template $jsonFile) == true ]] && [[ $(jq -c -r .tkg.clusters.management_build $jsonFile) == true ]] ; then
  tf_init_apply "Building TKG mgmt cluster - This should take around 25 minutes" tkg/mgmt_cluster_build ../../logs/tf_tkg_mgmt_cluster_build.stdout ../../logs/tf_tkg_mgmt_cluster_build.errors ../../tkg.json
fi
#
# Templating of TKG workload-clusters
#
if [[ $(jq -c -r .external_gw.create $jsonFile) == true ]] && [[ $(jq -c -r .tkg.clusters.workload_template $jsonFile) == true ]] ; then
  tf_init_apply "Templating of TKG workload cluster(s) - This should take less than one minute" tkg/workload_clusters_templates ../../logs/tf_tkg_workload_clusters_templates.stdout ../../logs/tf_tkg_workload_clusters_templates.errors ../../tkg.json
fi
#
# Build of TKG workload-clusters
#
if [[ $(jq -c -r .external_gw.create $jsonFile) == true ]] && [[ $(jq -c -r .tkg.clusters.workload_template $jsonFile) == true ]] && [[ $(jq -c -r .tkg.clusters.workload_build $jsonFile) == true ]] ; then
  tf_init_apply "Building TKG workload cluster(s) - This should take around 40 minutes - for 2 clusters" tkg/workload_clusters_builds ../../logs/tf_tkg_workload_clusters_builds.stdout ../../logs/tf_tkg_workload_clusters_builds.errors ../../tkg.json
fi
#
# Patching TKG workload-clusters
#
tf_init_apply "Patching TKG workload cluster(s) - This should take around 5 minutes - for 2 clusters" tkg/workload_patching ../../logs/tf_tkg_workload_patching.stdout ../../logs/tf_tkg_workload_patching.errors ../../tkg.json
#
# Templating AKO and K8s yaml files
#
if [[ $(jq -c -r .external_gw.create $jsonFile) == true ]] && [[ $(jq -c -r .tkg.clusters.ako_template $jsonFile) == true ]] ; then
  tf_init_apply "Templating values.yaml and K8s yaml files - This should take less than one minute" tkg/ako ../../logs/tf_tkg_ako.stdout ../../logs/tf_tkg_ako.errors ../../tkg.json
fi
#
#
# Output message
#
rm -f output.txt
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++" | tee output.txt
echo "Configure your local DNS by using $(jq -c -r .dns.nameserver $jsonFile)" | tee -a output.txt
echo "vCenter url: https://$(jq -c -r .vcenter.name $jsonFile).$(jq -c -r .dns.domain $jsonFile)" | tee -a output.txt
echo "NSX url: https://$(jq -c -r .nsx.manager.basename $jsonFile).$(jq -c -r .dns.domain $jsonFile)" | tee -a output.txt
echo "To access Avi UI:" | tee -a output.txt
echo "  - configure $(jq -c -r .vcenter.dvs.portgroup.management.external_gw_ip $jsonFile) as a socks proxy" | tee -a output.txt
echo "  - Avi url: https://$(jq -c -r .avi.controller.cidr avi.json | cut -d'/' -f1 | cut -d'.' -f1-3).$(jq -c -r .avi.controller.ip avi.json)" | tee -a output.txt
echo "To Access your TKG cluster:" | tee -a output.txt
echo '  - tanzu cluster list' | tee -a output.txt
echo "  - tanzu cluster kubeconfig get $(jq -c -r .tkg.clusters.workloads[0].name $jsonFile) --admin" | tee -a output.txt
echo "  - kubectl config use-context $(jq -c -r .tkg.clusters.workloads[0].name $jsonFile)-admin@$(jq -c -r .tkg.clusters.workloads[0].name $jsonFile)" | tee -a output.txt
echo "To ssh your TKG cluster node(s):" | tee -a output.txt
echo "  - kubectl get nodes -o json | jq -r .items[].status.addresses[1].address" | tee -a output.txt
echo "  - ssh capv@ip_of_tanzu_node -i $(jq -c -r .tkg.clusters.workloads[0].public_key_path $jsonFile)" | tee -a output.txt
echo "To Add Docker registry Account to your TKG cluster:" | tee -a output.txt
echo '  - kubectl create secret docker-registry docker --docker-server=docker.io --docker-username=******** --docker-password=******** --docker-email=********' | tee -a output.txt
echo '  - kubectl patch serviceaccount default -p "{\"imagePullSecrets\": [{\"name\": \"docker\"}]}"' | tee -a output.txt
echo "Avi/NSX: Configure BGP sessions between tier0s and service Engines" | tee -a output.txt
for network in $(jq -c -r .avi.config.cloud.networks[] $jsonFile)
do
  if [[ $(echo $network | jq -c -r .name) == $(echo $(jq -c -r .vcenter.dvs.portgroup.nsx_external.name $jsonFile)-pg) ]] ; then
    echo "  - pool of IP used by Service Engines: $(echo $network | jq -c -r .avi_ipam_pool)" | tee -a output.txt
  fi
done
echo "  - IPs used by tier0 interfaces: $(jq -c -r '.vcenter.dvs.portgroup.nsx_external.tier0_ips' $jsonFile)" | tee -a output.txt
echo "Avi: Configure the following subnets on the top the network called $(jq -r .vcenter.dvs.portgroup.nsx_external.name $jsonFile)-pg" | tee -a output.txt
for network in $(jq -c -r .avi.config.cloud.additional_subnets[] $jsonFile)
do
  if [[ $(echo $network | jq -c -r .name_ref) == $(echo $(jq -c -r .vcenter.dvs.portgroup.nsx_external.name $jsonFile)-pg) ]] ; then
    for subnet in $(echo $network | jq -c -r '.subnets[]')
    do
      echo "  - $(echo $subnet | jq -c -r .cidr)" | tee -a output.txt
    done
  fi
done
echo "To Add avi-system name space:" | tee -a output.txt
echo "  - kubectl create ns avi-system" | tee -a output.txt
echo "AKO with ClusterIp requires a dedicated Service Engine Group per K8s workload cluster: The current deployment has created only one Service Engine Group" | tee -a output.txt
echo "To Add AKO leveraging helm Install (from the external-gw):" | tee -a output.txt
echo "  - helm --debug install ako/ako --generate-name --version $(jq -c -r .tkg.clusters.ako_version $jsonFile) -f path-to-values.yml --namespace=avi-system" | tee -a output.txt
echo "Create InfraSetting CRD (from the external-gw):" | tee -a output.txt
echo "  - kubectl apply -f avi-infra-settings-workload-vrf-X.yml" | tee -a output.txt
echo "Create CNF/App (from the external-gw):" | tee -a output.txt
echo "  - kubectl apply -f k8s-deployment-X.yml" | tee -a output.txt
echo "Create svc (from the external-gw):" | tee -a output.txt
echo "  - kubectl apply -f k8s-svc-X.yml" | tee -a output.txt
echo "Connect to the tier0 to check the routes" | tee -a output.txt
echo "  - get logical-routers" | tee -a output.txt
echo "  - vrf xxx" | tee -a output.txt
echo "  - get route" | tee -a output.txt
