#!/bin/bash
jsonFile="/root/nsx.json"
source /nestedVsphere8/bash/tf_init_apply.sh
#
tf_init_apply "Build of the config of NSX - This should take less than 60 minutes" /nestedVsphere8/06_nsx_config /nestedVsphere8/log/06.stdout /nestedVsphere8/log/06.stderr $jsonFile