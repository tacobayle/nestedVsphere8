#!/bin/bash
jsonFile="/root/k8s.json"
source /nestedVsphere8/bash/tf_init_apply.sh
#
tf_init_apply "Build of unmanaged K8s cluster(s) - This should take less than 30 minutes" /nestedVsphere8/09_unmanaged_k8s_clusters /nestedVsphere8/log/09.stdout /nestedVsphere8/log/09.stderr $jsonFile