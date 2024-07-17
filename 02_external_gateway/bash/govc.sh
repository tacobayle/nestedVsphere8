#!/bin/bash
jsonFile="/root/external_gw.json"
source /nestedVsphere8/bash/ip.sh
rm /root/lbaas.json
if [[ $(jq -c -r .vsphere_underlay.networks.alb $jsonFile) == "null" && $(jq -c -r .nsx $jsonFile) != "null" ]]; then
  if [[ $(jq '[.nsx.config.segments_overlay[] | select(has("lbaas_ips")).display_name] | length' ${jsonFile}) -eq 1 ]]; then
    external_gw_ip=$(jq -c -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile)
    json_data='{
    "lbaas_segment": "'$(jq -c -r '[.nsx.config.segments_overlay[] | select(has("lbaas_ips")).display_name][0]' ${jsonFile})'",
    "lbaas_prefix": "'$(jq -c -r '[.nsx.config.segments_overlay[] | select(has("lbaas_ips")).cidr][0]' ${jsonFile} | cut -d"/" -f2)'",
    "lbaas_gw": "'$(nextip $(jq -c -r '[.nsx.config.segments_overlay[] | select(has("lbaas_ips")).cidr][0]' ${jsonFile} | cut -d"/" -f1))'",
    "lbaas_dns": "'${external_gw_ip}'",
    "lbaas_current_ip": "'$(jq -c -r '[.nsx.config.segments_overlay[] | select(has("lbaas_ips")).lbaas_ips[0]][0]' ${jsonFile})'",
    "lbaas_last_ip": "'$(nextip $(jq -c -r '[.nsx.config.segments_overlay[] | select(has("lbaas_ips")).lbaas_ips[1]][0]' ${jsonFile}))'",
    "docker_username": "'${TF_VAR_docker_registry_username}'",
    "docker_password": "'${TF_VAR_docker_registry_password}'",
    "password": "'${TF_VAR_ubuntu_password}'"
    }'
    echo ${json_data} | tee /root/lbaas.json
    #
    scp -o StrictHostKeyChecking=no /root/lbaas.json ubuntu@${external_gw_ip}:/home/ubuntu/govc/lbaas.json
    #
    scp -o StrictHostKeyChecking=no /nestedVsphere8/02_external_gateway/templates/backend_userdata.yaml.template ubuntu@${external_gw_ip}:/home/ubuntu/govc/backend_userdata.yaml.template
    #
    scp -o StrictHostKeyChecking=no /nestedVsphere8/02_external_gateway/govc/govc_init.sh ubuntu@${external_gw_ip}:/home/ubuntu/govc/govc_init.sh
    #
    sed -e "s/\${vsphere_host}/$(jq -r .vsphere_nested.vcsa_name $jsonFile)/" \
        -e "s/\${domain}/$(jq -r .external_gw.bind.domain $jsonFile)/" \
        -e "s/\${vsphere_username}/administrator/" \
        -e "s/\${vcenter_domain}/$(jq -r .vsphere_nested.sso.domain_name $jsonFile)/" \
        -e "s/\${vsphere_password}/${TF_VAR_vsphere_nested_password}/" \
        -e "s/\${vsphere_dc}/$(jq -r .vsphere_nested.datacenter $jsonFile)/" \
        -e "s/\${vsphere_cluster}/$(jq -r .vsphere_nested.cluster_list[0] $jsonFile)/" \
        -e "s/\${vsphere_datastore}/$(jq -r .vsphere_nested.datastore_list[0] $jsonFile)/" /nestedVsphere8/02_external_gateway/templates/load_govc_nested.sh.template | tee /root/load_govc_nested.sh > /dev/null
    #
    scp -o StrictHostKeyChecking=no /root/load_govc_nested.sh ubuntu@${external_gw_ip}:/home/ubuntu/govc/load_govc_nested.sh
    #
    scp -o StrictHostKeyChecking=no /nestedVsphere8/02_external_gateway/govc/create_backend.sh ubuntu@${external_gw_ip}:/home/ubuntu/govc/create_backend.sh
    #
  fi
fi