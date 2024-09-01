#!/bin/bash
jsonFile="/root/external_gw.json"
deployment=$(jq -c -r .deployment $jsonFile)
if [[ ${deployment} == "vsphere_nsx_alb" || ${deployment} == "vsphere_nsx_tanzu_alb" ]]; then
  echo "-----------------------------------------------------"
  echo "Starting timestamp: $(date)"
  log_file="/nestedVsphere8/log/09_lbaas.stdout"
  jsonFile="/root/avi.json"
  if [[ $(jq '[.nsx.config.segments_overlay[] | select(has("lbaas_public")).display_name] | length' ${jsonFile}) -eq 1 && \
        $(jq '[.nsx.config.segments_overlay[] | select(has("lbaas_private")).display_name] | length' ${jsonFile}) -eq 1 && \
        $(jq '[.avi.config.cloud.networks_data[] | select(has("lbaas_public")).display_name] | length' ${jsonFile}) -eq 1 && \
        $(jq '[.avi.config.cloud.networks_data[] | select(has("lbaas_private")).display_name] | length' ${jsonFile}) -eq 1 ]]; then
    echo "Creation a content library for LBaaS demo - This should take less than 10 minute" | tee -a ${log_file}
    echo "Starting timestamp: $(date)" | tee -a ${log_file}
    sed -e "s@\${folder}@/root@" \
            -e "s/\${vsphere_host}/$(jq -r .vsphere_nested.vcsa_name $jsonFile)/" \
            -e "s/\${domain}/$(jq -r .external_gw.bind.domain $jsonFile)/" \
            -e "s/\${vsphere_username}/administrator/" \
            -e "s/\${vcenter_domain}/$(jq -r .vsphere_nested.sso.domain_name $jsonFile)/" \
            -e "s/\${vsphere_password}/${TF_VAR_vsphere_nested_password}/" \
            -e "s/\${vsphere_dc}/$(jq -r .vsphere_nested.datacenter $jsonFile)/" \
            -e "s/\${vsphere_cluster}/$(jq -r .vsphere_nested.cluster_list[0] $jsonFile)/" \
            -e "s/\${vsphere_datastore}/$(jq -r .vsphere_nested.datastore_list[0] $jsonFile)/" /nestedVsphere8/02_external_gateway/templates/load_govc_nested.sh.template | tee /root/load_govc_nested.sh > /dev/null
    # create content library for backend
    cp /nestedVsphere8/02_external_gateway/lbaas/govc/govc_init.sh /root/govc_init.sh
    source /root/load_govc_nested.sh
    echo "" | tee ${log_file} > /dev/null
    govc library.create lbaas
    govc library.import lbaas /root/focal-server-cloudimg-amd64.ova
    echo "Ending timestamp: $(date)" | tee -a ${log_file}
    echo "-----------------------------------------------------" | tee -a ${log_file}
    #
    touch "/root/09_lbaas"
    if [ -z "${slack_webhook_url}" ] ; then echo "ignoring slack update" ; else curl -X POST -H 'Content-type: application/json' --data '{"text":"'$(date "+%Y-%m-%d,%H:%M:%S")', '${deployment}': 09_lbaas deployed"}' ${slack_webhook_url} >/dev/null 2>&1; fi
  fi
fi