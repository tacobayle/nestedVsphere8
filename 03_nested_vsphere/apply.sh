#!/bin/bash
jsonFile="/root/nested_vsphere.json"
source /nestedVsphere8/bash/tf_init_apply.sh
#
# Build of a folder on the underlay infrastructure
#
tf_init_apply "Build of the nested ESXi/vCenter infrastructure - This should take less than 45 minutes" /nestedVsphere8/03_nested_vsphere /nestedVsphere8/log/03.stdout /nestedVsphere8/log/03.stderr $jsonFile