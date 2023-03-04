#!/bin/bash
jsonFile="/etc/config/variables.json"
source /nestedVsphere8/bash/tf_init_apply.sh
#
# Build of a folder on the underlay infrastructure
#
tf_init_apply "Build of a folder on the underlay infrastructure - This should take less than a minute" /nestedVsphere8/01_underlay_vsphere_directory /nestedVsphere8/log/01.stdout /nestedVsphere8/log/01.stderr $jsonFile
