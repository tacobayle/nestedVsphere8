#!/bin/bash
jsonFile="/root/vsphere_with_tanzu.json"
source /nestedVsphere8/bash/tf_init_apply.sh
source /nestedVsphere8/bash/vcenter_api.sh
source /nestedVsphere8/bash/ip.sh
source /nestedVsphere8/bash/nsx/nsx_api.sh
#
IFS=$'\n'
#
vcsa_fqdn="$(jq -r .vsphere_nested.vcsa_name $jsonFile).$(jq -r .external_gw.bind.domain $jsonFile)"
vcsa_sso_domain=$(jq -r .vsphere_nested.sso.domain_name $jsonFile)
external_gw_ip=$(jq -c -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile)
avi_controller_ip=$(jq -c -r .vsphere_underlay.networks.vsphere.management.avi_nested_ip $jsonFile)
avi_cloud_name=$(jq -c -r .avi.config.cloud.name $jsonFile)
avi_version=$(jq -c -r .avi.version $jsonFile)
#
# registering Avi in the NSX config
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_tanzu_alb" ]]; then
  /bin/bash /nestedVsphere8/bash/nsx/registering_avi_controller.sh \
    "$(jq -r .vsphere_underlay.networks.vsphere.management.nsx_nested_ip $jsonFile)" \
    "${TF_VAR_nsx_password}" \
    "${TF_VAR_avi_password}" \
    "${avi_controller_ip}"
fi
#
#
#
if $(jq -e '.tanzu | has("supervisor_cluster")' $jsonFile) ; then
  #
  # Create Content Library for tanzu
  #
  create_subscribed_content_library_json_output="/root/tanzu_content_library.json"
  /bin/bash /nestedVsphere8/bash/vcenter/create_subscribed_content_library.sh \
    "${vcsa_fqdn}" \
    "${vcsa_sso_domain}" \
    "${TF_VAR_vsphere_nested_password}" \
    "$(jq -c -r .tanzu_local.content_library.subscription_url $jsonFile)" \
    "$(jq -c -r .tanzu_local.content_library.type $jsonFile)" \
    "$(jq -c -r .tanzu_local.content_library.automatic_sync_enabled $jsonFile)" \
    "$(jq -c -r .tanzu_local.content_library.on_demand $jsonFile)" \
    "$(jq -c -r .tanzu_local.content_library.name $jsonFile)" \
    "$(jq -c -r .tanzu.supervisor_cluster.datastore_ref $jsonFile)" \
    "${create_subscribed_content_library_json_output}"
  content_library_id=$(jq -c -r .content_library_id ${create_subscribed_content_library_json_output})
  #
  # Retrieve cluster id
  #
  retrieve_cluster_id_json_output="/root/vcenter_cluster_id.json"
  /bin/bash /nestedVsphere8/bash/vcenter/retrieve_cluster_id.sh \
    "${vcsa_fqdn}" \
    "${vcsa_sso_domain}" \
    "${TF_VAR_vsphere_nested_password}" \
    "$(jq -c -r .tanzu.supervisor_cluster.cluster_ref $jsonFile)" \
    "${retrieve_cluster_id_json_output}"
  cluster_id=$(jq -c -r .cluster_id ${retrieve_cluster_id_json_output})
  #
  # Retrieve storage policy
  #
  retrieve_storage_policy_id_json_output="/root/retrieve_storage_policy_id.json"
  /bin/bash /nestedVsphere8/bash/vcenter/retrieve_storage_policy_id.sh "${vcsa_fqdn}" "${vcsa_sso_domain}" "${TF_VAR_vsphere_nested_password}" \
    "$(jq -c -r .tanzu_local.storage_policy_name $jsonFile)" \
    "${retrieve_storage_policy_id_json_output}"
  storage_policy_id=$(jq -c -r .storage_policy_id ${retrieve_storage_policy_id_json_output})
  #
  # Retrieve Network details of tanzu_supervisor_dvportgroup dvportgroup
  #
  if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_tanzu_alb_wo_nsx" ]]; then
    supervisor_network="$(jq -c -r .networks.alb.tanzu.port_group_name $jsonFile)"
  fi
  #
  if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_tanzu_alb" ]]; then
    supervisor_network="$(jq -c -r .tanzu.supervisor_cluster.management_tanzu_segment $jsonFile)"
  fi
  #
  retrieve_network_id_json_output="/root/retrieve_network_id.json"
  /bin/bash /nestedVsphere8/bash/vcenter/retrieve_network_id.sh \
    "${vcsa_fqdn}" \
    "${vcsa_sso_domain}" \
    "${TF_VAR_vsphere_nested_password}" \
    "${supervisor_network}" \
    "${retrieve_network_id_json_output}"
  tanzu_supervisor_dvportgroup=$(jq -c -r .network_id ${retrieve_network_id_json_output})
  #
  # Retrieve Network details of tanzu_worker_dvportgroup dvportgroup
  #
  if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_tanzu_alb_wo_nsx" ]]; then
    retrieve_network_id_json_output="/root/retrieve_network_id.json"
    /bin/bash /nestedVsphere8/bash/vcenter/retrieve_network_id.sh \
      "${vcsa_fqdn}" \
      "${vcsa_sso_domain}" \
      "${TF_VAR_vsphere_nested_password}" \
      "$(jq -c -r .networks.alb.backend.port_group_name $jsonFile)" \
      "${retrieve_network_id_json_output}"
    tanzu_worker_dvportgroup=$(jq -c -r .network_id ${retrieve_network_id_json_output})
  fi
  #
  # Retrieve Avi Details
  #
  if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_tanzu_alb_wo_nsx" ]]; then
    echo "   +++ getting NSX ALB certificate..."
    openssl s_client -showcerts -connect $(jq -r .vsphere_underlay.networks.vsphere.management.avi_nested_ip $jsonFile):443  </dev/null 2>/dev/null|sed -ne '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' > /tmp/temp_avi-ca.cert
    if [ ! -s /tmp/temp_avi-ca.cert ] ; then exit 255 ; fi
    avi_cert=$(jq -sR . /tmp/temp_avi-ca.cert)
  fi
  #
  # vsphere_tanzu_alb_wo_nsx use case
  #
  if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_tanzu_alb_wo_nsx"  ]]; then
    /bin/bash /nestedVsphere8/bash/vcenter/create_supervisor_cluster_vds.sh "${vcsa_fqdn}" "${vcsa_sso_domain}" "${TF_VAR_vsphere_nested_password}" \
      "${external_gw_ip}" \
      "${storage_policy_id}" \
      "$(jq -r .tanzu.supervisor_cluster.service_cidr $jsonFile | cut -d"/" -f1)" \
      "$(jq -r .tanzu.supervisor_cluster.service_cidr $jsonFile | cut -d"/" -f2)" \
      "$(jq -r .tanzu.supervisor_cluster.size $jsonFile)" \
      "$(ip_netmask_by_prefix $(jq -c -r '.vsphere_underlay.networks.alb.tanzu.cidr' $jsonFile | cut -d"/" -f2) "   ++++++")" \
      "$(jq -r .vsphere_underlay.networks.alb.tanzu.tanzu_supervisor_starting_ip $jsonFile)" \
      "$(jq -r .vsphere_underlay.networks.alb.tanzu.external_gw_ip $jsonFile)" \
      "$(jq -r .vsphere_underlay.networks.alb.tanzu.tanzu_supervisor_count $jsonFile)" \
      "${tanzu_supervisor_dvportgroup}" \
      "${avi_cert}" \
      "${TF_VAR_avi_password}" \
      "$(jq -r .vsphere_underlay.networks.vsphere.management.avi_nested_ip $jsonFile)" \
      "${content_library_id}" \
      "$(jq -r .networks.alb.backend.port_group_name $jsonFile)" \
      "$(jq -r .vsphere_underlay.networks.alb.backend.tanzu_workers_starting_ip $jsonFile)" \
      "$(jq -r .vsphere_underlay.networks.alb.backend.tanzu_workers_count $jsonFile)" \
      "$(jq -r .vsphere_underlay.networks.alb.backend.external_gw_ip $jsonFile)" \
      "${tanzu_worker_dvportgroup}" \
      "$(ip_netmask_by_prefix $(jq -c -r '.vsphere_underlay.networks.alb.backend.cidr' $jsonFile | cut -d"/" -f2) "   ++++++")" \
      "${cluster_id}"
  fi
  #
  # vsphere_tanzu_alb_nsx use case
  #
  if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_tanzu_alb"  ]]; then
    #
    # retrieve edge cluster id
    #
    retrieve_network_id_json_output="/root/retrieve_namespace_edge_cluster_id.json"
    /bin/bash /nestedVsphere8/bash/nsx/get_edge_cluster.sh \
             "$(jq -r .vsphere_underlay.networks.vsphere.management.nsx_nested_ip $jsonFile)" \
             "${TF_VAR_nsx_password}" \
             "$(jq -r .tanzu.supervisor_cluster.namespace_edge_cluster $jsonFile)" \
             "${retrieve_network_id_json_output}"
    namespace_edge_cluster_id=$(jq -c -r .namespace_edge_cluster_id ${retrieve_network_id_json_output})
    #
    # create supervisor cluster
    #
    management_tanzu_segment=$(jq -r .tanzu.supervisor_cluster.management_tanzu_segment $jsonFile)
    management_tanzu_cidr=$(jq -c -r --arg segment ${management_tanzu_segment} '.nsx.config.segments_overlay[] | select(.display_name == $segment) | .cidr' $jsonFile)
    /bin/bash /nestedVsphere8/bash/vcenter/create_supervisor_cluster_nsx.sh "${vcsa_fqdn}" "${vcsa_sso_domain}" "${TF_VAR_vsphere_nested_password}" \
              "${content_library_id}" \
              "${storage_policy_id}" \
              "${external_gw_ip}" \
              "$(jq -r .tanzu.supervisor_cluster.size $jsonFile)" \
              "$(jq -r .tanzu.supervisor_cluster.service_cidr $jsonFile | cut -d"/" -f1)" \
              "$(jq -r .tanzu.supervisor_cluster.service_cidr $jsonFile | cut -d"/" -f2)" \
              "$(ip_netmask_by_prefix $(echo ${management_tanzu_cidr} | cut -d"/" -f2) "   ++++++")" \
              "$(jq -c -r --arg segment ${management_tanzu_segment} '.nsx.config.segments_overlay[] | select(.display_name == $segment) | .tanzu_supervisor_starting_ip' $jsonFile)" \
              "$(nextip $(echo ${management_tanzu_cidr} | cut -d"/" -f1 ))" \
              "$(jq -c -r --arg segment ${management_tanzu_segment} '.nsx.config.segments_overlay[] | select(.display_name == $segment) | .tanzu_supervisor_count' $jsonFile)" \
              "${tanzu_supervisor_dvportgroup}" \
              "$(jq -c -r .vds_network_nsx_overlay_id /root/vds_network_nsx_overlay_id.json)" \
              "$(jq -r .tanzu.supervisor_cluster.namespace_cidr $jsonFile | cut -d"/" -f1)" \
              "$(jq -r .tanzu.supervisor_cluster.namespace_cidr $jsonFile | cut -d"/" -f2)" \
              "$(jq -r .tanzu.supervisor_cluster.namespace_tier0 $jsonFile)" \
              "${namespace_edge_cluster_id}" \
              "$(jq -r .tanzu.supervisor_cluster.prefix_per_namespace $jsonFile)" \
              "$(jq -r .tanzu.supervisor_cluster.ingress_cidr $jsonFile | cut -d"/" -f1)" \
              "$(jq -r .tanzu.supervisor_cluster.ingress_cidr $jsonFile | cut -d"/" -f2)" \
              "${cluster_id}"
  fi
  #
  # Wait for supervisor cluster to be running
  #
  /bin/bash /nestedVsphere8/bash/vcenter/wait_for_supervisor_cluster.sh "${vcsa_fqdn}" "${vcsa_sso_domain}" "${TF_VAR_vsphere_nested_password}"
  #
  echo "waiting 5 minutes after supervisor cluster creation..."
  sleep 300
  #
  if $(jq -e '.tanzu | has("namespaces")' $jsonFile) ; then
    #
    # Namespace creation
    #
    for ns in $(jq -c -r .tanzu.namespaces[] $jsonFile); do
      # if nsx network values are overwritten
      if $(echo $ns | jq -e '.ingress_cidr' > /dev/null) ; then # 00_pre_check/00.sh checks that the other keys are present and valid.
        /bin/bash /nestedVsphere8/bash/vcenter/create_namespaces_nsx_overwrite_network.sh "${vcsa_fqdn}" "${vcsa_sso_domain}" "${TF_VAR_vsphere_nested_password}" \
                  "$(jq -r .tanzu_local.vm_classes $jsonFile)" \
                  "${storage_policy_id}" \
                  "$(echo $ns | jq -c -r .name)" \
                  "$(echo $ns | jq -c -r .ingress_cidr | cut -d"/" -f1)" \
                  "$(echo $ns | jq -c -r .ingress_cidr | cut -d"/" -f2)" \
                  "$(echo $ns | jq -c -r .namespace_cidr | cut -d"/" -f1)" \
                  "$(echo $ns | jq -c -r .namespace_cidr | cut -d"/" -f2)" \
                  "$(echo $ns | jq -c -r .namespace_tier0)" \
                  "$(echo $ns | jq -c -r .prefix_per_namespace)"
      else
      # if nsx network values are not overwritten, this also covers vsphere_nsx_tanzu_alb
        /bin/bash /nestedVsphere8/bash/vcenter/create_namespaces.sh "${vcsa_fqdn}" "${vcsa_sso_domain}" "${TF_VAR_vsphere_nested_password}" \
                  "$(jq -r .tanzu_local.vm_classes $jsonFile)" \
                  "${storage_policy_id}" \
                  "$(echo $ns | jq -c -r .name)"
      fi
    done
    #
    # retrieve K8s Supervisor node IP
    #
    retrieve_api_server_cluster_endpoint_json_output="/root/retrieve_api_server_cluster_endpoint.json"
    /bin/bash /nestedVsphere8/bash/vcenter/retrieve_api_server_cluster_endpoint.sh "${vcsa_fqdn}" "${vcsa_sso_domain}" "${TF_VAR_vsphere_nested_password}" \
              "${retrieve_api_server_cluster_endpoint_json_output}"
    api_server_cluster_endpoint=$(jq -c -r .api_server_cluster_endpoint ${retrieve_api_server_cluster_endpoint_json_output})
    #
    # TKC creation
    #
    # templating vsphere plugin install
    sed -e "s/\${api_server_cluster_endpoint}/${api_server_cluster_endpoint}/" /nestedVsphere8/12_vsphere_with_tanzu/templates/vsphere_plugin_install.sh.template | tee /root/vsphere_plugin_install.sh > /dev/null
    # transfer vsphere plugin install
    scp -o StrictHostKeyChecking=no /root/vsphere_plugin_install.sh ubuntu@${external_gw_ip}:/home/ubuntu/tanzu/vsphere_plugin_install.sh
    # exec vsphere plugin install
    ssh -o StrictHostKeyChecking=no -t ubuntu@${external_gw_ip} "/bin/bash /home/ubuntu/tanzu/vsphere_plugin_install.sh"
    # templating tanzu auth supervisor script
    sed -e "s/\${kubectl_password}/${TF_VAR_vsphere_nested_password}/" \
        -e "s/\${sso_domain_name}/${vcsa_sso_domain}/" \
        -e "s/\${api_server_cluster_endpoint}/${api_server_cluster_endpoint}/" /nestedVsphere8/12_vsphere_with_tanzu/templates/tanzu_auth_supervisor.sh.template | tee /root/tanzu_auth_supervisor.sh > /dev/null
    # transfer tanzu auth supervisor script
    scp -o StrictHostKeyChecking=no /root/tanzu_auth_supervisor.sh ubuntu@${external_gw_ip}:/home/ubuntu/tanzu/auth_supervisor.sh
    #
    #
    cluster_count=1
    remote_path="/home/ubuntu/tkc/create-tkc"
    remote_path_destroy="/home/ubuntu/tkc/destroy-tkc"
    remote_path_antrea_create="/home/ubuntu/tkc/create-antrea"
    remote_path_clusterbootstrap_create="/home/ubuntu/tkc/create-clusterbootstrap"
    remote_path_auth="/home/ubuntu/tkc/auth-tkc"
    for tkc in $(jq -c -r .tanzu.tkc_clusters[] $jsonFile); do
      # variables
      namespace=$(echo $tkc | jq -c -r .namespace_ref)
      tkc_name=$(echo $tkc | jq -c -r .name)
      if [[ $(echo $tkc | jq -c -r .k8s_version) == "v1.24.9---vmware.1-tkg.4" ]]; then
        # yaml antrea config templating
        sed -e "s/\${name}/${tkc_name}/" \
            -e "s/\${namespace_ref}/${namespace}/" /nestedVsphere8/12_vsphere_with_tanzu/templates/antreaconfig.yml.template | tee /root/antreaconfig-${cluster_count}.yml > /dev/null
        # yaml antrea config transfer
        scp -o StrictHostKeyChecking=no /root/antreaconfig-${cluster_count}.yml ubuntu@${external_gw_ip}:${remote_path_antrea_create}-${cluster_count}.yml
        # yaml ClusterBootstrap templating
        sed -e "s/\${name}/${tkc_name}/" \
            -e "s/\${k8s_version}/$(echo $tkc | jq -c -r .k8s_version)/" \
            -e "s/\${antrea_config_name}/${tkc_name}/" /nestedVsphere8/12_vsphere_with_tanzu/templates/clusterbootstrap.yml.template | tee /root/clusterbootstrap-${cluster_count}.yml > /dev/null
        # yaml ClusterBootstrap transfer
        scp -o StrictHostKeyChecking=no /root/clusterbootstrap-${cluster_count}.yml ubuntu@${external_gw_ip}:${remote_path_clusterbootstrap_create}-${cluster_count}.yml
      fi
      # yaml cluster templating
      sed -e "s/\${name}/${tkc_name}/" \
          -e "s/\${namespace_ref}/${namespace}/" \
          -e "s@\${services_cidrs}@"$(echo $tkc | jq -c -r .services_cidrs)"@" \
          -e "s@\${pods_cidrs}@$(echo $tkc | jq -c -r .pods_cidrs)@" \
          -e "s/\${serviceDomain}/$(jq -r -c .external_gw.bind.domain $jsonFile)/" \
          -e "s/\${k8s_version}/$(echo $tkc | jq -c -r .k8s_version)/" \
          -e "s/\${control_plane_count}/$(echo $tkc | jq -c -r .control_plane_count)/" \
          -e "s/\${cluster_count}/${cluster_count}/" \
          -e "s/\${workers_count}/$(echo $tkc | jq -c -r .workers_count)/" \
          -e "s/\${vm_class}/$(echo $tkc | jq -c -r .vm_class)/" /nestedVsphere8/12_vsphere_with_tanzu/templates/tkc.yml.template | tee /root/tkc-${cluster_count}.yml > /dev/null
      # yaml cluster transfer
      scp -o StrictHostKeyChecking=no /root/tkc-${cluster_count}.yml ubuntu@${external_gw_ip}:${remote_path}-${cluster_count}.yml
      # bash create templating
      if [[ $(echo $tkc | jq -c -r .k8s_version) == "v1.24.9---vmware.1-tkg.4" ]]; then
        sed -e "s/\${kubectl_password}/${TF_VAR_vsphere_nested_password}/" \
            -e "s/\${sso_domain_name}/${vcsa_sso_domain}/" \
            -e "s/\${api_server_cluster_endpoint}/${api_server_cluster_endpoint}/" \
            -e "s/\${namespace_ref}/${namespace}/" \
            -e "s@\${remote_path}@${remote_path}@" \
            -e "s@\${remote_path_antrea_create}@${remote_path_antrea_create}@" \
            -e "s@\${remote_path_clusterbootstrap_create}@${remote_path_clusterbootstrap_create}@" \
            -e "s/\${cluster_name}/${tkc_name}/" \
            -e "s/\${cluster_count}/${cluster_count}/" /nestedVsphere8/12_vsphere_with_tanzu/templates/tkc.sh.template | tee /root/create-tkc-${cluster_count}.sh > /dev/null
      fi
      if [[ $(echo $tkc | jq -c -r .k8s_version) == "v1.28.8---vmware.1-fips.1-tkg.2" ]]; then
        sed -e "s/\${kubectl_password}/${TF_VAR_vsphere_nested_password}/" \
            -e "s/\${sso_domain_name}/${vcsa_sso_domain}/" \
            -e "s/\${api_server_cluster_endpoint}/${api_server_cluster_endpoint}/" \
            -e "s/\${namespace_ref}/${namespace}/" \
            -e "s@\${remote_path}@${remote_path}@" \
            -e "s/\${cluster_name}/${tkc_name}/" \
            -e "s/\${cluster_count}/${cluster_count}/" /nestedVsphere8/12_vsphere_with_tanzu/templates/tkc_wo_antrea_wo_clusterbootstrap.sh.template | tee /root/create-tkc-${cluster_count}.sh > /dev/null
      fi
      # bash create transfer
      scp -o StrictHostKeyChecking=no /root/create-tkc-${cluster_count}.sh ubuntu@${external_gw_ip}:${remote_path}-${cluster_count}.sh
      # bash destroy templating
      sed -e "s/\${kubectl_password}/${TF_VAR_vsphere_nested_password}/" \
          -e "s/\${sso_domain_name}/${vcsa_sso_domain}/" \
          -e "s/\${api_server_cluster_endpoint}/${api_server_cluster_endpoint}/" \
          -e "s/\${namespace_ref}/${namespace}/" \
          -e "s/\${cluster_bootstrap_name}/${tkc_name}/" \
          -e "s/\${antrea_config_name}/${tkc_name}/" \
          -e "s/\${name}/${tkc_name}/" /nestedVsphere8/12_vsphere_with_tanzu/templates/tkc_destroy.sh.template | tee /root/destroy-tkc-${cluster_count}.sh > /dev/null
      # bash destroy transfer
      scp -o StrictHostKeyChecking=no /root/destroy-tkc-${cluster_count}.sh ubuntu@${external_gw_ip}:${remote_path_destroy}-${cluster_count}.sh
      # bash auth tkc templating
      sed -e "s/\${kubectl_password}/${TF_VAR_vsphere_nested_password}/" \
          -e "s/\${sso_domain_name}/${vcsa_sso_domain}/" \
          -e "s/\${api_server_cluster_endpoint}/${api_server_cluster_endpoint}/" \
          -e "s/\${namespace_ref}/${namespace}/" \
          -e "s/\${name}/${tkc_name}/" /nestedVsphere8/12_vsphere_with_tanzu/templates/tanzu_auth_tkc.sh.template | tee /root/tanzu_auth_tkc-${cluster_count}.sh > /dev/null
      # bash auth tkc transfer
      scp -o StrictHostKeyChecking=no /root/tanzu_auth_tkc-${cluster_count}.sh ubuntu@${external_gw_ip}:${remote_path_auth}-${cluster_count}.sh
      # bash create exec
      ssh -o StrictHostKeyChecking=no -t ubuntu@${external_gw_ip} "/bin/bash ${remote_path}-${cluster_count}.sh"
      #
      # ako values templating, needs to be checked without nsx
      #
      if $(echo $tkc | jq -e '.alb_tenant_name' > /dev/null) ; then # 00_pre_check/00.sh checks that the other keys are present and valid.
        tenant="'$(echo $tkc | jq -c -r '.alb_tenant_name')'"
      else
        tenant="admin"
      fi
      serviceEngineGroupName="Default-Group"
      shardVSSize="SMALL"
      serviceType="NodePortLocal" # needs to be configured before cluster creation
      cniPlugin="antrea"
      disableStaticRouteSync="true" # needs to be true if NodePortLocal is enabled
      if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_tanzu_alb"  ]]; then
        if $(jq -e --arg arg ${namespace} '.tanzu.namespaces[] | select(.name == $arg) | .ingress_cidr' $jsonFile > /dev/null) ; then
          cidr=$(jq -c -r --arg arg ${namespace} '.tanzu.namespaces[] | select(.name == $arg) | .ingress_cidr' $jsonFile)
        else
          cidr=$(jq -c -r '.tanzu.supervisor_cluster.ingress_cidr' $jsonFile)
        fi
        # retrieve the tier1 and his path
        nsxtT1LR_name="t1-${cluster_id}:$(jq -c -r .About.InstanceUuid /root/vcenter_about.json)-${namespace}-rtr"
        t1_path_json_output="/root/t1_path.json"
        /bin/bash /nestedVsphere8/bash/nsx/retrieve_t1_id.sh \
          "$(jq -r .vsphere_underlay.networks.vsphere.management.nsx_nested_ip $jsonFile)" \
          "${TF_VAR_nsx_password}" \
          "${nsxtT1LR_name}" \
          "${t1_path_json_output}"
        nsxtT1LR="$(jq -c -r .t1_path ${t1_path_json_output})"
        # retrieve the name of network in Avi based on the cidr
        avi_network_name_json_output="/root/avi_network_name.json"
        /bin/bash /nestedVsphere8/bash/avi/retrieve_network_name_per_cidr.sh \
                  "${avi_controller_ip}" \
                  "${avi_version}" \
                  "${TF_VAR_avi_password}" \
                  "${avi_cloud_name}" \
                  "$(echo ${cidr} | cut -d"/" -f1)" \
                  "${avi_network_name_json_output}"
        networkName=$(jq -c -r .network_name ${avi_network_name_json_output})
      fi
      if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_tanzu_alb_wo_nsx"  ]]; then
        networkName=$(jq -c -r .networks.alb.vip.port_group_name ${jsonFile})
        nsxtT1LR="''"
        cidr=$(jq -c -r .vsphere_underlay.networks.alb.vip.cidr ${jsonFile})
      fi
      ako_template_file_name=""
      if $(echo $tkc | jq -e '.ako_version' > /dev/null) ; then
        echo "defaulting to AKO version 1.11.1"
        ako_template_file_name="values.yml.1.11.1.template"
        if [[ $(echo $tkc | jq -c -r .ako_version) == "1.12.1" ]]; then
          if $(echo $tkc | jq -e '.ako_api_gateway' > /dev/null) ; then
            if [[ $(echo $tkc | jq -c -r .ako_api_gateway) == "true" ]]; then
              echo "enabling gatewayApi with NodePort because AKO 1.12.1 does not support NodePortLocal..."
              serviceType="NodePort"
              ako_template_file_name="values_api_gw.yml.1.12.1.template"
            else
              echo "defaulting to AKO version 1.12.1 without gatewayApi"
              ako_template_file_name="values.yml.1.12.1.template"
            fi
          else
            echo "defaulting to AKO version 1.12.1 without gatewayApi"
            ako_template_file_name="values.yml.1.12.1.template"
          fi
        fi
        if [[ $(echo $tkc | jq -c -r .ako_version) == "1.12.2" ]]; then
          if $(echo $tkc | jq -e '.ako_api_gateway' > /dev/null) ; then
            if [[ $(echo $tkc | jq -c -r .ako_api_gateway) == "true" ]]; then
              echo "enabling gatewayApi with AKO 1.12.2..."
              ako_template_file_name="values_api_gw.yml.1.12.2.template"
            else
              echo "defaulting to AKO version 1.12.2 without gatewayApi"
              ako_template_file_name="values.yml.1.12.2.template"
            fi
          else
            echo "defaulting to AKO version 1.12.2 without gatewayApi"
            ako_template_file_name="values.yml.1.12.2.template"
          fi
        fi
      else
        echo "defaulting to AKO version 1.11.1"
        ako_template_file_name="values.yml.1.11.1.template"
      fi
      if [ -z "${ako_template_file_name}" ] ; then
        echo "skipping AKO values template..."
      else
        echo "templating AKO values..."
        sed -e "s/\${disableStaticRouteSync}/${disableStaticRouteSync}/" \
            -e "s/\${clusterName}/${tkc_name}/" \
            -e "s/\${cniPlugin}/${cniPlugin}/" \
            -e "s@\${nsxtT1LR}@${nsxtT1LR}@" \
            -e "s/\${networkName}/${networkName}/" \
            -e "s@\${cidr}@${cidr}@" \
            -e "s/\${serviceType}/${serviceType}/" \
            -e "s/\${shardVSSize}/${shardVSSize}/" \
            -e "s/\${serviceEngineGroupName}/${serviceEngineGroupName}/" \
            -e "s/\${controllerVersion}/$(jq -c -r .avi.version $jsonFile)/" \
            -e "s/\${cloudName}/${avi_cloud_name}/" \
            -e "s/\${controllerHost}/${avi_controller_ip}/" \
            -e "s/\${tenant}/${tenant}/" \
            -e "s/\${password}/${TF_VAR_avi_password}/" /nestedVsphere8/12_vsphere_with_tanzu/templates/${ako_template_file_name} | tee /root/values-${cluster_count}.yml > /dev/null
        # ako values transfer
        scp -o StrictHostKeyChecking=no /root/values-${cluster_count}.yml ubuntu@${external_gw_ip}:/home/ubuntu/tkc/ako-values-${cluster_count}.yml
        ((cluster_count++))
      fi
    done
  fi
fi