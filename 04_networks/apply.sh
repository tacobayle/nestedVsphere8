#!/bin/bash
jsonFile="/root/networks.json"
source /nestedVsphere8/bash/tf_init_apply.sh
#
tf_init_apply "Build of Nested Networks - This should take less than a minute" /nestedVsphere8/04_networks /nestedVsphere8/log/04.stdout /nestedVsphere8/log/04.stderr $jsonFile
#
if [ -z "${slack_webhook_url}" ] ; then echo "ignoring slack update" ; else curl -X POST -H 'Content-type: application/json' --data '{"text":"'$(date "+%Y-%m-%d,%H:%M:%S")', '${deployment}': 04_networks configured"}' ${slack_webhook_url} >/dev/null 2>&1; fi