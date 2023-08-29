#!/bin/bash
#
source /nestedVsphere8/bash/nsx/nsx_api.sh
#
jsonFile="/root/nsx.json"
#
IFS=$'\n'
nsx_nested_ip=$(jq -r .vsphere_underlay.networks.vsphere.management.nsx_nested_ip $jsonFile)
cookies_file="group_cookies.txt"
headers_file="group_headers.txt"
rm -f $cookies_file $headers_file
#
/bin/bash /nestedVsphere8/bash/nsx/create_nsx_api_session.sh admin $TF_VAR_nsx_password $nsx_nested_ip $cookies_file $headers_file
#
for group in $(jq -c -r .nsx.config.groups[] $jsonFile)
do
#  curl -k -s -X PUT -b cookies.txt -H "`grep X-XSRF-TOKEN headers.txt`" -H "Content-Type: application/json" -d $(echo $group) https://$nsx_ip$(jq -c -r .nsx.config.groups_api_endpoint $jsonFile)/$(echo $group | jq -r .display_name)
  nsx_api 6 10 "PUT" $cookies_file $headers_file "$(echo $group)" $nsx_nested_ip "$(jq -c -r .nsx.config.groups_api_endpoint $jsonFile)/$(echo $group | jq -r .display_name)"
done