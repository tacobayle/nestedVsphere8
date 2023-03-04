#!/bin/bash
#
jsonFile="/etc/config/variables.json"
localJsonFile="/nestedVsphere8/06_nsx_config/variables.json"
#
IFS=$'\n'
#
if [[ $(jq -c -r .nsx $jsonFile) != "null" ]]; then
  echo ""
  echo "==> Creating /root/nsx3.json file..."
  rm -f /root/nsx3.json
  nsx_json=$(jq -c -r . $jsonFile | jq .)
  #
  echo "   +++ Adding uplink_profiles..."
  uplink_profiles=$(jq -c -r '.uplink_profiles' $localJsonFile)
  uplink_profiles=$(echo $nsx_json | jq '. += {"uplink_profiles": '$(echo $uplink_profiles)'}')
  #
  echo "   +++ Adding transport_zones..."
  transport_zones=$(jq -c -r '.transport_zones' $localJsonFile)
  nsx_json=$(echo $nsx_json | jq '. += {"transport_zones": '$(echo $transport_zones)'}')
  #
  echo $nsx_json | jq . | tee /root/nsx3.json > /dev/null
  #
fi