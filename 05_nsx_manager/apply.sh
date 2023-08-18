#!/bin/bash
jsonFile="/root/nsx.json"
source /nestedVsphere8/bash/tf_init_apply.sh
#
tf_init_apply "Build of the nested NSXT Manager - This should take less than 30 minutes" /nestedVsphere8/05_nsx_manager /nestedVsphere8/log/05.stdout /nestedVsphere8/log/05.stderr $jsonFile