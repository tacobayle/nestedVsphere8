#!/bin/bash
#
jsonFile="/root/variables.json"
localJsonFile="/nestedVsphere8/09_unmanaged_k8s_clusters/variables.json"
#
IFS=$'\n'
#
echo ""
echo "==> Creating /root/unmanaged_k8s_clusters.json file..."
rm -f /root/unmanaged_k8s_clusters.json
unmanaged_k8s_clusters_json=$(jq -c -r . $jsonFile | jq .)
#
if [[ $(jq -c -r .unmanaged_k8s_status $jsonFile) == true ]]; then
  unmanaged_k8s_clusters_masters_ips=[]
  unmanaged_k8s_clusters_segments=[]
  unmanaged_k8s_clusters_cidr=[]
  if [[ $(jq -c -r .vsphere_underlay.networks.alb.backend.k8s_clusters $jsonFile) != "null" ]] ; then
    for cluster in $(jq -c -r .vsphere_underlay.networks.alb.backend.k8s_clusters[] $jsonFile)
    do
      unmanaged_k8s_clusters_masters_ips=$(echo $unmanaged_k8s_clusters_masters_ips | jq '. += ["'$(echo $cluster | jq -c -r .cluster_ips[0])'"]')
      unmanaged_k8s_clusters_segments=$(echo $unmanaged_k8s_clusters_segments | jq '. += ["'$(jq -c -r .networks.alb.backend.port_group_name /nestedVsphere8/02_external_gateway/variables.json)'"]')
      unmanaged_k8s_clusters_cidr=$(echo $unmanaged_k8s_clusters_cidr | jq '. += ["'$(jq -c -r .vsphere_underlay.networks.alb.backend.cidr $jsonFile)'"]')
    done
  fi
fi