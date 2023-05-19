#!/bin/bash
jsonFile="/root/app.json"
source /nestedVsphere8/bash/tf_init_apply.sh
#
tf_init_apply "Build of App VMs in NSX - This should take less than 20 minutes" /nestedVsphere8/08_app /nestedVsphere8/log/08.stdout /nestedVsphere8/log/08.stderr $jsonFile