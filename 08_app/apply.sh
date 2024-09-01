#!/bin/bash
jsonFile="/root/app.json"
deployment=$(jq -c -r .deployment $jsonFile)
if [[ ${deployment} == "vsphere_alb_wo_nsx" || ${deployment} == "vsphere_tanzu_alb_wo_nsx" || ${deployment} == "vsphere_nsx_alb" || ${deployment} == "vsphere_nsx_tanzu_alb" || ${deployment} == "vsphere_nsx_alb_vcd" ]]; then
  source /nestedVsphere8/bash/tf_init_apply.sh
  #
  tf_init_apply "Build of App VMs - This should take less than 20 minutes" /nestedVsphere8/08_app /nestedVsphere8/log/08.stdout /nestedVsphere8/log/08.stderr $jsonFile
  #
  touch "/root/08_app"
  if [ -z "${slack_webhook_url}" ] ; then echo "ignoring slack update" ; else curl -X POST -H 'Content-type: application/json' --data '{"text":"'$(date "+%Y-%m-%d,%H:%M:%S")', '${deployment}': 08_app deployed"}' ${slack_webhook_url} >/dev/null 2>&1; fi
fi