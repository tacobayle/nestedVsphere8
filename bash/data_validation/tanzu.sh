
test_variables_if_tanzu () {
  echo ""
  echo "==> Checking vSphere with Tanzu variables"
  #
  # tanzu .tanzu.supervisor_cluster validation
  #
  if $(jq -e '.tanzu | has("supervisor_cluster")' ${1}) ; then
    test_if_variable_is_defined $(jq -c -r '.tanzu.supervisor_cluster.size' ${1}) "   " "testing if each .tanzu.supervisor_cluster.size is defined"
    if [[ $(jq -c -r '.tanzu.supervisor_cluster.size' ${1} | tr '[:upper:]' [:lower:]) != "tiny" \
          && $(jq -c -r '.tanzu.supervisor_cluster.size' ${1} | tr '[:upper:]' [:lower:]) != "small" \
          && $(jq -c -r '.tanzu.supervisor_cluster.size' ${1} | tr '[:upper:]' [:lower:]) != "medium" \
          && $(jq -c -r '.tanzu.supervisor_cluster.size' ${1} | tr '[:upper:]' [:lower:]) != "large" ]] ; then
            echo "   +++ ERROR ..tanzu.supervisor_cluster.size should equal to one of the following: 'tiny, small, medium, large'"
            echo "   +++ https://developer.vmware.com/apis/vsphere-automation/latest/vcenter/data-structures/NamespaceManagement/SizingHint/"
            exit 255
    fi
    if $(jq -e '.tanzu.supervisor_cluster | has("cluster_ref")' ${1}) ; then
      if $(echo $variables_json | jq -e -c -r --arg arg "$(jq -c -r '.tanzu.supervisor_cluster.cluster_ref')" '.vsphere_nested.cluster_list[] | select( . == $arg )'> /dev/null) ; then
        echo "   +++ .tanzu.supervisor_cluster found"
      else
        echo "   +++ ERROR .tanzu.supervisor_cluster not found in .vsphere_nested.cluster_list[]"
        exit 255
      fi
    fi
    test_if_variable_is_valid_cidr "$(jq -c -r '.tanzu.supervisor_cluster.service_cidr' ${1})" "   "
    # use case nsx
    if [[ ${2} == "nsx" ]] ; then
      test_if_variable_is_defined $(jq -c -r '.tanzu.supervisor_cluster.management_tanzu_segment' ${1}) "   " "testing if .tanzu.supervisor_cluster.management_tanzu_segment is defined"
      if $(jq -e -c -r --arg segment "$(jq -c -r '.tanzu.supervisor_cluster.management_tanzu_segment' ${1})" '.nsx.config.segments_overlay[] | select( .display_name == $segment )' ${1} > /dev/null) ; then
        echo "   +++ .tanzu.supervisor_cluster.management_tanzu_segment ref found"
        test_if_variable_is_defined $(jq -c -r --arg segment "$(jq -c -r '.tanzu.supervisor_cluster.management_tanzu_segment' ${1})" '.nsx.config.segments_overlay[] | select( .display_name == $segment) | .tanzu_supervisor_starting_ip' ${1}) "   +++" "testing if $(jq -c -r '.tanzu.supervisor_cluster.management_tanzu_segment' ${1}) have tanzu_supervisor_starting_ip defined"
        test_if_variable_is_defined $(jq -c -r --arg segment "$(jq -c -r '.tanzu.supervisor_cluster.management_tanzu_segment' ${1})" '.nsx.config.segments_overlay[] | select( .display_name == $segment) | .tanzu_supervisor_count' ${1}) "   +++" "testing if $(jq -c -r '.tanzu.supervisor_cluster.management_tanzu_segment' ${1}) have tanzu_supervisor_count defined"
      else
        echo "   +++ ERROR .tanzu.supervisor_cluster.management_tanzu_segment ref not found in .nsx.config.segments_overlay[]"
        exit 255
      fi
      test_if_variable_is_defined $(jq -c -r '.tanzu.supervisor_cluster.namespace_edge_cluster' ${1}) "   " "testing if .tanzu.supervisor_cluster.namespace_edge_cluster is defined"
      if $(jq -e -c -r --arg edge_cluster "$(jq -c -r '.tanzu.supervisor_cluster.namespace_edge_cluster' ${1})" '.nsx.config.edge_clusters[] | select( .display_name == $edge_cluster )' ${1} > /dev/null) ; then
        echo "   +++ .tanzu.supervisor_cluster.namespace_edge_cluster ref found"
      else
        echo "   +++ ERROR .tanzu.supervisor_cluster.namespace_edge_cluster ref not found in .nsx.config.edge_clusters[]"
        exit 255
      fi
      test_if_variable_is_defined $(jq -c -r '.tanzu.supervisor_cluster.namespace_tier0' ${1}) "   " "testing if .tanzu.supervisor_cluster.namespace_tier0 is defined"
      if $(jq -e -c -r --arg tier0 "$(jq -c -r '.tanzu.supervisor_cluster.namespace_tier0' ${1})" '.nsx.config.tier0s[] | select( .display_name == $tier0 )' ${1} > /dev/null) ; then
        echo "   +++ .tanzu.supervisor_cluster.namespace_tier0 ref found"
      else
        echo "   +++ ERROR .tanzu.supervisor_cluster.namespace_tier0 ref not found in .nsx.config.tier0s[]"
        exit 255
      fi
      test_if_variable_is_valid_cidr "$(jq -c -r '.tanzu.supervisor_cluster.namespace_cidr' ${1})" "   "
      test_if_variable_is_defined $(jq -c -r '.tanzu.supervisor_cluster.prefix_per_namespace' ${1}) "   " "testing if .tanzu.supervisor_cluster.prefix_per_namespace is defined"
      test_if_variable_is_valid_cidr "$(jq -c -r '.tanzu.supervisor_cluster.ingress_cidr' ${1})" "   "
    fi
  fi
  #
  # tanzu .tanzu.namespaces validation
  #
  if $(jq -e '.tanzu | has("namespaces")' ${1}) ; then
    if $(jq -e '.tanzu.namespaces[].name' ${1} > /dev/null) ; then
      echo "   +++ .tanzu.namespaces[] has name defined"
    else
      echo "   +++ ERROR .tanzu.namespaces[] has not a name defined"
      exit 255
    fi
    #
    if [[ ${2} == "nsx" ]] ; then
      # tanzu overwrite supervisor cluster values use case nsx
      for ns in $(jq -c -r '.tanzu.namespaces[]' ${1})
      do
        if $(echo $ns | jq -e '.namespace_cidr' > /dev/null) || \
           $(echo $ns | jq -e '.namespace_tier0' > /dev/null) || \
           $(echo $ns | jq -e '.prefix_per_namespace' > /dev/null) || \
           $(echo $ns | jq -e '.ingress_cidr' > /dev/null) ; then
          if $(echo $ns | jq -e '.namespace_cidr' > /dev/null) && \
             $(echo $ns | jq -e '.namespace_tier0' > /dev/null) && \
             $(echo $ns | jq -e '.prefix_per_namespace' > /dev/null) && \
             $(echo $ns | jq -e '.ingress_cidr' > /dev/null) ; then
            if [[ $(echo $ns | jq -c -r '.namespace_cidr') != $(jq -c -r '.tanzu.supervisor_cluster.namespace_cidr' ${1}) && \
                  $(echo $ns | jq -c -r '.ingress_cidr') != $(jq -c -r '.tanzu.supervisor_cluster.ingress_cidr' ${1}) ]] ; then
              echo "   +++ .tanzu.namespaces called $(echo $ns | jq -c -r '.name') has different values for .namespace_cidr and .ingress_cidr than the supervisor clusters"
              test_if_variable_is_valid_cidr "$(echo $ns | jq -c -r '.namespace_cidr')" "   "
              test_if_variable_is_valid_cidr "$(echo $ns | jq -c -r '.ingress_cidr')" "   "
              if $(jq -e -c -r --arg tier0 "$(echo $ns | jq -c -r '.namespace_tier0')" '.nsx.config.tier0s[] | select( .display_name == $tier0 )' ${1} > /dev/null) ; then
                echo "   +++ .tanzu.namespaces called $(echo $ns | jq -c -r '.name').namespace_tier0 ref found"
              else
                echo "   +++ ERROR .tanzu.namespaces called $(echo $ns | jq -c -r '.name').namespace_tier0 ref not found in .nsx.config.tier0s[]"
                exit 255
              fi
            else
              echo "   +++ ERROR .tanzu.namespaces called $(echo $ns | jq -c -r '.name') has same values for .namespace_cidr or/and .ingress_cidr than the supervisor clusters"
            fi
          else
            echo "   +++ ERROR .tanzu.namespaces[] called $(echo $ns | jq -c -r '.name') should have .namespace_cidr, .namespace_tier0, .prefix_per_namespace, .ingress_cidr - all of them or none of them"
          fi
        fi
      done
    fi
  fi
  #
  # tanzu .tanzu.tkc_clusters validation
  #
  if $(jq -e '.tanzu | has("tkc_clusters")' ${1}) ; then
    # .tanzu.tkc_clusters[].name
    for tkc in $(jq -c -r '.tanzu.tkc_clusters[]' ${1})
    do
      test_if_variable_is_defined $(echo $tkc | jq -c .name) "   " "testing if each .tanzu.tkc_clusters[] have a name defined"
      test_if_list_of_value_is_unique "${jsonFile}" ".tanzu.tkc_clusters[].name"
      test_if_variable_is_defined $(echo $tkc | jq -c .namespace_ref) "   " "testing if each .tanzu.tkc_clusters[] have a namespace_ref defined"
      # check that the namespace_ref exists in .tanzu.namespaces[].name
      if $(jq -e -c -r --arg namespace "$(echo $tkc | jq -c -r '.namespace_ref')" '.tanzu.namespaces[] | select( .name == $namespace )' ${1} > /dev/null) ; then
        echo "   +++ .tanzu.tkc_clusters called $(echo $tkc | jq -c -r '.name').namespace_ref ref found"
      else
        echo "   +++ ERROR .tanzu.tkc_clusters called $(echo $tkc | jq -c -r '.name').namespace_ref ref not found in .tanzu.namespaces[].name"
        exit 255
      fi
      test_if_variable_is_defined $(echo $tkc | jq -c .k8s_version) "   " "testing if each .tanzu.tkc_clusters[] have a k8s_version defined"
      test_if_variable_is_defined $(echo $tkc | jq -c .control_plane_count) "   " "testing if each .tanzu.tkc_clusters[] have a control_plane_count defined"
      test_if_variable_is_defined $(echo $tkc | jq -c .vm_class) "   " "testing if each .tanzu.tkc_clusters[] have a vm_class defined"
      test_if_variable_is_defined $(echo $tkc | jq -c .workers_count) "   " "testing if each .tanzu.tkc_clusters[] have a workers_count defined"
      test_if_variable_is_defined $(echo $tkc | jq -c .services_cidrs) "   " "testing if each .tanzu.tkc_clusters[] have a services_cidrs defined"
      for cidr in $(echo $tkc | jq -c -r '.services_cidrs[]')
      do
        test_if_variable_is_valid_cidr "${cidr}" "   "
      done
      test_if_variable_is_defined $(echo $tkc | jq -c .pods_cidrs) "   " "testing if each .tanzu.tkc_clusters[] have a pods_cidrs defined"
      for cidr in $(echo $tkc | jq -c -r '.pods_cidrs[]')
      do
        test_if_variable_is_valid_cidr "${cidr}" "   "
      done
      # .tanzu.tkc_clusters[].alb_tenants
      if $(echo $tkc | jq -e '.alb_tenant_name' > /dev/null) || \
         $(echo $tkc | jq -e '.alb_tenant_type' > /dev/null) ; then
        if $(echo $tkc | jq -e '.alb_tenant_name' > /dev/null) && \
           $(echo $tkc | jq -e '.alb_tenant_type' > /dev/null) ; then
          if [[ $(echo $tkc | jq -c -r '.alb_tenant_type' | tr '[:upper:]' [:lower:]) != "tenant-mode" \
             && $(echo $tkc | jq -c -r '.alb_tenant_type' | tr '[:upper:]' [:lower:]) !=  "provider-mode" ]] ; then
            echo "   +++ ERROR .tanzu.tkc_clusters[] called $(echo $tkc | jq -c -r '.name') should have .alb_tenant_type configures with either 'tenant-mode' or 'provider-mode' - it is $(echo $tkc | jq -c -r '.alb_tenant_type')"
            exit 255
          fi
          if [[ $(echo $tkc | jq -c -r '.alb_tenant_name' | tr '[:upper:]' [:lower:]) == "admin" ]] ; then
            echo "   +++ ERROR .tanzu.tkc_clusters[] called $(echo $tkc | jq -c -r '.name') should not have .alb_tenant_name configures 'admin'"
            exit 255
          fi
        else
          echo "   +++ ERROR .tanzu.tkc_clusters[] called $(echo $tkc | jq -c -r '.name') should have .alb_tenant_name, .alb_tenant_type - all of them or none of them"
        fi
      fi
    done
  fi
}