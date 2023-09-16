#!/bin/bash
#
jsonFile="/root/tkgm.json"
#
cluster_count=1
for cluster in $(jq -c -r .tkg.clusters.workloads[] $jsonFile)
do
  ssh -o StrictHostKeyChecking=no -t ubuntu@$(jq -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile) 'tanzu cluster delete '$(echo $cluster | jq -c - r .name)''
  /bin/bash /root/govc_workload${cluster_count}_destroy.sh
  ((cluster_count++))
done
