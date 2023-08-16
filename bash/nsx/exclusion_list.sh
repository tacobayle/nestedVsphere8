#!/bin/bash
#
source /nestedVsphere8/bash/nsx/nsx_api.sh
#
jsonFile="/root/nsx.json"
#
IFS=$'\n'
nsx_nested_ip=$(jq -r .vsphere_underlay.networks.vsphere.management.nsx_nested_ip $jsonFile)
cookies_file="exclusion_cookies.txt"
headers_file="exclusion_headers.txt"
rm -f $cookies_file $headers_file
#
/bin/bash /nestedVsphere8/bash/nsx/create_nsx_api_session.sh admin $TF_VAR_nsx_password $nsx_nested_ip $cookies_file $headers_file
#
# retrieve current exclusion list members
#members=$(curl -k  -X GET -b cookies.txt -H "`grep X-XSRF-TOKEN headers.txt`" -H "Content-Type: application/json" https://$nsx_ip$(jq -c -r .nsx.config.exclusion_list_api_endpoint $jsonFile) | jq -c -r .members)
members=$(nsx_api 6 10 "GET" $cookies_file $headers_file "" $nsx_nested_ip "$(jq -c -r .nsx.config.exclusion_list_api_endpoint $jsonFile)" | jq -c -r .members)
#
for member in $(jq -c -r .nsx.config.exclusion_list_groups[] $jsonFile)
do
  members=$(echo $members | jq '. += ["/infra/domains/default/groups/'$(echo $member)'"]')
done
# update new exclusion list members
#curl -k -s -X PATCH -b cookies.txt -H "`grep X-XSRF-TOKEN headers.txt`" -H "Content-Type: application/json" -d '{"members": '$(echo $members | jq -c -r .)'}' https://$nsx_ip$(jq -c -r .nsx.config.exclusion_list_api_endpoint $jsonFile)
new_json="{\"members\": '$(echo $members | jq -c -r .)'}"
nsx_api 6 10 "PATCH" $cookies_file $headers_file "$(echo $new_json)" $nsx_nested_ip "$(jq -c -r .nsx.config.exclusion_list_api_endpoint $jsonFile)"