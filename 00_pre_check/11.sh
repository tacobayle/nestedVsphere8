#!/bin/bash
#
source /nestedVsphere8/bash/ip.sh
#
jsonFile="/root/variables.json"
localJsonFile="/nestedVsphere8/11_vsphere_with_tanzu/variables.json"
rm -f /root/tanzu_wo_nsx.json
tanzu_wo_nsx_json=$(jq -c -r . $jsonFile | jq .)
#
IFS=$'\n'
#
echo ""
echo "==> Creating /root/tanzu_wo_nsx.json file..."
echo "   +++ Adding Networks"
networks_details=$(jq -c -r .networks "/nestedVsphere8/02_external_gateway/variables.json")
tanzu_wo_nsx_json=$(echo $tanzu_wo_nsx_json | jq '. += {"networks": '$(echo $networks_details)'}')
#
echo "   +++ Adding tanzu_local"
tanzu_local=$(jq -c -r .tanzu_local $localJsonFile)
tanzu_wo_nsx_json=$(echo $tanzu_wo_nsx_json | jq '. += {"tanzu_local": '$(echo $tanzu_local)'}')
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_alb_wo_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_tanzu_alb_wo_nsx" ]]; then
  echo "   +++ Adding netmasks"
  alb_networks='["se", "backend", "vip", "tanzu"]'
  for network in $(echo $alb_networks | jq -c -r .[])
  do
    echo "   +++ Adding prefix for alb $network network..."
    netmask=$(ip_netmask_by_prefix $(jq -c -r '.vsphere_underlay.networks.alb.'$network'.cidr'  $jsonFile| cut -d"/" -f2) "   ++++++")
    tanzu_wo_nsx_json=$(echo $tanzu_wo_nsx_json | jq '.vsphere_underlay.networks.alb.'$network' += {"netmask": "'$(echo $netmask)'"}')
  done
fi
#
echo $tanzu_wo_nsx_json | jq . | tee /root/tanzu_wo_nsx.json > /dev/null