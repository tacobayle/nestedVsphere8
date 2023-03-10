#!/bin/bash
#
jsonFile="/etc/config/variables.json"
localJsonFile="/nestedVsphere8/08_app/variables.json"
#
IFS=$'\n'
#
if [[ $(jq -c -r .avi $jsonFile) != "null" &&  $(jq -c -r .nsx $jsonFile) != "null" ]]; then
  echo ""
  echo "==> Creating /root/app.json file..."
  rm -f /root/app.json
  app_json=$(jq -c -r . $jsonFile | jq .)
  #
  echo "   +++ Adding ubuntu_ova_path..."
  ubuntu_ova_path=$(jq -c -r '.ubuntu_ova_path' /nestedVsphere8/02_external_gateway/variables.json)
  app_json=$(echo $app_json | jq '. += {"ubuntu_ova_path": "'$(echo $ubuntu_ova_path)'"}')
  #
  app_segments=[]
  app_ips=[]
  app_cidr=[]
  for item in $(jq -c -r .nsx.config.segments_overlay[] $jsonFile)
  do
    if [[ $(echo $item | jq -c .app_ips) != "null" ]] ; then
      for ip in $(echo $item | jq .app_ips[] -c -r)
      do
        app_ips=$(echo $app_ips | jq '. += ["'$(echo $ip)'"]')
        app_segments=$(echo $app_segments | jq '. += ["'$(echo $item | jq -c -r .display_name)'"]')
        app_cidr=$(echo $app_cidr | jq '. += ["'$(echo $item | jq -c -r .cidr)'"]')
      done
    fi
  done
  echo "   +++ Adding app_segments..."
  app_json=$(echo $app_json | jq '. += {"app_segments": '$(echo $app_segments)'}')
  app_json=$(echo $app_json | jq '. += {"app_cidr": '$(echo $app_cidr)'}')
  app_json=$(echo $app_json | jq '. += {"app_ips": '$(echo $app_ips)'}')
  #
  echo $app_json | jq . | tee /root/app.json > /dev/null
fi