#!/bin/bash
#
source /nestedVsphere8/bash/nsx_api.sh
#
jsonFile="/root/nsx.json"
#
nsx_nested_ip=$(jq -r .vsphere_underlay.networks.vsphere.management.nsx_nested_ip $jsonFile)
vcenter_username=administrator
vcenter_domain=$(jq -r .vsphere_nested.sso.domain_name $jsonFile)
vcenter_fqdn="$(jq -r .vsphere_nested.vcsa_name $jsonFile).$(jq -r .external_gw.bind.domain $jsonFile)"
cookies_file="compute_manager_cookies.txt"
headers_file="compute_manager_headers.txt"
rm -f $cookies_file $headers_file
#
/bin/bash /nestedVsphere8/bash/create_nsx_api_session.sh admin $TF_VAR_nsx_password $nsx_nested_ip $cookies_file $headers_file
ValidCmThumbPrint=$(openssl s_client -connect $vcenter_fqdn:443 < /dev/null 2>/dev/null | openssl x509 -fingerprint -sha256 -noout -in /dev/stdin | awk -F'Fingerprint=' '{print $2}')
nsx_api 6 10 "POST" $cookies_file $headers_file '{"display_name": "'$vcenter_fqdn'", "server": "'$vcenter_fqdn'", "create_service_account": true, "access_level_for_oidc": "FULL", "origin_type": "vCenter", "set_as_oidc_provider" : true, "credential": {"credential_type": "UsernamePasswordLoginCredential", "username": "'$vcenter_username'@'$vcenter_domain'", "password": "'$TF_VAR_vsphere_nested_password'", "thumbprint": "'$ValidCmThumbPrint'"}}' $nsx_nested_ip "api/v1/fabric/compute-managers"
compute_manager_id=$(echo $response_body | jq -r .id)
retry=6
pause=10
attempt=0
echo "Waiting for compute manager to be UP and REGISTERED"
while true ; do
  nsx_api 6 10 "GET" $cookies_file $headers_file "" $nsx_nested_ip "api/v1/fabric/compute-managers/$compute_manager_id/status"
  if [[ $(echo $response_body | jq -r .connection_status) == "UP" && $(echo $response_body | jq -r .registration_status) == "REGISTERED" ]] ; then
    echo "compute manager UP and REGISTERED"
    break
  fi
  if [ $attempt -eq $retry ]; then
    echo "FAILED to get compute manager UP and REGISTERED after $retry retries"
    exit 255
  fi
  sleep $pause
  ((attempt++))
done
rm -f $cookies_file $headers_file