#!/bin/bash
#
jsonFile="/root/variables.json"
localJsonFile="/nestedVsphere8/10_unmanaged_k8s_clusters/variables.json"
#
rm -f /root/unmanaged_k8s_clusters.json
unmanaged_k8s_clusters_json=$(jq -c -r . $jsonFile | jq .)
#
if [[ $(jq -c -r .unmanaged_k8s_status $jsonFile) == true ]]; then
  IFS=$'\n'
  #
  echo ""
  echo "==> Creating /root/unmanaged_k8s_clusters.json file..."
  #
  echo "   +++ Adding k8s..."
  k8s=$(jq -c -r '.k8s' $localJsonFile)
  unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '. += {"k8s": '$(echo $k8s)'}')
  #
  echo "   +++ Adding ubuntu_ova..."
  ubuntu_ova=$(basename $(jq -c -r '.ubuntu_ova_path' /nestedVsphere8/02_external_gateway/variables.json) .ova)
  unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '. += {"ubuntu_ova": "'$(echo $ubuntu_ova)'"}')
  #
  echo "   +++ Adding ubuntu_cl..."
  ubuntu_cl=$(jq -c -r '.ubuntu_cl' /nestedVsphere8/02_external_gateway/variables.json)
  unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '. += {"ubuntu_cl": "'$(echo $ubuntu_cl)'"}')
  #
  #echo "   +++ Adding ako_url..."
  #ako_url=$(jq -c -r '.ako_url' /nestedVsphere8/07_nsx_alb/variables.json)
  #unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '. += {"ako_url": "'$(echo $ako_url)'"}')
  #
  unmanaged_k8s_clusters_nodes=[]
  unmanaged_k8s_masters_ips=[]
  unmanaged_k8s_masters_vsphere_cluster=[]
  unmanaged_k8s_masters_vsphere_datastore=[]
  unmanaged_k8s_masters_segments=[]
  unmanaged_k8s_masters_cidr=[]
  unmanaged_k8s_masters_gw=[]
  unmanaged_k8s_masters_cluster_name=[]
  unmanaged_k8s_masters_version=[]
  unmanaged_k8s_masters_cni=[]
  unmanaged_k8s_masters_cni_version=[]
  unmanaged_k8s_masters_ako_disableStaticRouteSync=[]
  unmanaged_k8s_masters_ako_serviceType=[]
  unmanaged_k8s_masters_vip_networks=[]
  #
  unmanaged_k8s_workers_count=[]
  unmanaged_k8s_workers_associated_master_ips=[]
  unmanaged_k8s_workers_ips=[]
  unmanaged_k8s_workers_vsphere_cluster=[]
  unmanaged_k8s_workers_vsphere_datastore=[]
  unmanaged_k8s_workers_segments=[]
  unmanaged_k8s_workers_cidr=[]
  unmanaged_k8s_workers_gw=[]
  unmanaged_k8s_workers_cluster_name=[]
  unmanaged_k8s_workers_version=[]
  unmanaged_k8s_workers_cni=[]
  unmanaged_k8s_workers_cni_version=[]
  #
  # vSphere use cases
  #
  if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_alb_wo_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_tanzu_alb_wo_nsx" ]]; then
    networks='["backend", "vip", "tanzu"]'
    for network in $(echo $networks | jq -c -r .[])
    do
      if [[ $(jq -c -r .vsphere_underlay.networks.alb.$network.k8s_clusters $jsonFile) != "null" ]] ; then
        for cluster in $(jq -c -r .vsphere_underlay.networks.alb.$network.k8s_clusters[] $jsonFile)
        do
          unmanaged_k8s_clusters_nodes=$(echo $unmanaged_k8s_clusters_nodes | jq '. += ["'$(echo $cluster | jq -c -r '.cluster_ips | length')'"]')
          unmanaged_k8s_masters_ips=$(echo $unmanaged_k8s_masters_ips | jq '. += ["'$(echo $cluster | jq -c -r .cluster_ips[0])'"]')
          unmanaged_k8s_masters_cluster_name=$(echo $unmanaged_k8s_masters_cluster_name | jq '. += ["'$(echo $cluster | jq -c -r .cluster_name)'"]')
          unmanaged_k8s_masters_segments=$(echo $unmanaged_k8s_masters_segments | jq '. += ["'$(jq -c -r .networks.alb.$network.port_group_name /nestedVsphere8/02_external_gateway/variables.json)'"]')
          unmanaged_k8s_masters_cidr=$(echo $unmanaged_k8s_masters_cidr | jq '. += ["'$(jq -c -r .vsphere_underlay.networks.alb.$network.cidr $jsonFile)'"]')
          unmanaged_k8s_masters_gw=$(echo $unmanaged_k8s_masters_gw | jq '. += ["'$(jq -c -r .vsphere_underlay.networks.alb.$network.external_gw_ip $jsonFile)'"]')
          unmanaged_k8s_masters_version=$(echo $unmanaged_k8s_masters_version | jq '. += ["'$(echo $cluster | jq -c -r .k8s_version)'"]')
          if $(echo $cluster | jq -e '. | has("cluster_ref")') ; then
            echo "   +++ Unmanaged K8s Cluster called $(echo $cluster | jq -c -r .cluster_name) / master node will be installed on the top of vSphere cluster $(echo $cluster | jq -c -r  '.cluster_ref')"
            unmanaged_k8s_masters_vsphere_cluster=$(echo $unmanaged_k8s_masters_vsphere_cluster | jq '. += ["'$(echo $cluster | jq -c -r .cluster_ref)'"]')
            vsan_datastore_index=$(jq -c -r --arg arg "$(echo $cluster | jq -c -r '.cluster_ref')" '.vsphere_nested.cluster_list | map( . == $arg ) | index(true)' $jsonFile)
            unmanaged_k8s_masters_vsphere_datastore=$(echo $unmanaged_k8s_masters_vsphere_datastore | jq '. += ["'$(jq -c -r '.vsphere_nested.datastore_list['${vsan_datastore_index}']' $jsonFile)'"]')
          else
            echo "   +++ Unmanaged K8s Cluster called $(echo $cluster | jq -c -r .cluster_name) / master node will be installed on the top of vSphere cluster $(jq -c -r '.vsphere_nested.cluster_list[0]' $jsonFile)"
            unmanaged_k8s_masters_vsphere_cluster=$(echo $unmanaged_k8s_masters_vsphere_cluster | jq '. += ["'$(jq -c -r '.vsphere_nested.cluster_list[0]' $jsonFile)'"]')
            unmanaged_k8s_masters_vsphere_datastore=$(echo $unmanaged_k8s_masters_vsphere_datastore | jq '. += ["vsanDatastore"]')
          fi
          unmanaged_k8s_masters_cni=$(echo $unmanaged_k8s_masters_cni | jq '. += ["'$(echo $cluster | jq -c -r .cni)'"]')
          unmanaged_k8s_masters_cni_version=$(echo $unmanaged_k8s_masters_cni_version | jq '. += ["'$(echo $cluster | jq -c -r .cni_version)'"]')
          if [[ $(echo $cluster | jq -c -r .cni) == "antrea" ]] ; then
            unmanaged_k8s_masters_ako_disableStaticRouteSync=$(echo $unmanaged_k8s_masters_ako_disableStaticRouteSync | jq '. += [true]')
            unmanaged_k8s_masters_ako_serviceType=$(echo $unmanaged_k8s_masters_ako_serviceType | jq '. += ["NodePortLocal"]')
          fi
          if [[ $(echo $cluster | jq -c -r .cni) == "calico" || $(echo $cluster | jq -c -r .cni) == "cilium" ]] ; then
            unmanaged_k8s_masters_ako_disableStaticRouteSync=$(echo $unmanaged_k8s_masters_ako_disableStaticRouteSync | jq '. += [false]')
            unmanaged_k8s_masters_ako_serviceType=$(echo $unmanaged_k8s_masters_ako_serviceType | jq '. += ["ClusterIP"]')
          fi
          unmanaged_k8s_masters_vip_networks=$(echo $unmanaged_k8s_masters_vip_networks | jq '. += ["'$(jq -c -r .networks.alb.vip.port_group_name /nestedVsphere8/02_external_gateway/variables.json)'"]')
          count=0
          for ip in $(echo $cluster | jq -c -r '.cluster_ips[1:][]')
          do
            ((count++))
            unmanaged_k8s_workers_count=$(echo $unmanaged_k8s_workers_count | jq '. += ["'$(echo $count)'"]')
            unmanaged_k8s_workers_associated_master_ips=$(echo $unmanaged_k8s_workers_associated_master_ips | jq '. += ["'$(echo $cluster | jq -c -r .cluster_ips[0])'"]')
            unmanaged_k8s_workers_ips=$(echo $unmanaged_k8s_workers_ips  | jq '. += ["'$(echo $ip)'"]')
            unmanaged_k8s_workers_segments=$(echo $unmanaged_k8s_workers_segments | jq '. += ["'$(jq -c -r .networks.alb.$network.port_group_name /nestedVsphere8/02_external_gateway/variables.json)'"]')
            unmanaged_k8s_workers_cidr=$(echo $unmanaged_k8s_workers_cidr | jq '. += ["'$(jq -c -r .vsphere_underlay.networks.alb.$network.cidr $jsonFile)'"]')
            unmanaged_k8s_workers_gw=$(echo $unmanaged_k8s_workers_gw | jq '. += ["'$(jq -c -r .vsphere_underlay.networks.alb.$network.external_gw_ip $jsonFile)'"]')
            unmanaged_k8s_workers_cluster_name=$(echo $unmanaged_k8s_workers_cluster_name | jq '. += ["'$(echo $cluster | jq -c -r .cluster_name)'"]')
            unmanaged_k8s_workers_version=$(echo $unmanaged_k8s_workers_version | jq '. += ["'$(echo $cluster | jq -c -r .k8s_version)'"]')
            if $(echo $cluster | jq -e '. | has("cluster_ref")') ; then
              echo "   +++ Unmanaged K8s Cluster called $(echo $cluster | jq -c -r .cluster_name) / worker ${count} node will be installed on the top of vSphere cluster $(echo $cluster | jq -c -r  '.cluster_ref')"
              vsan_datastore_index=$(jq -c -r --arg arg "$(echo $cluster | jq -c -r '.cluster_ref')" '.vsphere_nested.cluster_list | map( . == $arg ) | index(true)' $jsonFile)
              unmanaged_k8s_workers_vsphere_datastore=$(echo $unmanaged_k8s_workers_vsphere_datastore | jq '. += ["'$(jq -c -r '.vsphere_nested.datastore_list['${vsan_datastore_index}']' $jsonFile)'"]')
              unmanaged_k8s_workers_vsphere_cluster=$(echo $unmanaged_k8s_workers_vsphere_cluster | jq '. += ["'$(echo $cluster | jq -c -r .cluster_ref)'"]')
            else
              echo "   +++ Unmanaged K8s Cluster called $(echo $cluster | jq -c -r .cluster_name) / worker ${count} will be installed on the top of vSphere cluster $(jq -c -r '.vsphere_nested.cluster_list[0]' $jsonFile)"
              unmanaged_k8s_workers_vsphere_cluster=$(echo $unmanaged_k8s_workers_vsphere_cluster | jq '. += ["'$(jq -c -r '.vsphere_nested.cluster_list[0]' $jsonFile)'"]')
              unmanaged_k8s_workers_vsphere_datastore=$(echo $unmanaged_k8s_workers_vsphere_datastore | jq '. += ["vsanDatastore"]')
            fi
            unmanaged_k8s_workers_cni=$(echo $unmanaged_k8s_workers_cni | jq '. += ["'$(echo $cluster | jq -c -r .cni)'"]')
            unmanaged_k8s_workers_cni_version=$(echo $unmanaged_k8s_workers_cni_version | jq '. += ["'$(echo $cluster | jq -c -r .cni_version)'"]')
          done
        done
      fi
    done
    echo "   +++ Adding avi.config.cloud.name..."
    unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '.avi.config.cloud += {"name": "'$(jq -c -r '.vcenter_default_cloud_name' /nestedVsphere8/07_nsx_alb/variables.json)'"}')
  fi
  #
  # NSX use cases
  #
  if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_tanzu_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_vcd" ]]; then
    for item in $(jq -c -r .nsx.config.segments_overlay[] $jsonFile)
    do
      if [[ $(echo $item | jq -c -r .k8s_clusters) != "null" ]] ; then
        for cluster in $(echo $item | jq -c -r .k8s_clusters[])
        do
          unmanaged_k8s_clusters_nodes=$(echo $unmanaged_k8s_clusters_nodes | jq '. += ["'$(echo $cluster | jq -c -r '.cluster_ips | length')'"]')
          unmanaged_k8s_masters_ips=$(echo $unmanaged_k8s_masters_ips | jq '. += ["'$(echo $cluster | jq -c -r .cluster_ips[0])'"]')
          unmanaged_k8s_masters_cluster_name=$(echo $unmanaged_k8s_masters_cluster_name | jq '. += ["'$(echo $cluster | jq -c -r .cluster_name)'"]')
          unmanaged_k8s_masters_segments=$(echo $unmanaged_k8s_masters_segments | jq '. += ["'$(echo $item | jq -c -r .display_name)'"]')
          unmanaged_k8s_masters_cidr=$(echo $unmanaged_k8s_masters_cidr | jq '. += ["'$(echo $item | jq -c -r .cidr)'"]')
          unmanaged_k8s_masters_gw=$(echo $unmanaged_k8s_masters_gw | jq '. += ["'$(echo $item | jq -c -r .cidr | cut -d"/" -f1 | sed 's/[0-9]\+$/1/')'"]')
          unmanaged_k8s_masters_version=$(echo $unmanaged_k8s_masters_version | jq '. += ["'$(echo $cluster | jq -c -r .k8s_version)'"]')
          if $(echo $cluster | jq -e '. | has("cluster_ref")') ; then
            echo "   +++ Unmanaged K8s Cluster called $(echo $cluster | jq -c -r .cluster_name) / master node will be installed on the top of vSphere cluster $(echo $cluster | jq -c -r  '.cluster_ref')"
            unmanaged_k8s_masters_vsphere_cluster=$(echo $unmanaged_k8s_masters_vsphere_cluster | jq '. += ["'$(echo $cluster | jq -c -r .cluster_ref)'"]')
            vsan_datastore_index=$(jq -c -r --arg arg "$(echo $cluster | jq -c -r '.cluster_ref')" '.vsphere_nested.cluster_list | map( . == $arg ) | index(true)' $jsonFile)
            unmanaged_k8s_masters_vsphere_datastore=$(echo $unmanaged_k8s_masters_vsphere_datastore | jq '. += ["'$(jq -c -r '.vsphere_nested.datastore_list['${vsan_datastore_index}']' $jsonFile)'"]')
          else
            echo "   +++ Unmanaged K8s Cluster called $(echo $cluster | jq -c -r .cluster_name) / master node will be installed on the top of vSphere cluster $(jq -c -r '.vsphere_nested.cluster_list[0]' $jsonFile)"
            unmanaged_k8s_masters_vsphere_cluster=$(echo $unmanaged_k8s_masters_vsphere_cluster | jq '. += ["'$(jq -c -r '.vsphere_nested.cluster_list[0]' $jsonFile)'"]')
            unmanaged_k8s_masters_vsphere_datastore=$(echo $unmanaged_k8s_masters_vsphere_datastore | jq '. += ["vsanDatastore"]')
          fi
          unmanaged_k8s_masters_cni=$(echo $unmanaged_k8s_masters_cni | jq '. += ["'$(echo $cluster | jq -c -r .cni)'"]')
          unmanaged_k8s_masters_cni_version=$(echo $unmanaged_k8s_masters_cni_version | jq '. += ["'$(echo $cluster | jq -c -r .cni_version)'"]')
          if [[ $(echo $cluster | jq -c -r .cni) == "antrea" ]] ; then
            unmanaged_k8s_masters_ako_disableStaticRouteSync=$(echo $unmanaged_k8s_masters_ako_disableStaticRouteSync | jq '. += [true]')
            unmanaged_k8s_masters_ako_serviceType=$(echo $unmanaged_k8s_masters_ako_serviceType | jq '. += ["NodePortLocal"]')
          fi
          if [[ $(echo $cluster | jq -c -r .cni) == "calico" || $(echo $cluster | jq -c -r .cni) == "cilium" ]] ; then
            unmanaged_k8s_masters_ako_disableStaticRouteSync=$(echo $unmanaged_k8s_masters_ako_disableStaticRouteSync | jq '. += [false]')
            unmanaged_k8s_masters_ako_serviceType=$(echo $unmanaged_k8s_masters_ako_serviceType | jq '. += ["ClusterIP"]')
          fi
          unmanaged_k8s_masters_vip_networks=$(echo $unmanaged_k8s_masters_vip_networks | jq '. += ["'$(jq -c -r .avi.config.cloud.networks_data[0].name $jsonFile)'"]')
          count=0
          for ip in $(echo $cluster | jq -c -r '.cluster_ips[1:][]')
          do
            ((count++))
            unmanaged_k8s_workers_count=$(echo $unmanaged_k8s_workers_count | jq '. += ["'$(echo $count)'"]')
            unmanaged_k8s_workers_associated_master_ips=$(echo $unmanaged_k8s_workers_associated_master_ips | jq '. += ["'$(echo $cluster | jq -c -r .cluster_ips[0])'"]')
            unmanaged_k8s_workers_ips=$(echo $unmanaged_k8s_workers_ips  | jq '. += ["'$(echo $ip)'"]')
            unmanaged_k8s_workers_segments=$(echo $unmanaged_k8s_workers_segments | jq '. += ["'$(echo $item | jq -c -r .display_name)'"]')
            unmanaged_k8s_workers_cidr=$(echo $unmanaged_k8s_workers_cidr | jq '. += ["'$(echo $item | jq -c -r .cidr)'"]')
            unmanaged_k8s_workers_gw=$(echo $unmanaged_k8s_workers_gw | jq '. += ["'$(echo $item | jq -c -r .cidr | cut -d"/" -f1 | sed 's/[0-9]\+$/1/')'"]')
            unmanaged_k8s_workers_cluster_name=$(echo $unmanaged_k8s_workers_cluster_name | jq '. += ["'$(echo $cluster | jq -c -r .cluster_name)'"]')
            unmanaged_k8s_workers_version=$(echo $unmanaged_k8s_workers_version | jq '. += ["'$(echo $cluster | jq -c -r .k8s_version)'"]')
            if $(echo $cluster | jq -e '. | has("cluster_ref")') ; then
              echo "   +++ Unmanaged K8s Cluster called $(echo $cluster | jq -c -r .cluster_name) / worker ${count} will be installed on the top of vSphere cluster $(echo $cluster | jq -c -r  '.cluster_ref')"
              unmanaged_k8s_workers_vsphere_cluster=$(echo $unmanaged_k8s_workers_vsphere_cluster | jq '. += ["'$(echo $cluster | jq -c -r .cluster_ref)'"]')
              vsan_datastore_index=$(jq -c -r --arg arg "$(echo $cluster | jq -c -r '.cluster_ref')" '.vsphere_nested.cluster_list | map( . == $arg ) | index(true)' $jsonFile)
              unmanaged_k8s_workers_vsphere_datastore=$(echo $unmanaged_k8s_workers_vsphere_datastore | jq '. += ["'$(jq -c -r '.vsphere_nested.datastore_list['${vsan_datastore_index}']' $jsonFile)'"]')
            else
              echo "   +++ Unmanaged K8s Cluster called $(echo $cluster | jq -c -r .cluster_name) / worker ${count} will be installed on the top of vSphere cluster $(jq -c -r '.vsphere_nested.cluster_list[0]' $jsonFile)"
              unmanaged_k8s_workers_vsphere_cluster=$(echo $unmanaged_k8s_workers_vsphere_cluster | jq '. += ["'$(jq -c -r '.vsphere_nested.cluster_list[0]' $jsonFile)'"]')
              unmanaged_k8s_workers_vsphere_datastore=$(echo $unmanaged_k8s_workers_vsphere_datastore | jq '. += ["vsanDatastore"]')
            fi
            unmanaged_k8s_workers_cni=$(echo $unmanaged_k8s_workers_cni | jq '. += ["'$(echo $cluster | jq -c -r .cni)'"]')
            unmanaged_k8s_workers_cni_version=$(echo $unmanaged_k8s_workers_cni_version | jq '. += ["'$(echo $cluster | jq -c -r .cni_version)'"]')
          done
        done
      fi
    done
    echo "   +++ Adding avi.config.cloud.name..."
    unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '.avi.config.cloud += {"name": "'$(jq -c -r '.nsx_default_cloud_name' /nestedVsphere8/07_nsx_alb/variables.json)'"}')
  fi
  #
  #
  #
  echo "   +++ Adding unmanaged_k8s.clusters_nodes..."
  unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '.unmanaged_k8s += {"clusters_nodes": '$(echo $unmanaged_k8s_clusters_nodes)'}')
  echo "   +++ Adding unmanaged_k8s.masters_ips..."
  unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '.unmanaged_k8s += {"masters_ips": '$(echo $unmanaged_k8s_masters_ips)'}')
  echo "   +++ Adding unmanaged_k8s.masters_cluster_name..."
  unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '.unmanaged_k8s += {"masters_cluster_name": '$(echo $unmanaged_k8s_masters_cluster_name)'}')
  echo "   +++ Adding unmanaged_k8s.masters_segments..."
  unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '.unmanaged_k8s += {"masters_segments": '$(echo $unmanaged_k8s_masters_segments)'}')
  echo "   +++ Adding unmanaged_k8s.masters_cidr..."
  unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '.unmanaged_k8s += {"masters_cidr": '$(echo $unmanaged_k8s_masters_cidr)'}')
  echo "   +++ Adding unmanaged_k8s.masters_gw..."
  unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '.unmanaged_k8s += {"masters_gw": '$(echo $unmanaged_k8s_masters_gw)'}')
  echo "   +++ Adding unmanaged_k8s.masters_vsphere_cluster..."
  unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '.unmanaged_k8s += {"masters_vsphere_cluster": '$(echo $unmanaged_k8s_masters_vsphere_cluster)'}')
  echo "   +++ Adding unmanaged_k8s.masters_vsphere_datastore..."
  unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '.unmanaged_k8s += {"masters_vsphere_datastore": '$(echo $unmanaged_k8s_masters_vsphere_datastore)'}')
  echo "   +++ Adding unmanaged_k8s.masters_version..."
  unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '.unmanaged_k8s += {"masters_version": '$(echo $unmanaged_k8s_masters_version)'}')
  echo "   +++ Adding unmanaged_k8s.masters_cni..."
  unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '.unmanaged_k8s += {"masters_cni": '$(echo $unmanaged_k8s_masters_cni)'}')
  echo "   +++ Adding unmanaged_k8s.masters_cni_version..."
  unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '.unmanaged_k8s += {"masters_cni_version": '$(echo $unmanaged_k8s_masters_cni_version)'}')
  echo "   +++ Adding unmanaged_k8s.masters_ako_disableStaticRouteSync..."
  unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '.unmanaged_k8s += {"masters_ako_disableStaticRouteSync": '$(echo $unmanaged_k8s_masters_ako_disableStaticRouteSync)'}')
  echo "   +++ Adding unmanaged_k8s.masters_ako_serviceType..."
  unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '.unmanaged_k8s += {"masters_ako_serviceType": '$(echo $unmanaged_k8s_masters_ako_serviceType)'}')
  echo "   +++ Adding unmanaged_k8s.masters_vip_networks..."
  unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '.unmanaged_k8s += {"masters_vip_networks": '$(echo $unmanaged_k8s_masters_vip_networks)'}')
  #
  echo "   +++ Adding unmanaged_k8s.workers_count..."
  unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '.unmanaged_k8s += {"workers_count": '$(echo $unmanaged_k8s_workers_count)'}')
  echo "   +++ Adding unmanaged_k8s.workers_associated_master_ips..."
  unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '.unmanaged_k8s += {"workers_associated_master_ips": '$(echo $unmanaged_k8s_workers_associated_master_ips)'}')
  echo "   +++ Adding unmanaged_k8s.workers_ips..."
  unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '.unmanaged_k8s += {"workers_ips": '$(echo $unmanaged_k8s_workers_ips)'}')
  echo "   +++ Adding unmanaged_k8s.workers_segments..."
  unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '.unmanaged_k8s += {"workers_segments": '$(echo $unmanaged_k8s_workers_segments)'}')
  echo "   +++ Adding unmanaged_k8s.workers_cidr..."
  unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '.unmanaged_k8s += {"workers_cidr": '$(echo $unmanaged_k8s_workers_cidr)'}')
  echo "   +++ Adding unmanaged_k8s.workers_gw..."
  unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '.unmanaged_k8s += {"workers_gw": '$(echo $unmanaged_k8s_workers_gw)'}')
  echo "   +++ Adding unmanaged_k8s.workers_cluster_name..."
  unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '.unmanaged_k8s += {"workers_cluster_name": '$(echo $unmanaged_k8s_workers_cluster_name)'}')
  echo "   +++ Adding unmanaged_k8s.workers_vsphere_cluster..."
  unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '.unmanaged_k8s += {"workers_vsphere_cluster": '$(echo $unmanaged_k8s_workers_vsphere_cluster)'}')
  echo "   +++ Adding unmanaged_k8s.workers_vsphere_datastore..."
  unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '.unmanaged_k8s += {"workers_vsphere_datastore": '$(echo $unmanaged_k8s_workers_vsphere_datastore)'}')
  echo "   +++ Adding unmanaged_k8s.workers_version..."
  unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '.unmanaged_k8s += {"workers_version": '$(echo $unmanaged_k8s_workers_version)'}')
  echo "   +++ Adding unmanaged_k8s.masters_version..."
  unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '.unmanaged_k8s += {"masters_version": '$(echo $unmanaged_k8s_masters_version)'}')
  echo "   +++ Adding unmanaged_k8s.workers_cni..."
  unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '.unmanaged_k8s += {"workers_cni": '$(echo $unmanaged_k8s_workers_cni)'}')
  echo "   +++ Adding unmanaged_k8s.workers_cni_version..."
  unmanaged_k8s_clusters_json=$(echo $unmanaged_k8s_clusters_json | jq '.unmanaged_k8s += {"workers_cni_version": '$(echo $unmanaged_k8s_workers_cni_version)'}')
  #
  #
  #
fi
echo $unmanaged_k8s_clusters_json | jq . | tee /root/unmanaged_k8s_clusters.json > /dev/null