#!/bin/bash
#
source /nestedVsphere8/bash/vcenter_api.sh
#
jsonFile="/etc/config/variables.json"
#
echo ""
echo "==> Checking vSphere folders for name conflict..."
api_host="$(jq -r .vcenter_underlay.server $jsonFile)"
vcenter_username=$TF_VAR_vsphere_underlay_username
vcenter_domain=''
vsphere_password=$TF_VAR_vsphere_underlay_password
#
token=$(/bin/bash /nestedVsphere8/bash/create_vcenter_api_session.sh "$vcenter_username" "$vcenter_domain" "$vsphere_password" "$api_host")
vcenter_api 6 10 "GET" $token "" $api_host "rest/vcenter/folder"
response_folder=$(echo $response_body)
IFS=$'\n'
for folder_entry in $(echo $response_folder | jq -c -r .value[])
do
  if [[ $(echo $folder_entry | jq -c -r .type) == "VIRTUAL_MACHINE" ]] ; then
    if [[ $(echo $folder_entry | jq -c -r .name) == $(jq -c -r .vcenter_underlay.folder $jsonFile) ]] ; then
      echo "  +++ ERROR +++ folder $(jq -c -r .vcenter_underlay.folder $jsonFile) already exists"
      exit 255
    fi
  fi
done
echo "  +++ No conflict found, OK"