#!/bin/bash
jsonFile="/root/external_gw.json"
source /nestedVsphere8/bash/tf_init_apply.sh
output_file="/root/output.txt"
echo "+++++++++++++++++ O U T P U T S +++++++++++++++++++++" | tee ${output_file} >/dev/null 2>&1
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
#
# outputs 02_external_gateway
#
echo "" | tee -a ${output_file} >/dev/null 2>&1
echo "+++++++ external-gateway" | tee -a ${output_file} >/dev/null 2>&1
echo "ssh your external gateway from the pod:" | tee -a ${output_file} >/dev/null 2>&1
echo "  > ssh -o StrictHostKeyChecking=no ubuntu@external-gw" | tee -a ${output_file} >/dev/null 2>&1
echo "ssh your external gateway from an external node:" | tee -a ${output_file} >/dev/null 2>&1
echo "  > ssh -o StrictHostKeyChecking=no ubuntu@$(jq -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile)" | tee -a ${output_file} >/dev/null 2>&1
echo "ssh ubuntu password: ${TF_VAR_ubuntu_password}" | tee -a ${output_file} >/dev/null 2>&1
deployment=$(jq -c -r .deployment $jsonFile)
if [[ ${deployment} == "vsphere_nsx_alb" || ${deployment} == "vsphere_nsx_tanzu_alb" ]]; then
  jsonFile="/root/avi.json"
  if [[ $(jq '[.nsx.config.segments_overlay[] | select(has("lbaas_public")).display_name] | length' ${jsonFile}) -eq 1 && \
        $(jq '[.nsx.config.segments_overlay[] | select(has("lbaas_private")).display_name] | length' ${jsonFile}) -eq 1 && \
        $(jq '[.avi.config.cloud.networks_data[] | select(has("lbaas_public")).display_name] | length' ${jsonFile}) -eq 1 && \
        $(jq '[.avi.config.cloud.networks_data[] | select(has("lbaas_private")).display_name] | length' ${jsonFile}) -eq 1 ]]; then
    echo "+++++++ self-service portal demo" | tee -a ${output_file} >/dev/null 2>&1
    echo "  https://${external_gw_ip}" | tee -a ${output_file} >/dev/null 2>&1
    echo "  username: admin" | tee -a ${output_file} >/dev/null 2>&1
    echo "  password: ${TF_VAR_ubuntu_password}" | tee -a ${output_file} >/dev/null 2>&1
  fi
fi
#
if [ -s "/root/$(basename $(jq -c -r .vault.secret_file_path /nestedVsphere8/02_external_gateway/variables.json))" ]; then
  #  echo "patching avi.json with vault token"
  avi_json=$(jq . /root/avi.json)
  avi_json=$(echo ${avi_json} | jq '.avi.config.certificatemanagementprofile[0].script_params[2] += {"value": "'$(jq -c -r .root_token /root/$(basename $(jq -c -r .vault.secret_file_path /nestedVsphere8/02_external_gateway/variables.json)))'"}')
  echo ${avi_json} | jq . | tee /root/avi.json > /dev/null
  echo "Vault details:" | tee -a ${output_file} >/dev/null 2>&1
  echo "Vault root token: $(jq -c -r .root_token /root/$(basename $(jq -c -r .vault.secret_file_path /nestedVsphere8/02_external_gateway/variables.json)))" | tee -a ${output_file} >/dev/null 2>&1
fi
#
if [ -z "${slack_webhook_url}" ] ; then echo "ignoring slack update" ; else curl -X POST -H 'Content-type: application/json' --data '{"text":"'$(date "+%Y-%m-%d,%H:%M:%S")', '${deployment}': 02_external_gateway created"}' ${slack_webhook_url} >/dev/null 2>&1; fi
#
scp -o StrictHostKeyChecking=no ubuntu@$(jq -c -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile):/home/ubuntu/.ssh/id_rsa /root/.ssh/id_rsa_external >/dev/null 2>&1
scp -o StrictHostKeyChecking=no ubuntu@$(jq -c -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile):/home/ubuntu/.ssh/id_rsa.pub /root/.ssh/id_rsa_external.pub >/dev/null 2>&1