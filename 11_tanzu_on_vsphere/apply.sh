#!/bin/bash
jsonFile="/root/tanzu_wo_nsx.json"
source /nestedVsphere8/bash/tf_init_apply.sh
#
tf_init_apply "Configuration of Vsphere with Tanzu - This should take less than 60 minutes" /nestedVsphere8/11_tanzu_on_vsphere /nestedVsphere8/log/11.stdout /nestedVsphere8/log/11.stderr $jsonFile