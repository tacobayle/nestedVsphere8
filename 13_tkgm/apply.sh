#!/bin/bash
jsonFile="/root/tkgm.json"
source /nestedVsphere8/bash/tf_init_apply.sh
#
tf_init_apply "Configuration TKGm - This should take around 120 minutes" /nestedVsphere8/13_tkgm /nestedVsphere8/log/13.stdout /nestedVsphere8/log/13.stderr $jsonFile