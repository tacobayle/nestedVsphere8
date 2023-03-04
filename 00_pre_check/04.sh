#!/bin/bash
#
jsonFile="/etc/config/variables.json"
localJsonFile="/nestedVsphere8/02_external_gateway/variables.json"
#
IFS=$'\n'
#
if [[ $(jq -c -r .nsx $jsonFile) != "null" ]]; then
  echo ""
  echo "==> Creating /root/nsx1.json file..."
  rm -f /root/nsx1.json
  nsx_json=$(jq -c -r . $jsonFile | jq .)
  #
  echo "   +++ Adding networks..."
  networks=$(jq -c -r '.networks' $localJsonFile)
  nsx_json=$(echo $nsx_json | jq '. += {"networks": '$(echo $networks)'}')
  #
  echo $nsx_json | jq . | tee /root/nsx1.json > /dev/null
fi
