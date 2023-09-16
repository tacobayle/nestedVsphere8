#!/bin/bash
jsonFile="/root/tkgm.json"
source /nestedVsphere8/bash/tf_init_apply.sh
#
tf_init_apply "Configuration TKGm - This should take around 90 minutes" /nestedVsphere8/12_tkgm /nestedVsphere8/log/12.stdout /nestedVsphere8/log/12.stderr $jsonFile