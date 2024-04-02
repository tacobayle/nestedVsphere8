#!/bin/bash
jsonFile="/root/nsx.json"
source /nestedVsphere8/bash/nsx/nsx_api.sh
#
IFS=$'\n'
#
nsx_manager=$(jq -r .vsphere_underlay.networks.vsphere.management.nsx_nested_ip $jsonFile)
nsx_password=${TF_VAR_nsx_password}
#
/bin/bash /nestedVsphere8/bash/nsx/create_cert_ca.sh "${nsx_manager}" "${nsx_password}" \
  "cert_ca" \
  "/root/openssl/cert/My-Root-CA.crt" \
  "/root/openssl/cert/My-Root-CA.key" \
  "/root/openssl/cert/ca_private_key_passphrase.txt"
#
/bin/bash /nestedVsphere8/bash/nsx/create_cert.sh "${nsx_manager}" "${nsx_password}" \
  "app_cert" \
  "/root/openssl/cert/app_cert.crt" \
  "/root/openssl/cert/app_cert.key"
#