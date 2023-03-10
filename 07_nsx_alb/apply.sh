#!/bin/bash
jsonFile="/root/avi.json"
source /nestedVsphere8/bash/tf_init_apply.sh
#
tf_init_apply "Build of ALB controller - This should take less than 20 minutes" /nestedVsphere8/07_nsx_alb /nestedVsphere8/log/07.stdout /nestedVsphere8/log/07.stderr $jsonFile