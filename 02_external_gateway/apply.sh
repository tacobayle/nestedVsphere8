#!/bin/bash
jsonFile="/root/external_gw.json"
source /nestedVsphere8/bash/tf_init_apply.sh
#
# Build of an external GW server on the underlay infrastructure
#
tf_init_apply "Build of an external GW server on the underlay infrastructure - This should take less than 10 minutes" /nestedVsphere8/02_external_gateway /nestedVsphere8/log/02.stdout /nestedVsphere8/log/02.stderr $jsonFile