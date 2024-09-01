#!/bin/bash
jsonFile="/root/nsx.json"
deployment=$(jq -c -r .deployment $jsonFile)
if [[ ${deployment} == "vsphere_nsx" || ${deployment} == "vsphere_nsx_alb" || ${deployment} == "vsphere_nsx_alb_telco" || ${deployment} == "vsphere_nsx_tanzu_alb" || ${deployment} == "vsphere_nsx_alb_vcd" ]]; then
  source /nestedVsphere8/bash/tf_init_apply.sh
  #
  tf_init_apply "Build of the nested NSXT Manager - This should take less than 30 minutes" /nestedVsphere8/05_nsx_manager /nestedVsphere8/log/05.stdout /nestedVsphere8/log/05.stderr $jsonFile
  #
  echo "waiting for 5 minutes to finish the NSX bootstrap..."
  sleep 300
  #
  touch "/root/05_nsx_manager"
  if [ -z "${slack_webhook_url}" ] ; then echo "ignoring slack update" ; else curl -X POST -H 'Content-type: application/json' --data '{"text":"'$(date "+%Y-%m-%d,%H:%M:%S")', '${deployment}': 05_nsx_manager deployed"}' ${slack_webhook_url} >/dev/null 2>&1; fi
fi