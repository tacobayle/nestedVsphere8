#!/bin/bash
#
source /nestedVsphere8/bash/vcenter_api.sh
#
jsonFile="/root/nested_vsphere.json"
#
api_host="$(jq -r .vsphere_nested.vcsa_name $jsonFile).$(jq -r .external_gw.bind.domain $jsonFile)"
vsphere_nested_username=administrator
vcenter_domain=$(jq -r .vsphere_nested.sso.domain_name $jsonFile)
vsphere_nested_password=$TF_VAR_vsphere_nested_password
#
token=$(/bin/bash /nestedVsphere8/bash/create_vcenter_api_session.sh "$vsphere_nested_username" "$vcenter_domain" "$vsphere_nested_password" "$api_host")
retry_a=10
pause_a=10
attempt_a=0
#
while true ; do
  echo "attempt $attempt_a to get VCSA status"
  vcenter_api 10 10 "GET" $token '' $api_host "api/appliance/health/system"
  if [[ $(echo $response_body) == '"green"' ]] ; then
    echo "VCSA status is $response_body after $attempt_a attempts"
    break 2
  fi
  ((attempt_a++))
  if [ $attempt_a -eq $retry_a ]; then
    echo "VCSA status is $response_body after $attempt_a attempts"
    exit 255
  fi
  sleep $pause_a
done
#