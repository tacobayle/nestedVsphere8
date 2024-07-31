#!/bin/bash
jsonFile="/root/avi.json"
source /nestedVsphere8/bash/tf_init_apply.sh
#
tf_init_apply "Configuration of ALB controller - This should take less than 60 minutes" /nestedVsphere8/11_nsx_alb_config /nestedVsphere8/log/11.stdout /nestedVsphere8/log/11.stderr $jsonFile