#!/bin/bash
jsonFile="/root/vcd.json"
source /nestedVsphere8/bash/tf_init_apply.sh
#
tf_init_apply "Build of VCD appliance - This should take less than 20 minutes" /nestedVsphere8/11_vcd_appliance /nestedVsphere8/log/10.stdout /nestedVsphere8/log/10.stderr $jsonFile