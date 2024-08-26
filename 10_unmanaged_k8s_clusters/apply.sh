#!/bin/bash
jsonFile="/root/unmanaged_k8s_clusters.json"
output_file="/root/output.txt"
source /nestedVsphere8/bash/tf_init_apply.sh
#
tf_init_apply "Build of unmanaged K8s cluster(s) - This should take less than 20 minutes" /nestedVsphere8/10_unmanaged_k8s_clusters /nestedVsphere8/log/11.stdout /nestedVsphere8/log/11.stderr $jsonFile
#
# Output unmanaged K8s clusters
#
echo "" | tee -a ${output_file} >/dev/null 2>&1
echo "+++++++++++++ Deploy AKO" | tee -a ${output_file} >/dev/null 2>&1
echo "  > helm install --generate-name $(jq -c -r .helm_url /nestedVsphere8/07_nsx_alb/variables.json) --version ako_version -f path_values.yml --namespace=avi-system" | tee -a ${output_file} >/dev/null 2>&1
#
if [ -z "${slack_webhook_url}" ] ; then echo "ignoring slack update" ; else curl -X POST -H 'Content-type: application/json' --data '{"text":"'$(date "+%Y-%m-%d,%H:%M:%S")', '${deployment}': 10_unmanaged_k8s_clusters deployed"}' ${slack_webhook_url} >/dev/null 2>&1; fi
