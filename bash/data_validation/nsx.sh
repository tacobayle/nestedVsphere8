
test_nsx_k8s_variables () {
  echo ""
  echo "==> Checking unmanaged_k8s with NSX"
  # .nsx.config.segments_overlay[].k8s_clusters
  for item in $(jq -c -r .nsx.config.segments_overlay[] "$1")
  do
    if [[ $(echo $item | jq -c .k8s_clusters) != "null" ]] ; then
      placement_k8s=0
      for network in $(jq -c -r .avi.config.cloud.networks_data[] "$1")
      do
        if [[ $(echo $item | jq -r -c .display_name) == $(echo $network | jq -c -r .name) ]] ; then
          placement_k8s=1
        fi
      done
      if [[ $placement_k8s -ne 1 ]] ; then
        echo "With NSX: k8s_clusters is supported only on vip segments defined .avi.config.cloud.networks_data[]"
        exit 255
      fi
      variables_json=$(echo $variables_json | jq '. += {"unmanaged_k8s_status": true}')
      for cluster in $(echo $item | jq -c -r .k8s_clusters[])
      do
        test_if_variable_is_defined $(echo $cluster | jq -c .cluster_name) "   " "testing if each .nsx.config.segments_overlay.$(echo $item | jq -r -c .display_name).k8s_clusters[] have a cluster_name defined"
        test_if_variable_is_defined $(echo $cluster | jq -c .k8s_version) "   " "testing if each .nsx.config.segments_overlay.$(echo $item | jq -r -c .display_name).k8s_clusters[] have a k8s_version defined"
        test_if_variable_is_defined $(echo $cluster | jq -c .cni) "   " "testing if each .nsx.config.segments_overlay.$(echo $item | jq -r -c .display_name).k8s_clusters[] have a cni defined"
        if [[ $(echo $cluster | jq -c -r .cni) == "antrea" || $(echo $cluster | jq -c -r .cni) == "calico" || $(echo $cluster | jq -c -r .cni) == "cilium" ]] ; then
          echo "   +++ cni is $(echo $cluster | jq -c -r .cni) which is supported"
        else
          echo "   +++ cni $(echo $cluster | jq -c -r .cni) is not supported - cni should be either \"calico\" or \"antrea\" or \"cilium\""
          exit 255
        fi
        test_if_variable_is_defined $(echo $cluster | jq -c .cni_version) "   " "testing if each .nsx.config.segments_overlay.$(echo $item | jq -r -c .display_name).k8s_clusters[] have a cni_version defined"
        test_if_variable_is_defined $(echo $cluster | jq -c .cluster_ips) "   " ".nsx.config.segments_overlay.$(echo $item | jq -r -c .display_name).k8s_clusters[] have a cluster_ips defined"
        if [[ $(echo $cluster | jq -c -r '.cluster_ips | length') -lt 3 ]] ; then echo "   +++ Amount of cluster_ips should be higher than 3" ; exit 255 ; fi
        for ip in $(echo $cluster | jq -c -r .cluster_ips[])
        do
          test_if_variable_is_valid_ip "$ip" "   "
        done
      done
    fi
  done
}