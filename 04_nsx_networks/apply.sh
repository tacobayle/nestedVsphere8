#!/bin/bash
jsonFile="/root/nsx1.json"
source /nestedVsphere8/bash/tf_init_apply.sh
#
tf_init_apply "Build of NSX Nested Networks - This should take less than a minute" /nestedVsphere8/04_nsx_networks /nestedVsphere8/log/04.stdout /nestedVsphere8/log/04.stderr $jsonFile