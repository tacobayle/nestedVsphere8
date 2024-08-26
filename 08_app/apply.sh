#!/bin/bash
jsonFile="/root/app.json"
source /nestedVsphere8/bash/tf_init_apply.sh
#
tf_init_apply "Build of App VMs - This should take less than 20 minutes" /nestedVsphere8/08_app /nestedVsphere8/log/08.stdout /nestedVsphere8/log/08.stderr $jsonFile
#
if [ -z "${slack_webhook_url}" ] ; then echo "ignoring slack update" ; else curl -X POST -H 'Content-type: application/json' --data '{"text":"'$(date "+%Y-%m-%d,%H:%M:%S")', '${deployment}': 08_app deployed"}' ${slack_webhook_url} >/dev/null 2>&1; fi