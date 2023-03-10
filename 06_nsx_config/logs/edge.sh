#!/bin/bash
#
if [ -f "../../variables.json" ]; then
  jsonFile="../../variables.json"
else
  echo "ERROR: no json file found"
  exit 1
fi
nsx_nested_ip=$(jq -r .vsphere_underlay.networks.vsphere.management.nsx_nested_ip $jsonFile)
rm -f cookies.txt headers.txt
curl -k -c cookies.txt -D headers.txt -X POST -d 'j_username=admin&j_password='$TF_VAR_nsx_password'' https://$nsx_nested_ip/api/session/create
curl -k -s -X GET -b cookies.txt -H "`grep X-XSRF-TOKEN headers.txt`" -H "Content-Type: application/json" https://$nsx_nested_ip/policy/api/v1/infra/sites/default/enforcement-points/default/transport-nodes
