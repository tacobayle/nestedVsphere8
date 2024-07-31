#!/bin/bash
jsonFile="/root/unmanaged_k8s_clusters.json"
source /nestedVsphere8/bash/tf_init_apply.sh
#
tf_init_apply "Build of unmanaged K8s cluster(s) - This should take less than 20 minutes" /nestedVsphere8/10_unmanaged_k8s_clusters /nestedVsphere8/log/11.stdout /nestedVsphere8/log/11.stderr $jsonFile