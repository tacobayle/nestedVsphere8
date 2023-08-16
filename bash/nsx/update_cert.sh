#!/bin/bash
#
#
source /nestedVsphere8/bash/nsx/nsx_api.sh
#
jsonFile=$2
nsx_password=$TF_VAR_nsx_password
#
nsx_nested_ip=$(jq -r .vsphere_underlay.networks.vsphere.management.nsx_nested_ip $jsonFile)
#
# cert has to be generated and updated in the UI and in the API of the NSX Manager
#
echo -n | openssl s_client -connect $nsx_nested_ip:443 -servername $nsx_nested_ip | openssl x509 | tee /root/$nsx_nested_ip.cert