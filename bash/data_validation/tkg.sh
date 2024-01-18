test_tkg () {
  echo ""
  echo "==> Checking TKG Variables"
  test_if_json_variable_is_defined .tkg "$1" "   "
  test_if_json_variable_is_defined .tkg.tanzu_bin_location "$1" "   "
  test_if_json_variable_is_defined .tkg.k8s_bin_location "$1" "   "
  test_if_json_variable_is_defined .tkg.ova_location "$1" "   "
  test_if_json_variable_is_defined .tkg.version "$1" "   "
  test_if_json_variable_is_defined .tkg.clusters "$1" "   "
  test_if_json_variable_is_defined .tkg.clusters.management "$1" "   "
  echo "   +++ Checking TKG clusters.management"
  test_if_json_variable_is_defined .tkg.clusters.management.name "$1" "   "
  test_if_json_variable_is_defined .tkg.clusters.management.avi_control_plane_network "$1" "   "
  test_if_json_variable_is_defined .tkg.clusters.management.avi_data_network "$1" "   "
  test_if_json_variable_is_defined .tkg.clusters.management.avi_mgmt_cluster_control_plane_vip_network_name "$1" "   "
  test_if_json_variable_is_defined .tkg.clusters.management.avi_mgmt_cluster_vip_network_name "$1" "   "
  test_if_json_variable_is_defined .tkg.clusters.management.avi_management_cluster_service_engine_group "$1" "   "
  test_if_json_variable_is_defined .tkg.clusters.management.avi_service_engine_group "$1" "   "
  test_if_json_variable_is_defined .tkg.clusters.management.cluster_cidr "$1" "   "
  test_if_json_variable_is_defined .tkg.clusters.management.service_cidr "$1" "   "
  test_if_json_variable_is_defined .tkg.clusters.management.vsphere_network "$1" "   "
  test_if_json_variable_is_defined .tkg.clusters.management.control_plane_disk "$1" "   "
  test_if_json_variable_is_defined .tkg.clusters.management.control_plane_memory "$1" "   "
  test_if_json_variable_is_defined .tkg.clusters.management.control_plane_cpu "$1" "   "
  test_if_json_variable_is_defined .tkg.clusters.management.worker_disk "$1" "   "
  test_if_json_variable_is_defined .tkg.clusters.management.worker_memory "$1" "   "
  test_if_json_variable_is_defined .tkg.clusters.management.worker_cpu "$1" "   "
  if $(jq -e '.tkg.clusters.management | has("cluster_ref")' "${1}") ; then
    if $(echo $variables_json | jq -e -c -r --arg arg "$(jq -c -r '.tkg.clusters.management.cluster_ref' "${1}")" '.vsphere_nested.cluster_list[] | select( . == $arg )'> /dev/null) ; then
      echo "   +++ .tkg.clusters.management.cluster_ref found"
    else
      echo "   +++ ERROR tkg.clusters.management.cluster_ref not found in .vsphere_nested.cluster_list[]"
      exit 255
    fi
  fi
  echo "   +++ Checking TKG clusters.workloads"
  for cluster in $(jq -c -r .tkg.clusters.workloads[] "$1")
  do
    test_if_variable_is_valid_cidr "$(echo $cluster | jq -c -r '.name')" "   "
    test_if_variable_is_valid_cidr "$(echo $cluster | jq -c -r '.cni')" "   "
    test_if_variable_is_valid_cidr "$(echo $cluster | jq -c -r '.antrea_node_port_local')" "   "
    test_if_variable_is_valid_cidr "$(echo $cluster | jq -c -r '.cluster_cidr')" "   "
    test_if_variable_is_valid_cidr "$(echo $cluster | jq -c -r '.avi_control_plane_ha_provider')" "   "
    test_if_variable_is_valid_cidr "$(echo $cluster | jq -c -r '.service_cidr')" "   "
    test_if_variable_is_valid_cidr "$(echo $cluster | jq -c -r '.vsphere_network')" "   "
    test_if_variable_is_valid_cidr "$(echo $cluster | jq -c -r '.worker_disk')" "   "
    test_if_variable_is_valid_cidr "$(echo $cluster | jq -c -r '.worker_memory')" "   "
    test_if_variable_is_valid_cidr "$(echo $cluster | jq -c -r '.worker_cpu')" "   "
    test_if_variable_is_valid_cidr "$(echo $cluster | jq -c -r '.worker_count')" "   "
    test_if_variable_is_valid_cidr "$(echo $cluster | jq -c -r '.control_plane_disk')" "   "
    test_if_variable_is_valid_cidr "$(echo $cluster | jq -c -r '.control_plane_memory')" "   "
    test_if_variable_is_valid_cidr "$(echo $cluster | jq -c -r '.control_plane_cpu')" "   "
    test_if_variable_is_valid_cidr "$(echo $cluster | jq -c -r '.control_plane_count')" "   "
    if $(echo $cluster | jq -e '. | has("cluster_ref")') ; then
      if $(echo $variables_json | jq -e -c -r --arg arg "$(echo $cluster | jq -c -r '.cluster_ref')" '.vsphere_nested.cluster_list[] | select( . == $arg )'> /dev/null) ; then
        echo "   +++ tkg.clusters.workloads[].cluster_ref found"
      else
        echo "   +++ ERROR tkg.clusters.workloads[].cluster_ref not found in .vsphere_nested.cluster_list[] - cluster called $(echo $cluster | jq -c -r '.name')"
        exit 255
      fi
    fi
  done
}