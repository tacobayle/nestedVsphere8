#!/bin/bash
#
source /nestedVsphere8/bash/ip.sh
#
jsonFile="/root/variables.json"
localJsonFile="/nestedVsphere8/12_vsphere_with_tanzu/variables.json"
rm -f /root/vsphere_with_tanzu.json
vsphere_with_tanzu=$(jq -c -r . $jsonFile | jq .)
#
IFS=$'\n'
#
echo ""
echo "==> Creating /root/vsphere_with_tanzu.json file..."
echo "   +++ Adding Networks"
networks_details=$(jq -c -r .networks "/nestedVsphere8/02_external_gateway/variables.json")
vsphere_with_tanzu=$(echo $vsphere_with_tanzu | jq '. += {"networks": '$(echo $networks_details)'}')
#
echo "   +++ Adding tanzu_local"
tanzu_local=$(jq -c -r .tanzu_local $localJsonFile)
vsphere_with_tanzu=$(echo $vsphere_with_tanzu | jq '. += {"tanzu_local": '$(echo $tanzu_local)'}')
#
if $(jq -e '.tanzu.supervisor_cluster | has("cluster_ref")' $jsonFile) ; then
  echo "   +++ Tanzu Supervisor cluster will be installed on the top of cluster $(jq -c -r '.tanzu.supervisor_cluster.cluster_ref' $jsonFile)"
  vsan_datastore_index=$(jq -c -r --arg arg "$(jq -c -r '.tanzu.supervisor_cluster.cluster_ref' $jsonFile)" '.vsphere_nested.cluster_list | map( . == $arg ) | index(true)' $jsonFile)
  vsphere_with_tanzu=$(echo $vsphere_with_tanzu | jq '.tanzu.supervisor_cluster += {"datastore_ref": "'$(jq -c -r '.vsphere_nested.datastore_list['${vsan_datastore_index}']' $jsonFile)'"}')
else
  echo "   +++ Adding .tanzu.supervisor_cluster.cluster_ref..."
  vsphere_with_tanzu=$(echo $vsphere_with_tanzu | jq '.tanzu.supervisor_cluster += {"cluster_ref": "'$(jq -c -r '.vsphere_nested.cluster_list[0]' $jsonFile)'"}')
  vsphere_with_tanzu=$(echo $vsphere_with_tanzu | jq '.tanzu.supervisor_cluster += {"datastore_ref": "'$(jq -c -r '.vsphere_nested.datastore_list[0]' $jsonFile)'"}')
fi
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_tanzu_alb_wo_nsx" ]]; then
  echo "   +++ Adding netmasks"
  alb_networks='["se", "backend", "vip", "tanzu"]'
  for network in $(echo $alb_networks | jq -c -r .[])
  do
    echo "   +++ Adding prefix for alb $network network..."
    netmask=$(ip_netmask_by_prefix $(jq -c -r '.vsphere_underlay.networks.alb.'$network'.cidr'  $jsonFile| cut -d"/" -f2) "   ++++++")
    vsphere_with_tanzu=$(echo $vsphere_with_tanzu | jq '.vsphere_underlay.networks.alb.'$network' += {"netmask": "'$(echo $netmask)'"}')
  done
  #
  echo "   +++ Adding avi.config.cloud.name..."
  vsphere_with_tanzu=$(echo $vsphere_with_tanzu | jq '.avi.config.cloud += {"name": "'$(jq -c -r '.vcenter_default_cloud_name' /nestedVsphere8/07_nsx_alb/variables.json)'"}')
  #
fi
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_tanzu_alb" ]]; then
  #
  echo "   +++ Adding avi.config.cloud.name..."
  vsphere_with_tanzu=$(echo $vsphere_with_tanzu | jq '.avi.config.cloud += {"name": "'$(jq -c -r '.nsx_default_cloud_name' /nestedVsphere8/07_nsx_alb/variables.json)'"}')
  #
fi
#
echo $vsphere_with_tanzu | jq . | tee /root/vsphere_with_tanzu.json > /dev/null