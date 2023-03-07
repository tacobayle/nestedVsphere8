#!/bin/bash
#
jsonFile="/etc/config/variables.json"
localJsonFile="/nestedVsphere8/07_nsx_alb/variables.json"
#
IFS=$'\n'
#
if [[ $(jq -c -r .nsx.avi $jsonFile) != "null" ]]; then
  echo ""
  echo "==> Creating /root/avi1.json file..."
  rm -f /root/avi1.json
  avi_json=$(jq -c -r . $jsonFile | jq .)
  #
  echo "   +++ Adding avi_ova_path..."
  avi_ova_path=$(jq -c -r '.avi_ova_path' $localJsonFile)
  avi_json=$(echo $avi_json | jq '. += {"avi_ova_path": "'$(echo $avi_ova_path)'"}')
  #
  for item in $(jq -c -r .nsx.config.segments_overlay[] $jsonFile)
  do
    if [[ $(echo $item | jq -c .avi_ip) != "null" ]] ; then
      avi_segment=$(echo $item | jq -c .display_name)
      avi_ip=$(echo $item | jq -c .avi_ip)
      avi_cidr=$(echo $item | jq -c .cidr)
    fi
  done
  echo "   +++ Adding avi_segment..."
  avi_json=$(echo $avi_json | jq '. += {"avi_segment": "'$(echo $avi_segment)'"}')
  #
  echo "   +++ Adding avi_ip..."
  avi_json=$(echo $avi_json | jq '. += {"avi_ip": "'$(echo $avi_ip)'"}')
  #
  echo "   +++ Adding avi_cidr..."
  avi_json=$(echo $avi_json | jq '. += {"avi_cidr": "'$(echo $avi_cidr)'"}')
  #
  echo $avi_json | jq . | tee /root/avi1.json > /dev/null




  echo ""
  echo "==> Downloading Avi ova file"
  if [ -s "$(jq -c -r .avi_ova_path $localJsonFile)" ]; then echo "   +++ Avi ova file $(jq -c -r .avi_ova_path $localJsonFile) is not empty" ; else curl -s -o $(jq -c -r .avi_ova_path $localJsonFile) $(jq -c -r .nsx.avi.ova_url $jsonFile) ; fi
  if [ -s "$(jq -c -r .avi_ova_path $localJsonFile)" ]; then echo "   +++ Avi ova file $(jq -c -r .avi_ova_path $localJsonFile) is not empty" ; else echo "   +++ NSX ova $(jq -c -r .avi_ova_path $localJsonFile) is empty" ; exit 255 ; fi
  #
fi
