#!/bin/bash
#
#
source /nestedVsphere8/bash/vcd/vcd_api.sh
#
jsonFile=$1
vcd_administrator_password=$TF_VAR_vcd_administrator_password
api_version=$2
api_host="$(jq -r .vsphere_nested.vcsa_name $jsonFile).$(jq -r .external_gw.bind.domain $jsonFile)"
vsphere_nested_username=administrator
vcenter_domain=$(jq -r .vsphere_nested.sso.domain_name $jsonFile)
vsphere_nested_password=$TF_VAR_vsphere_nested_password

#
vcd_nested_ip=$(jq -r .vsphere_underlay.networks.vsphere.management.vcd_nested_ip $jsonFile)
#
token=$(/bin/bash /nestedVsphere8/bash/vcd/create_vcd_api_session.sh "$vcd_administrator_password" "$vcd_nested_ip" "$api_version")
vcd_api 2 2 "POST" $token "{\"name\": \"$api_host\", \"url\": \"https://$api_host\", \"username\": \"$vsphere_nested_username@$vcenter_domain\", \"password\": \"$vsphere_nested_password\", \"isConnected\": \"True\", \"isEnabled\": \"True\"}" $vcd_nested_ip "cloudapi/1.0.0/virtualCenters" "$api_version"