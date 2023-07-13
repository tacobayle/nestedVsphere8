#!/bin/bash
#
jsonFile="/root/variables.json"
localJsonFile="/nestedVsphere8/08_app/variables.json"
#
IFS=$'\n'
#
echo ""
echo "==> Creating /root/app.json file..."
rm -f /root/app.json
app_json=$(jq -c -r . $jsonFile | jq .)
#
echo "   +++ Adding ubuntu_ova_path..."
ubuntu_ova_path=$(jq -c -r '.ubuntu_ova_path' /nestedVsphere8/02_external_gateway/variables.json)
app_json=$(echo $app_json | jq '. += {"ubuntu_ova_path": "'$(echo $ubuntu_ova_path)'"}')
#
echo "   +++ Adding app..."
app=$(jq -c -r '.app' $localJsonFile)
app_json=$(echo $app_json | jq '. += {"app": '$(echo $app)'}')
#
app_segments=[]
app_ips=[]
app_cidr=[]
#
if [[ $(jq -c -r .nsx $jsonFile) != "null" ]]; then
  #
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
  #
  echo "   +++ Adding variable nsx_password in /nestedVsphere8/08_app/tf_remote/variables.tf"
  echo 'variable "nsx_password" {}' | tee -a /nestedVsphere8/08_app/tf_remote/variables.tf > /dev/null
  #
  echo "   +++ Adding variable nsx_password in /nestedVsphere8/08_app/variables.tf"
  echo 'variable "nsx_password" {}' | tee -a /nestedVsphere8/08_app/variables.tf > /dev/null
  #
  mv /nestedVsphere8/08_app/tf_remote/version.tf.disabled /nestedVsphere8/08_app/tf_remote/version.tf
  mv /nestedVsphere8/08_app/tf_remote/nsx_tag.tf.disabled /nestedVsphere8/08_app/tf_remote/nsx_tag.tf
  mv /nestedVsphere8/08_app/tf_remote/provider_nsx.tf.disabled /nestedVsphere8/08_app/tf_remote/provider_nsx.tf
  mv /nestedVsphere8/08_app/template_file_nsx.tf.disabled /nestedVsphere8/08_app/template_file_nsx.tf
  mv /nestedVsphere8/08_app/template_file.tf /nestedVsphere8/08_app/template_file.tf.disabled
  #
fi
#
if [[ $(jq -c -r .vsphere_underlay.networks.alb $jsonFile) != "null" ]]; then
  #
#  if [[ $(jq -c -r .vsphere_underlay.networks.alb.se.app_ips $jsonFile) != "null" ]] ; then
#    for ip in $(jq -c -r .vsphere_underlay.networks.alb.se.app_ips[] $jsonFile)
#    do
#      app_ips=$(echo $app_ips | jq '. += ["'$(echo $ip)'"]')
#      app_segments=$(echo $app_segments | jq '. += ["'$(jq -c -r .networks.alb.se.port_group_name /nestedVsphere8/02_external_gateway/variables.json)'"]')
#      app_cidr=$(echo $app_cidr | jq '. += ["'$(jq -c -r .vsphere_underlay.networks.alb.se.cidr $jsonFile)'"]')
#    done
#  fi
  #
  if [[ $(jq -c -r .vsphere_underlay.networks.alb.backend.app_ips $jsonFile) != "null" ]] ; then
    for ip in $(jq -c -r .vsphere_underlay.networks.alb.backend.app_ips[] $jsonFile)
    do
      app_ips=$(echo $app_ips | jq '. += ["'$(echo $ip)'"]')
      app_segments=$(echo $app_segments | jq '. += ["'$(jq -c -r .networks.alb.backend.port_group_name /nestedVsphere8/02_external_gateway/variables.json)'"]')
      app_cidr=$(echo $app_cidr | jq '. += ["'$(jq -c -r .vsphere_underlay.networks.alb.backend.cidr $jsonFile)'"]')
    done
  fi
  #
  if [[ $(jq -c -r .vsphere_underlay.networks.alb.vip.app_ips $jsonFile) != "null" ]] ; then
    for ip in $(jq -c -r .vsphere_underlay.networks.alb.vip.app_ips[] $jsonFile)
    do
      app_ips=$(echo $app_ips | jq '. += ["'$(echo $ip)'"]')
      app_segments=$(echo $app_segments | jq '. += ["'$(jq -c -r .networks.alb.vip.port_group_name /nestedVsphere8/02_external_gateway/variables.json)'"]')
      app_cidr=$(echo $app_cidr | jq '. += ["'$(jq -c -r .vsphere_underlay.networks.alb.vip.cidr $jsonFile)'"]')
    done
  fi
  #
  if [[ $(jq -c -r .vsphere_underlay.networks.alb.tanzu.app_ips $jsonFile) != "null" ]] ; then
    for ip in $(jq -c -r .vsphere_underlay.networks.alb.tanzu.app_ips[] $jsonFile)
    do
      app_ips=$(echo $app_ips | jq '. += ["'$(echo $ip)'"]')
      app_segments=$(echo $app_segments | jq '. += ["'$(jq -c -r .networks.alb.tanzu.port_group_name /nestedVsphere8/02_external_gateway/variables.json)'"]')
      app_cidr=$(echo $app_cidr | jq '. += ["'$(jq -c -r .vsphere_underlay.networks.alb.tanzu.cidr $jsonFile)'"]')
    done
  #
  fi
fi
echo "   +++ Adding app_segments..."
app_json=$(echo $app_json | jq '. += {"app_segments": '$(echo $app_segments)'}')
app_json=$(echo $app_json | jq '. += {"app_cidr": '$(echo $app_cidr)'}')
app_json=$(echo $app_json | jq '. += {"app_ips": '$(echo $app_ips)'}')
echo $app_json | jq . | tee /root/app.json > /dev/null