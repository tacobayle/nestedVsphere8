#!/bin/bash
jsonFile="/root/avi.json"
if [[ $(jq -c -r .vsphere_underlay.networks.alb $jsonFile) == "null" && $(jq -c -r .nsx $jsonFile) != "null" ]]; then
  if [[ $(jq '[.nsx.config.segments_overlay[] | select(has("lbaas_public")).display_name] | length' ${jsonFile}) -eq 1 && \
        $(jq '[.nsx.config.segments_overlay[] | select(has("lbaas_private")).display_name] | length' ${jsonFile}) -eq 1 && \
        $(jq '[.avi.config.cloud.networks_data[] | select(has("lbaas_public")).display_name] | length' ${jsonFile}) -eq 1 && \
        $(jq '[.avi.config.cloud.networks_data[] | select(has("lbaas_private")).display_name] | length' ${jsonFile}) -eq 1 ]]; then
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
    cp /nestedVsphere8/02_external_gateway/govc/govc_init.sh /root/govc_init.sh
    source /root/load_govc_nested.sh
    govc library.create lbaas
    govc library.import lbaas /root/focal-server-cloudimg-amd64.ova
    # create API backend server and send it to external gw


    echo '
    #!/bin/bash
    #
    python3 /home/ubuntu/lbaas/lbaas.py
    ' | sudo tee /root/lbaas_service.sh
    #
    scp -o StrictHostKeyChecking=no /root/lbaas_service.sh ubuntu@${external_gw_ip}:/usr/bin/lbaas_service.sh
    echo '
    [Unit]
    Description=avi-lbaas

    [Service]
    Type=simple
    ExecStart=/bin/bash /usr/bin/lbaas.sh

    [Install]
    WantedBy=multi-user.target
    ' | sudo tee /etc/systemd/system/avi-lbaas.service
  fi
  #
  sudo chmod 644 /etc/systemd/system/avi-lbaas.service
  #
  sudo systemctl start avi-lbaas
  sudo systemctl enable avi-lbaas
fi