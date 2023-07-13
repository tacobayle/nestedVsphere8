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
#
unmanaged_k8s_masters_ips=[]
unmanaged_k8s_masters_segments=[]
unmanaged_k8s_masters_cidr=[]
unmanaged_k8s_masters_cluster_name=[]
unmanaged_k8s_workers_associated_master_ips=[]
unmanaged_k8s_workers_ips=[]
unmanaged_k8s_workers_segments=[]
unmanaged_k8s_workers_cidr=[]
unmanaged_k8s_workers_cluster_name=[]
#
if [[ $(jq -c -r .vsphere_underlay.networks.alb.backend.k8s_clusters $jsonFile) != "null" ]] ; then
  for cluster in $(jq -c -r .vsphere_underlay.networks.alb.backend.k8s_clusters[] $jsonFile)
  do
    unmanaged_k8s_masters_ips=$(echo $unmanaged_k8s_masters_ips | jq '. += ["'$(echo $cluster | jq -c -r .cluster_ips[0])'"]')
    unmanaged_k8s_masters_cluster_name=$(echo $unmanaged_k8s_masters_cluster_name | jq '. += ["'$(echo $cluster | jq -c -r .cluster_name'"]'))
    unmanaged_k8s_masters_segments=$(echo $unmanaged_k8s_masters_segments | jq '. += ["'$(jq -c -r .networks.alb.backend.port_group_name /nestedVsphere8/02_external_gateway/variables.json)'"]')
    unmanaged_k8s_masters_cidr=$(echo $unmanaged_k8s_masters_cidr | jq '. += ["'$(jq -c -r .vsphere_underlay.networks.alb.backend.cidr $jsonFile)'"]')
    for ip in $(echo $cluster | jq -c -r '.cluster_ips[1:]')
    do
      unmanaged_k8s_workers_associated_master_ips=$(echo $unmanaged_k8s_workers_associated_master_ips | jq '. += ["'$(echo $cluster | jq -c -r .cluster_ips[0])'"]')
      unmanaged_k8s_workers_ips=$(echo $unmanaged_k8s_workers_ips  | jq '. += ["'$(echo $ip)'"]')
      unmanaged_k8s_workers_segments=$(echo $unmanaged_k8s_masters_segments | jq '. += ["'$(jq -c -r .networks.alb.backend.port_group_name /nestedVsphere8/02_external_gateway/variables.json)'"]')
      unmanaged_k8s_workers_cidr=$(echo $unmanaged_k8s_masters_cidr | jq '. += ["'$(jq -c -r .vsphere_underlay.networks.alb.backend.cidr $jsonFile)'"]')
      unmanaged_k8s_workers_cluster_name=$(echo $unmanaged_k8s_workers_cluster_name | jq '. += ["'$(echo $cluster | jq -c -r .cluster_name'"]'))
    done
  done
fi
#
if [[ $(jq -c -r .vsphere_underlay.networks.alb.vip.k8s_clusters $jsonFile) != "null" ]] ; then
  for cluster in $(jq -c -r .vsphere_underlay.networks.alb.vip.k8s_clusters[] $jsonFile)
  do
    unmanaged_k8s_masters_ips=$(echo $unmanaged_k8s_masters_ips | jq '. += ["'$(echo $cluster | jq -c -r .cluster_ips[0])'"]')
    unmanaged_k8s_masters_cluster_name=$(echo $unmanaged_k8s_masters_cluster_name | jq '. += ["'$(echo $cluster | jq -c -r .cluster_name'"]'))
    unmanaged_k8s_masters_segments=$(echo $unmanaged_k8s_masters_segments | jq '. += ["'$(jq -c -r .networks.alb.vip.port_group_name /nestedVsphere8/02_external_gateway/variables.json)'"]')
    unmanaged_k8s_masters_cidr=$(echo $unmanaged_k8s_masters_cidr | jq '. += ["'$(jq -c -r .vsphere_underlay.networks.alb.vip.cidr $jsonFile)'"]')
    for ip in $(echo $cluster | jq -c -r '.cluster_ips[1:]')
    do
      unmanaged_k8s_workers_associated_master_ips=$(echo $unmanaged_k8s_workers_associated_master_ips | jq '. += ["'$(echo $cluster | jq -c -r .cluster_ips[0])'"]')
      unmanaged_k8s_workers_ips=$(echo $unmanaged_k8s_workers_ips  | jq '. += ["'$(echo $ip)'"]')
      unmanaged_k8s_workers_segments=$(echo $unmanaged_k8s_masters_segments | jq '. += ["'$(jq -c -r .networks.alb.vip.port_group_name /nestedVsphere8/02_external_gateway/variables.json)'"]')
      unmanaged_k8s_workers_cidr=$(echo $unmanaged_k8s_masters_cidr | jq '. += ["'$(jq -c -r .vsphere_underlay.networks.alb.vip.cidr $jsonFile)'"]')
      unmanaged_k8s_workers_cluster_name=$(echo $unmanaged_k8s_workers_cluster_name | jq '. += ["'$(echo $cluster | jq -c -r .cluster_name'"]'))
    done
  done
fi
#
if [[ $(jq -c -r .vsphere_underlay.networks.alb.tanzu.k8s_clusters $jsonFile) != "null" ]] ; then
  for cluster in $(jq -c -r .vsphere_underlay.networks.alb.tanzu.k8s_clusters[] $jsonFile)
  do
    unmanaged_k8s_masters_ips=$(echo $unmanaged_k8s_masters_ips | jq '. += ["'$(echo $cluster | jq -c -r .cluster_ips[0])'"]')
    unmanaged_k8s_masters_cluster_name=$(echo $unmanaged_k8s_masters_cluster_name | jq '. += ["'$(echo $cluster | jq -c -r .cluster_name'"]'))
    unmanaged_k8s_masters_segments=$(echo $unmanaged_k8s_masters_segments | jq '. += ["'$(jq -c -r .networks.alb.tanzu.port_group_name /nestedVsphere8/02_external_gateway/variables.json)'"]')
    unmanaged_k8s_masters_cidr=$(echo $unmanaged_k8s_masters_cidr | jq '. += ["'$(jq -c -r .vsphere_underlay.networks.alb.tanzu.cidr $jsonFile)'"]')
    for ip in $(echo $cluster | jq -c -r '.cluster_ips[1:]')
    do
      unmanaged_k8s_workers_associated_master_ips=$(echo $unmanaged_k8s_workers_associated_master_ips | jq '. += ["'$(echo $cluster | jq -c -r .cluster_ips[0])'"]')
      unmanaged_k8s_workers_ips=$(echo $unmanaged_k8s_workers_ips  | jq '. += ["'$(echo $ip)'"]')
      unmanaged_k8s_workers_segments=$(echo $unmanaged_k8s_masters_segments | jq '. += ["'$(jq -c -r .networks.alb.tanzu.port_group_name /nestedVsphere8/02_external_gateway/variables.json)'"]')
      unmanaged_k8s_workers_cidr=$(echo $unmanaged_k8s_masters_cidr | jq '. += ["'$(jq -c -r .vsphere_underlay.networks.alb.tanzu.cidr $jsonFile)'"]')
      unmanaged_k8s_workers_cluster_name=$(echo $unmanaged_k8s_workers_cluster_name | jq '. += ["'$(echo $cluster | jq -c -r .cluster_name'"]'))
    done
  done
fi
#
#
#
echo "   +++ Adding unmanaged_k8s_masters_ips..."
unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '. += {"unmanaged_k8s_masters_ips": '$(echo $unmanaged_k8s_masters_ips)'}')
echo "   +++ Adding unmanaged_k8s_masters_cluster_name..."
unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '. += {"unmanaged_k8s_masters_cluster_name": '$(echo $unmanaged_k8s_masters_cluster_name)'}')
echo "   +++ Adding unmanaged_k8s_masters_segments..."
unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '. += {"unmanaged_k8s_masters_segments": '$(echo $unmanaged_k8s_masters_segments)'}')
echo "   +++ Adding unmanaged_k8s_masters_cidr..."
unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '. += {"unmanaged_k8s_masters_ips": '$(echo $unmanaged_k8s_masters_ips)'}')
echo "   +++ Adding unmanaged_k8s_workers_associated_master_ips..."
unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '. += {"unmanaged_k8s_workers_associated_master_ips": '$(echo $unmanaged_k8s_workers_associated_master_ips)'}')
echo "   +++ Adding unmanaged_k8s_workers_ips..."
unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '. += {"unmanaged_k8s_workers_ips": '$(echo $unmanaged_k8s_workers_ips)'}')
echo "   +++ Adding unmanaged_k8s_workers_segments..."
unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '. += {"unmanaged_k8s_workers_segments": '$(echo $unmanaged_k8s_workers_segments)'}')
echo "   +++ Adding unmanaged_k8s_workers_cidr..."
unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '. += {"unmanaged_k8s_workers_cidr": '$(echo $unmanaged_k8s_workers_cidr)'}')
echo "   +++ Adding unmanaged_k8s_workers_cluster_name..."
unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '. += {"unmanaged_k8s_workers_cluster_name": '$(echo $unmanaged_k8s_workers_cluster_name)'}')
echo $unmanaged_k8s_clusters_json | jq . | tee /root/unmanaged_k8s_clusters.json > /dev/null
