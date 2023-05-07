#!/bin/bash
#
#
source /nestedVsphere8/bash/vcd/vcd_api.sh
#
jsonFile=$1
vcd_administrator_password=$TF_VAR_vcd_administrator_password
api_version=$2
api_host="$(jq -r .vsphere_nested.vcsa_name $jsonFile).$(jq -r .external_gw.bind.domain $jsonFile)"
nsx_nested_ip=$(jq -r .vsphere_underlay.networks.vsphere.management.nsx_nested_ip $jsonFile)
avi_nested_ip=$(jq -r .vsphere_underlay.networks.vsphere.management.avi_nested_ip $jsonFile)
nsx_manager_name=$(jq -r .external_gw.nsx_manager_name $jsonFile)
alb_controller_name=$(jq -r .external_gw.alb_controller_name $jsonFile)
#
vcd_nested_ip=$(jq -r .vsphere_underlay.networks.vsphere.management.vcd_nested_ip $jsonFile)
#
token=$(/bin/bash /nestedVsphere8/bash/vcd/create_vcd_api_session.sh "$vcd_administrator_password" "$vcd_nested_ip" "$api_version")
vcd_api 2 2 "POST" $token "{\"alias\": \"$api_host\", \"certificate\": \"$(cat /root/$api_host.cert | awk '{printf "%s\\n", $0}')\"}" $vcd_nested_ip "cloudapi/1.0.0/ssl/trustedCertificates" "$api_version"
vcd_api 2 2 "POST" $token "{\"alias\": \"$nsx_manager_name\", \"certificate\": \"$(cat /root/$nsx_nested_ip.cert | awk '{printf "%s\\n", $0}')\"}" $vcd_nested_ip "cloudapi/1.0.0/ssl/trustedCertificates" "$api_version"
vcd_api 2 2 "POST" $token "{\"alias\": \"$alb_controller_name\", \"certificate\": \"$(cat /root/$avi_nested_ip.cert | awk '{printf "%s\\n", $0}')\"}" $vcd_nested_ip "cloudapi/1.0.0/ssl/trustedCertificates" "$api_version"