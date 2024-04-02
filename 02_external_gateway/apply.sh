#!/bin/bash
jsonFile="/root/external_gw.json"
source /nestedVsphere8/bash/tf_init_apply.sh
#
# Build of an external GW server on the underlay infrastructure
#
external_gw_ip=$(jq -c -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile)
tf_init_apply "Build of an external GW server on the underlay infrastructure - This should take less than 10 minutes" /nestedVsphere8/02_external_gateway /nestedVsphere8/log/02.stdout /nestedVsphere8/log/02.stderr $jsonFile
# cert_creation.sh transfer
scp -o StrictHostKeyChecking=no /nestedVsphere8/02_external_gateway/bash/cert_creation.sh ubuntu@${external_gw_ip}:/home/ubuntu/openssl/cert_creation.sh >/dev/null 2>&1
# bash create exec
ssh -o StrictHostKeyChecking=no -t ubuntu@${external_gw_ip} "/bin/bash /home/ubuntu/openssl/cert_creation.sh" >/dev/null 2>&1
# copying cert from the external-gw
scp -r -o StrictHostKeyChecking=no ubuntu@${external_gw_ip}:/home/ubuntu/openssl /root > /dev/null 2>&1