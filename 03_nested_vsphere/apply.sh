#!/bin/bash
jsonFile="/root/nested_vsphere.json"
output_file="/root/output.txt"
source /nestedVsphere8/bash/tf_init_apply.sh
#
# Build of a folder on the underlay infrastructure
#
tf_init_apply "Build of the nested ESXi/vCenter infrastructure - This should take less than 45 minutes" /nestedVsphere8/03_nested_vsphere /nestedVsphere8/log/03.stdout /nestedVsphere8/log/03.stderr $jsonFile
#
# outputs 03_nested_vsphere
#
echo "" | tee -a ${output_file} >/dev/null 2>&1
echo "++++++++++++++++ vSphere" | tee -a ${output_file} >/dev/null 2>&1
echo "Configure your /etc/hosts with the following entry:" | tee -a ${output_file} >/dev/null 2>&1
echo "  > $(jq -r .vsphere_underlay.networks.vsphere.management.vcsa_nested_ip $jsonFile) $(jq -r .vsphere_nested.vcsa_name $jsonFile).$(jq -r .external_gw.bind.domain $jsonFile)" | tee -a ${output_file} >/dev/null 2>&1
echo "vSphere server url: https://$(jq -r .vsphere_nested.vcsa_name $jsonFile).$(jq -r .external_gw.bind.domain $jsonFile)" | tee -a ${output_file} >/dev/null 2>&1
echo "ESXi root password: ${TF_VAR_nested_esxi_root_password}" | tee -a ${output_file} >/dev/null 2>&1
echo "vSphere username: administrator@$(jq -c -r .vsphere_nested.sso.domain_name $jsonFile)" | tee -a ${output_file} >/dev/null 2>&1
echo "vSphere password: ${TF_VAR_vsphere_nested_password}" | tee -a ${output_file} >/dev/null 2>&1
#
echo "waiting for 20 minutes to finish the vCenter config..."
sleep 1200
#
touch "/root/03_nested_vsphere"
if [ -z "${slack_webhook_url}" ] ; then echo "ignoring slack update" ; else curl -X POST -H 'Content-type: application/json' --data '{"text":"'$(date "+%Y-%m-%d,%H:%M:%S")', '${deployment}': 03_nested_vsphere created"}' ${slack_webhook_url} >/dev/null 2>&1; fi
