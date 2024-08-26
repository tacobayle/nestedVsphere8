#!/bin/bash
jsonFile="/root/avi.json"
source /nestedVsphere8/bash/tf_init_apply.sh
#
tf_init_apply "Build of ALB controller - This should take less than 20 minutes" /nestedVsphere8/07_nsx_alb /nestedVsphere8/log/07.stdout /nestedVsphere8/log/07.stderr $jsonFile
#
if [ -z "${slack_webhook_url}" ] ; then echo "ignoring slack update" ; else curl -X POST -H 'Content-type: application/json' --data '{"text":"'$(date "+%Y-%m-%d,%H:%M:%S")', '${deployment}': 07_nsx_alb deployed"}' ${slack_webhook_url} >/dev/null 2>&1; fi
