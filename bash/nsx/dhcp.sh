#!/bin/bash
#
source /nestedVsphere8/bash/nsx/nsx_api.sh
#
jsonFile="/root/nsx.json"
#
IFS=$'\n'
nsx_nested_ip=$(jq -r .vsphere_underlay.networks.vsphere.management.nsx_nested_ip $jsonFile)
cookies_file="dhcp_cookies.txt"
headers_file="dhcp_headers.txt"
rm -f $cookies_file $headers_file
#
/bin/bash /nestedVsphere8/bash/nsx/create_nsx_api_session.sh admin $TF_VAR_nsx_password $nsx_nested_ip $cookies_file $headers_file
#
for dhcp_server in $(jq -c -r .nsx.config.dhcp_servers[] $jsonFile)
do
  new_json="{\"display_name\": \"$(echo $dhcp_server | jq -r .name)\", \"server_address\": \"$(echo $dhcp_server | jq -r .server_address)\", \"lease_time\": \"$(echo $dhcp_server | jq -r .lease_time)\"}"
#  curl -k -s -X PUT -b cookies.txt -H "`grep X-XSRF-TOKEN headers.txt`" -H "Content-Type: application/json" -d $(echo $new_json) https://$nsx_ip$(jq -c -r .nsx.config.dhcp_servers_api_endpoint $jsonFile)/$(echo $dhcp_server | jq -r .name)
  nsx_api 2 2 "PUT" $cookies_file $headers_file "$(echo $new_json)" $nsx_nested_ip "$(jq -c -r .nsx.config.dhcp_servers_api_endpoint $jsonFile)/$(echo $dhcp_server | jq -r .name)"
done