#!/bin/bash
#
source /nestedVsphere8/bash/test_if_variables.sh
source /nestedVsphere8/bash/data_validation/alb.sh
source /nestedVsphere8/bash/data_validation/nsx.sh
source /nestedVsphere8/bash/data_validation/tanzu.sh
source /nestedVsphere8/bash/data_validation/tkg.sh
source /nestedVsphere8/bash/ip.sh
#
jsonFile="/etc/config/variables.json"
rm -f /root/variables.json
variables_json=$(jq -c -r . $jsonFile | jq .)
IFS=$'\n'
#
# Env Variables
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
# Underlay vSphere Variables
#
echo ""
echo "==> Checking Underlay vSphere Variables"
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
  test_if_variable_is_valid_cidr "$(jq -c -r .vsphere_underlay.networks.vsphere.$network.cidr $jsonFile)" "   "
  test_if_json_variable_is_defined .vsphere_underlay.networks.vsphere.$network.esxi_ips $jsonFile "   "
  for ip in $(jq -c -r .vsphere_underlay.networks.vsphere.$network.esxi_ips[] $jsonFile)
  do
    test_if_variable_is_valid_ip $ip "   "
  done
  if [[ $(jq -r '.vsphere_underlay.networks.vsphere.'$network'.esxi_ips | length' $jsonFile) -lt $(jq -r '.vsphere_underlay.networks.vsphere.management.esxi_ips | length' $jsonFile) ]] ; then
    echo "   +++ .vsphere_underlay.networks.vsphere.$network.esxi_ips don't get enought IP(s)"
    exit 255
  fi
  #
  echo "   +++ Adding prefix for $network network..."
  prefix=$(jq -c -r .vsphere_underlay.networks.vsphere.$network.cidr $jsonFile | cut -d"/" -f2)
  variables_json=$(echo $variables_json | jq '.vsphere_underlay.networks.vsphere.'$network' += {"prefix": "'$(echo $prefix)'"}')
  #
  echo "   +++ Adding netmask for $network network..."
  netmask=$(ip_netmask_by_prefix $(jq -c -r .vsphere_underlay.networks.vsphere.$network.cidr $jsonFile | cut -d"/" -f2) "   ++++++")
  variables_json=$(echo $variables_json | jq '.vsphere_underlay.networks.vsphere.'$network' += {"netmask": "'$(echo $netmask)'"}')
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
# External Gateway Variables
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
# Nested vCenter Variables
#
echo ""
echo "==> Checking Nested vCenter Variables"
test_if_json_variable_is_defined .vsphere_nested.vcsa_name $jsonFile "   "
test_if_json_variable_is_defined .vsphere_nested.iso_url $jsonFile "   "
test_if_json_variable_is_defined .vsphere_nested.esxi.iso_url $jsonFile "   "
test_if_json_variable_is_defined .vsphere_nested.datacenter $jsonFile "   "
test_if_json_variable_is_defined .vsphere_nested.cluster_basename $jsonFile "   "
test_if_json_variable_is_defined .vsphere_nested.cluster_esxi_count $jsonFile "   "
if [[ $(jq -c -r '.vsphere_nested.cluster_esxi_count' $jsonFile) -lt 3 ]] ; then echo "   +++ At least 3 ESXi hosts per cluster are required" ; exit 255 ; fi
echo "   +++ Adding a count_cluster"
cluster_esxi_count=$(jq -r .vsphere_nested.cluster_esxi_count $jsonFile)
count_cluster=$(($(jq -r '.vsphere_underlay.networks.vsphere.management.esxi_ips | length' $jsonFile)/${cluster_esxi_count}))
variables_json=$(echo $variables_json | jq '.vsphere_nested += {"count_cluster": '$(echo $count_cluster)'}')
cluster_list="[]"
datastore_list="[]"
count_datastore=0
for cluster in $(seq 1 ${count_cluster})
do
  cluster_list=$(echo $cluster_list | jq  '. += ["'$(jq -c -r .vsphere_nested.cluster_basename $jsonFile)${cluster}'"]')
  if [[ ${count_datastore} -eq 0 ]] ; then
    datastore_list=$(echo $datastore_list | jq  '. += ["vsanDatastore"]')
  else
    datastore_list=$(echo $datastore_list | jq  '. += ["vsanDatastore ('${count_datastore}')"]')
  fi
  ((count_datastore++))
done
echo "   +++ Adding a .vsphere_nested.cluster_list"
variables_json=$(echo $variables_json | jq '.vsphere_nested += {"cluster_list": '$(echo $cluster_list)'}')
echo "   +++ Adding a .vsphere_nested.datastore_list"
variables_json=$(echo $variables_json | jq '.vsphere_nested += {"datastore_list": '$(echo $datastore_list)'}')
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
  mv /nestedVsphere8/02_external_gateway/external_gw.tf.disabled /nestedVsphere8/02_external_gateway/external_gw.tf
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
    echo "   ++++++ ERROR: cannot get .vsphere_underlay.networks.alb defined without .avi defined"
    exit 255
  fi
  # setting unmanaged_k8s_status disabled by default
  variables_json=$(echo $variables_json | jq '. += {"unmanaged_k8s_status": false}')
  #
  if [[ $(jq -c -r .vsphere_underlay.networks.alb.se.app_ips $jsonFile) != "null" || $(jq -c -r .vsphere_underlay.networks.alb.se.k8s_clusters $jsonFile) != "null" ]] ; then
    echo "app_ips or k8s_clusters is not supported on Port Group SE - because NAT is disabled hence no Internet Access from this port group"
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
      test_if_list_contains_ip "${jsonFile}" ".vsphere_underlay.networks.alb.$network.app_ips[]"
    fi
    #
    if [[ $(jq -c -r .vsphere_underlay.networks.alb.$network.k8s_clusters $jsonFile) != "null" ]] ; then
      count_cluster=0
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
        test_if_variable_is_defined $(echo $cluster | jq -c .cluster_ips) "   " "testing if each .vsphere_underlay.networks.alb.$network.k8s_clusters[] have a cluster_ips defined"
        if [[ $(echo $cluster | jq -c -r '.cluster_ips | length') -lt 3 ]] ; then echo "   +++ Amount of cluster_ips should be higher than 3" ; exit 255 ; fi
        test_if_list_contains_ip "${jsonFile}" ".vsphere_underlay.networks.alb.$network.k8s_clusters[${count_cluster}].cluster_ips[]"
         ((count_cluster++))
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
    test_variables_if_tanzu "/etc/config/variables.json" "vds"
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
  if $(jq -e '.nsx | has("cluster_ref")' $jsonFile) ; then
    if $(echo $variables_json | jq -e -c -r --arg arg "$(jq -c -r '.nsx.cluster_ref' $jsonFile)" '.vsphere_nested.cluster_list[] | select( . == $arg )'> /dev/null) ; then
      echo "   +++ .nsx.cluster_ref found"
    else
      echo "   +++ ERROR .nsx.cluster_ref not found in .vsphere_nested.cluster_list[]"
      exit 255
    fi
  fi
  test_if_json_variable_is_defined .nsx.config.edge_node.size $jsonFile "   "
  if [[ $(jq -c -r '.nsx.config.edge_node.size' $jsonFile | tr '[:upper:]' [:lower:]) != "small" && \
        $(jq -c -r '.nsx.config.edge_node.size' $jsonFile | tr '[:upper:]' [:lower:]) != "medium" && \
        $(jq -c -r '.nsx.config.edge_node.size' $jsonFile | tr '[:upper:]' [:lower:]) != "large" && \
        $(jq -c -r '.nsx.config.edge_node.size' $jsonFile | tr '[:upper:]' [:lower:]) != "extra_large" ]] ; then
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
    if [[ $(echo $item | jq -c -r .lb) == true ]] ; then
  test_if_variable_is_defined $(echo $item | jq -c .ha_mode) "   " "testing if .nsx.config.tier1s[] have a ha_mode defined"
      test_if_variable_is_defined $(echo $item | jq -c .edge_cluster_name) "   " "testing if .nsx.config.tier1s[] have a edge_cluster_name defined"
      if [[ $(echo $item | jq -c -r .ha_mode) != "ACTIVE_STANDBY" ]] ; then
        echo "   +++ Only .nsx.config.tier1s[].ha_mode equals to 'ACTIVE_STANDBY' has been tested when .nsx.config.tier1s[].lb is true"
        exit 255
      fi
      if $(jq -e -c -r --arg arg "$(echo $item | jq -c -r .edge_cluster_name)" '.nsx.config.edge_clusters[] | select( .display_name == $arg )' $jsonFile > /dev/null) ; then
        echo "   +++ .nsx.config.tier1s[].edge_cluster_name found in .nsx.config.edge_clusters[].display_name"
      else
        echo "   +++ ERROR .nsx.config.tier1s[].edge_cluster_name not found in .nsx.config.edge_clusters[].display_name"
        exit 255
      fi
    fi
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
  # check uniqueness
  test_if_list_of_value_is_unique "${jsonFile}" ".nsx.config.segments_overlay[].display_name"
  test_if_list_of_value_is_unique "${jsonFile}" ".nsx.config.segments_overlay[].cidr"
  test_if_list_of_value_is_unique "${jsonFile}" ".nsx.config.segments_overlay[].dhcp_ranges"
  #
  test_if_ref_from_list_exists_in_another_list ".nsx.config.segments_overlay[].tier1" \
                                               ".nsx.config.tier1s[].display_name" \
                                               "$jsonFile" \
                                               "   +++ Checking Tiers 1 in segments_overlay" \
                                               "   ++++++ Tier1 " \
                                               "   ++++++ERROR++++++ Tier1 not found: "
  # .nsx.config.ip_blocks
  if $(jq -e '.nsx.config | has("ip_blocks")' $jsonFile) ; then
    for ip_block in $(jq -c -r '.nsx.config.ip_blocks[]' ${jsonFile})
    do
      test_if_variable_is_defined $(echo $ip_block | jq -c -r .name) "   " "testing if each .nsx.config.ip_blocks[] have a name defined"
      test_if_variable_is_defined $(echo $ip_block | jq -c -r .cidr) "   " "testing if each .nsx.config.ip_blocks[] have a cidr defined"
      test_if_variable_is_valid_cidr "$(echo $ip_block | jq -c -r .cidr)" "   "
      test_if_variable_is_defined $(echo $ip_block | jq -c -r .visibility) "   " "testing if each .nsx.config.ip_blocks[] have a visibility defined"
      if [[ $(echo $ip_block | jq -c -r .visibility) != "PRIVATE" \
         && $(echo $ip_block | jq -c -r .visibility) !=  "EXTERNAL" ]] ; then
        echo "   +++ ERROR .nsx.config.ip_blocks[] called $(echo $ip_block | jq -c -r .name) should have .visibility configures with either 'PRIVATE' or 'EXTERNAL'"
        exit 255
      fi
      if $(echo ${ip_block} | jq -e -c -r '. | has("project_ref")') ; then
        if $(jq -e '.nsx.config | has("projects")' $jsonFile) ; then
          if $(jq -e -c -r --arg arg "$(echo ${ip_block} | jq -r -c .project_ref)" '.nsx.config.projects[] | select( .name == $arg )' ${jsonFile} > /dev/null) ; then
            echo "   +++ .nsx.config.ip_block called $(echo $ip_block | jq -c -r .name).project_ref found in .nsx.config.projects[].name"
          else
            echo "   +++ ERROR .nsx.config.ip_block called $(echo $ip_block | jq -c -r .name).project_ref not found in .nsx.config.projects[].name"
            exit 255
          fi
        else
          echo "   +++ ERROR .nsx.config.ip_block called $(echo $ip_block | jq -c - r .name).project_ref not found: .nsx.config.projects[] is not defined"
          exit 255
        fi
      fi
    done
    test_if_list_of_value_is_unique "${jsonFile}" ".nsx.config.ip_blocks[].name"
    test_if_list_of_value_is_unique "${jsonFile}" ".nsx.config.ip_blocks[].cidr"
  fi
  # .nsx.config.projects
  if $(jq -e '.nsx.config | has("projects")' $jsonFile) ; then
    for project in $(jq -c -r '.nsx.config.projects[]' ${jsonFile})
    do
      test_if_variable_is_defined $(echo $project | jq -c -r .name) "   " "testing if each .nsx.config.projects[] have a name defined"
      test_if_variable_is_defined $(echo $project | jq -c -r .ip_block_ref) "   " "testing if each .nsx.config.projects[] have a ip_block_ref defined"
      test_if_variable_is_defined $(echo $project | jq -c -r .tier0_ref) "   " "testing if each .nsx.config.projects[] have a tier0_ref defined"
      test_if_variable_is_defined $(echo $project | jq -c -r .edge_cluster_ref) "   " "testing if each .nsx.config.projects[] have a edge_cluster_ref defined"
    done
    test_if_list_of_value_is_unique "${jsonFile}" ".nsx.config.projects[].name"
    test_if_list_of_value_is_unique "${jsonFile}" ".nsx.config.projects[].ip_block_ref"
    #
    if $(jq -e '.nsx.config | has("ip_blocks")' $jsonFile) ; then
      if $(jq -e -c -r --arg arg "$(echo $project | jq -c -r .ip_block_ref)" '.nsx.config.ip_blocks[] | select( .name == $arg )' ${jsonFile} > /dev/null) ; then
        echo "   +++ .nsx.config.projects called $(echo $project | jq -c -r .name).ip_block_ref found in .nsx.config.tier0s[].display_name"
      else
        echo "   +++ ERROR .nsx.config.projects called $(echo $project | jq -c -r .name).ip_block_ref not found in .nsx.config.ip_blocks[].name"
        exit 255
      fi
    else
      echo "   +++ ERROR .nsx.config.projects called $(echo $project | jq -c -r .name).ip_block_ref not found in .nsx.config.ip_blocks[].name: .nsx.config.ip_blocks[] is not defined"
      exit 255
    fi
    #
    if $(jq -e -c -r --arg arg "$(echo $project | jq -c -r .tier0_ref)" '.nsx.config.tier0s[] | select( .display_name == $arg )' ${jsonFile} > /dev/null) ; then
      echo "   +++ .nsx.config.projects called $(echo $project | jq -c -r .name).tier0_ref found in .nsx.config.tier0s[].display_name"
    else
      echo "   +++ ERROR .nsx.config.projects called $(echo $project | jq -c -r .name).tier0_ref not found in .nsx.config.tier0s[].display_name"
      exit 255
    fi
    #
    if $(jq -e -c -r --arg arg "$(echo $project | jq -c -r .edge_cluster_ref)" '.nsx.config.edge_clusters[] | select( .display_name == $arg )' ${jsonFile} > /dev/null) ; then
      echo "   +++ .nsx.config.projects called $(echo $project | jq -c -r .name).edge_cluster_ref found in .nsx.config.edge_clusters[].display_name"
    else
      echo "   +++ ERROR .nsx.config.projects called $(echo $project | jq -c -r .name).edge_cluster_ref not found in .nsx.config.edge_clusters[].display_name"
      exit 255
    fi
  fi
  # .nsx.config.vpcs
  if $(jq -e '.nsx.config | has("vpcs")' $jsonFile) ; then
    if $(jq -e '.nsx.config | has("projects") | not' $jsonFile) ; then
      echo "   +++ ERROR .nsx.config.vpc mandates .nsx.config.projects[] to be defined"
      exit 255
    fi
    for vpc in $(jq -c -r '.nsx.config.vpcs[]' ${jsonFile})
    do
      test_if_variable_is_defined $(echo $vpc | jq -c -r .name) "   " "testing if each .nsx.config.vpcs[] have a name defined"
      test_if_variable_is_defined $(echo $vpc | jq -c -r .project_ref) "   " "testing if each .nsx.config.vpcs[] have a project_ref defined"
      test_if_variable_is_defined $(echo $vpc | jq -c -r .ip_block_private_ref) "   " "testing if each .nsx.config.vpcs[] have a ip_block_private_ref defined"
      test_if_variable_is_defined $(echo $vpc | jq -c -r .ip_block_public_ref) "   " "testing if each .nsx.config.vpcs[] have a ip_block_public_ref defined"
    done
    if $(jq -e -c -r --arg arg "$(echo $vpc | jq -c -r .project_ref)" '.nsx.config.projects[] | select( .name == $arg )' ${jsonFile} > /dev/null) ; then
      echo "   +++ .nsx.config.vpc called $(echo $vpc | jq -c -r .name).project_ref ref found in .nsx.config.projects[].name"
    else
      echo "   +++ ERROR .nsx.config.vpc called $(echo $project | jq -c -r .name).project_ref not found in .nsx.config.projects[].name"
      exit 255
    fi
    if $(jq -e -c -r --arg arg "$(echo $vpc | jq -c -r .ip_block_public_ref)" '.nsx.config.projects[] | select( .ip_block_ref == $arg )' ${jsonFile} > /dev/null) ; then
      echo "   +++ .nsx.config.vpc called $(echo $vpc | jq -c -r .name).ip_block_public_ref ref found in .nsx.config.projects[].ip_block_ref"
    else
      echo "   +++ ERROR .nsx.config.vpc called $(echo $project | jq -c -r .name).ip_block_public_ref not found in .nsx.config.projects[].ip_block_ref"
      exit 255
    fi
    if $(jq -e -c -r --arg arg "$(echo $vpc | jq -c -r .ip_block_private_ref)" '.nsx.config.ip_blocks[] | select( .name == $arg and .visibility == "PRIVATE")' ${jsonFile} > /dev/null) ; then
      echo "   +++ .nsx.config.vpc called $(echo $vpc | jq -c -r .name).ip_block_private_ref ref found in .nsx.config.ip_blocks[].name"
    else
      echo "   +++ ERROR .nsx.config.vpc called $(echo $project | jq -c -r .name).ip_block_private_ref not found in .nsx.config.projects[].name with visibility == PRIVATE"
      exit 255
    fi
    test_if_list_of_value_is_unique "${jsonFile}" ".nsx.config.vpcs[].project_ref"
    test_if_list_of_value_is_unique "${jsonFile}" ".nsx.config.vpcs[].ip_block_private_ref"
    test_if_list_of_value_is_unique "${jsonFile}" ".nsx.config.vpcs[].ip_block_public_ref"
  fi
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
    test_tkg "/etc/config/variables.json"
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
    test_variables_if_tanzu "/etc/config/variables.json" "nsx"
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