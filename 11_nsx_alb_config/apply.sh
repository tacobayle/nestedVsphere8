#!/bin/bash
jsonFile="/root/avi.json"
output_file="/root/output.txt"
source /nestedVsphere8/bash/tf_init_apply.sh
#
tf_init_apply "Configuration of ALB controller - This should take less than 60 minutes" /nestedVsphere8/11_nsx_alb_config /nestedVsphere8/log/11.stdout /nestedVsphere8/log/11.stderr $jsonFile
#
deployment=$(jq -c -r .deployment $jsonFile)
if [[ ${deployment} == "vsphere_nsx_alb" || ${deployment} == "vsphere_nsx_tanzu_alb" ]]; then
  if [[ $(jq '[.nsx.config.segments_overlay[] | select(has("lbaas_public")).display_name] | length' ${jsonFile}) -eq 1 && \
        $(jq '[.nsx.config.segments_overlay[] | select(has("lbaas_private")).display_name] | length' ${jsonFile}) -eq 1 && \
        $(jq '[.avi.config.cloud.networks_data[] | select(has("lbaas_public")).display_name] | length' ${jsonFile}) -eq 1 && \
        $(jq '[.avi.config.cloud.networks_data[] | select(has("lbaas_private")).display_name] | length' ${jsonFile}) -eq 1 ]]; then
    ssh -o StrictHostKeyChecking=no -t ubuntu@external-gw "/bin/bash /home/ubuntu/lbaas/cleanup.sh"
  fi
fi
#
# output Avi
#
echo "" | tee -a ${output_file} >/dev/null 2>&1
echo "++++++++++++++++ NSX-ALB" | tee -a ${output_file} >/dev/null 2>&1
echo "  > NSX ALB controller url: https://$(jq -r .vsphere_underlay.networks.vsphere.management.avi_nested_ip $jsonFile)" | tee -a ${output_file} >/dev/null 2>&1
echo "Avi admin password: ${TF_VAR_avi_password}" | tee -a ${output_file} >/dev/null 2>&1
#
if [ -z "${slack_webhook_url}" ] ; then echo "ignoring slack update" ; else curl -X POST -H 'Content-type: application/json' --data '{"text":"'$(date "+%Y-%m-%d,%H:%M:%S")', '${deployment}': 11_nsx_alb_config done"}' ${slack_webhook_url} >/dev/null 2>&1; fi
