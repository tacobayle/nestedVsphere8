#!/bin/bash
#
jsonFile="/etc/config/variables.json"
localJsonFile="/nestedVsphere8/07_nsx_alb/variables.json"
#
IFS=$'\n'
#
if [[ $(jq -c -r .avi $jsonFile) != "null" ]]; then
  echo ""
  echo "==> Creating /root/avi.json file..."
  rm -f /root/avi.json
  avi_json=$(jq -c -r . $jsonFile | jq .)
  #
  echo "   +++ Adding avi_ova_path..."
  avi_ova_path=$(jq -c -r '.avi_ova_path' $localJsonFile)
  avi_json=$(echo $avi_json | jq '. += {"avi_ova_path": "'$(echo $avi_ova_path)'"}')
  #
  echo "   +++ Adding nsx_alb_se_cl..."
  nsx_alb_se_cl=$(jq -c -r '.nsx_alb_se_cl' $localJsonFile)
  avi_json=$(echo $avi_json | jq '. += {"nsx_alb_se_cl": "'$(echo $nsx_alb_se_cl)'"}')
  #
  echo "   +++ Adding avi_port_group..."
  avi_port_group=$(jq -c -r '.networks.vsphere.management.port_group_name' /nestedVsphere8/03_nested_vsphere/variables.json)
  avi_json=$(echo $avi_json | jq '. += {"avi_port_group": "'$(echo $avi_port_group)'"}')
  #
  echo $avi_json | jq . | tee /root/avi.json > /dev/null
  #
  echo ""
  echo "==> Downloading Avi ova file"
  if [ -s "$(jq -c -r .avi_ova_path $localJsonFile)" ]; then echo "   +++ Avi ova file $(jq -c -r .avi_ova_path $localJsonFile) is not empty" ; else curl -s -o $(jq -c -r .avi_ova_path $localJsonFile) $(jq -c -r .avi.ova_url $jsonFile) ; fi
  if [ -s "$(jq -c -r .avi_ova_path $localJsonFile)" ]; then echo "   +++ Avi ova file $(jq -c -r .avi_ova_path $localJsonFile) is not empty" ; else echo "   +++ NSX ova $(jq -c -r .avi_ova_path $localJsonFile) is empty" ; exit 255 ; fi
  #
fi
