#!/bin/bash
#
jsonFile="/root/nested_vsphere.json"
#
source /nestedVsphere8/bash/govc/variables.sh
#
IFS=$'\n'
load_govc_esxi
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_tanzu_alb_wo_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_tanzu_alb" ]]; then
  for ip in $(cat $jsonFile | jq -c -r .vsphere_underlay.networks.vsphere.management.esxi_ips[])
  do
    export GOVC_URL=$ip
    for network in $(jq -r .vsphere_nested.ip_routes_vcenter[] $jsonFile)
    do
      echo "ESXi host IP: ${ip} // Adding route to network ${network} via gateway $(jq -c -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile)"
      govc host.esxcli network ip route ipv4 add --gateway $(jq -c -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile) --network ${network}
    done
  done
fi