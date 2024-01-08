#!/bin/bash
jsonFile="/root/avi.json"
source /nestedVsphere8/bash/tf_init_apply.sh
#
curl https://raw.githubusercontent.com/vmware/alb-sdk/eng/python/avi/sdk/samples/clone_vs.py -o /tmp/clone_vs.py -s
tf_init_apply "Configuration of ALB controller - This should take less than 60 minutes" /nestedVsphere8/10_nsx_alb_config /nestedVsphere8/log/10.stdout /nestedVsphere8/log/10.stderr $jsonFile