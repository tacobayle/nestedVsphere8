#!/bin/bash
jsonFile="/root/nsx.json"
output_file="/root/output.txt"
source /nestedVsphere8/bash/tf_init_apply.sh
#
tf_init_apply "Build of the config of NSX - This should take less than 60 minutes" /nestedVsphere8/06_nsx_config /nestedVsphere8/log/06.stdout /nestedVsphere8/log/06.stderr $jsonFile
#
# outputs NSX
#
echo "" | tee -a ${output_file} >/dev/null 2>&1
echo "++++++++++++++++++++ NSX" | tee -a ${output_file} >/dev/null 2>&1
echo "  > NSX manager url: https://$(jq -r .vsphere_underlay.networks.vsphere.management.nsx_nested_ip $jsonFile)" | tee -a ${output_file} >/dev/null 2>&1
echo "NSX admin password: ${TF_VAR_nsx_password}" | tee -a ${output_file} >/dev/null 2>&1
#
if [ -z "${slack_webhook_url}" ] ; then echo "ignoring slack update" ; else curl -X POST -H 'Content-type: application/json' --data '{"text":"'$(date "+%Y-%m-%d,%H:%M:%S")', '${deployment}': 06_nsx_config done"}' ${slack_webhook_url} >/dev/null 2>&1; fi