#!/bin/bash
#
jsonFile="/etc/config/variables.json"
localJsonFile="/nestedVsphere8/07_nsx_alb/variables.json"
#

if [[ $(jq -c -r .nsx $jsonFile) != "null" ]]; then
  if [[ $(jq -c -r .nsx.avi $jsonFile) != "null" ]]; then
    #
    echo ""
    echo "==> Downloading Avi ova file"
    if [ -s "$(jq -c -r .avi_ova_path $localJsonFile)" ]; then echo "   +++ Avi ova file $(jq -c -r .avi_ova_path $localJsonFile) is not empty" ; else curl -s -o $(jq -c -r .avi_ova_path $localJsonFile) $(jq -c -r .nsx.avi.ova_url $jsonFile) ; fi
    if [ -s "$(jq -c -r .avi_ova_path $localJsonFile)" ]; then echo "   +++ Avi ova file $(jq -c -r .avi_ova_path $localJsonFile) is not empty" ; else echo "   +++ NSX ova $(jq -c -r .avi_ova_path $localJsonFile) is empty" ; exit 255 ; fi
    #
  fi
fi