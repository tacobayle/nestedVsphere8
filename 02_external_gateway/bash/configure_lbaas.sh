#!/bin/bash
jsonFile="/root/avi.json"
rm /root/lbaas.json
if [[ $(jq -c -r .vsphere_underlay.networks.alb $jsonFile) == "null" && $(jq -c -r .nsx $jsonFile) != "null" ]]; then
  if [[ $(jq '[.nsx.config.segments_overlay[] | select(has("lbaas_public")).display_name] | length' ${jsonFile}) -eq 1 && \
        $(jq '[.nsx.config.segments_overlay[] | select(has("lbaas_private")).display_name] | length' ${jsonFile}) -eq 1 && \
        $(jq '[.avi.config.cloud.networks_data[] | select(has("lbaas_public")).display_name] | length' ${jsonFile}) -eq 1 && \
        $(jq '[.avi.config.cloud.networks_data[] | select(has("lbaas_private")).display_name] | length' ${jsonFile}) -eq 1 ]]; then
    external_gw_ip=$(jq -c -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile)
    json_data='{
    "public":
      {
        "lbaas_segment": "'$(jq -c -r '[.nsx.config.segments_overlay[] | select(has("lbaas_public")).display_name][0]' ${jsonFile})'"
      },
    "docker_username": "'${TF_VAR_docker_registry_username}'",
    "docker_password": "'${TF_VAR_docker_registry_password}'",
    "password": "'${TF_VAR_ubuntu_password}'",
    "nsx_username": "admin",
    "nsx_password": "'${TF_VAR_nsx_password}'",
    "nsx_nested_ip": "'$(jq -r .vsphere_underlay.networks.vsphere.management.nsx_nested_ip $jsonFile)'",
    "avi_username": "admin",
    "avi_password": "'${TF_VAR_avi_password}'",
    "avi_version": "'$(jq -r .avi.version $jsonFile)'",
    "avi_tenant": "automation",
    "avi_cloud": "'$(jq -c -r '.avi.config.cloud.name' $jsonFile)'",
    "avi_domain": "'$(jq -c -r '.avi.config.domain' $jsonFile)'",
    "avi_nested_ip": "'$(jq -c -r .vsphere_underlay.networks.vsphere.management.avi_nested_ip $jsonFile)'",
    "avi_application_profile_ref": "System-Secure-HTTP",
    "avi_ssl_profile_ref": "System-Standard",
    "vault_certificate_mgmt_profile_name": "'$(jq -c -r .vault.certificate_mgmt_profile.name /nestedVsphere8/07_nsx_alb/variables.json)'"
    }'
    if [[ $(jq '[.avi.config.cloud.networks_data[] | select(has("lbaas_public")).name] | length' ${jsonFile}) -eq 1 ]]; then
      json_data=$(echo ${json_data} | jq -c -r '.public += {"avi_tier1": "'$(jq -c -r --arg arg $(jq -c -r '[.avi.config.cloud.networks_data[] | select(has("lbaas_public")).name] | .[0]' ${jsonFile}) '.nsx.config.segments_overlay[] | select(.display_name == $arg).tier1' ${jsonFile})'","avi_vip_cidr": "'$(jq -c -r '[.avi.config.cloud.networks_data[] | select(has("lbaas_public")).avi_ipam_vip.cidr] | .[0]' ${jsonFile})'"}')
    fi
    if [[ $(jq '[.nsx.config.segments_overlay[] | select(has("lbaas_private")).display_name] | length' ${jsonFile}) -eq 1 ]]; then
      json_data=$(echo ${json_data} | jq -c -r '. += {"private": {"lbaas_segment": "'$(jq -c -r '[.nsx.config.segments_overlay[] | select(has("lbaas_private")).display_name][0]' ${jsonFile})'"}}')
    fi
    if [[ $(jq '[.avi.config.cloud.networks_data[] | select(has("lbaas_private")).name] | length' ${jsonFile}) -eq 1 ]]; then
      json_data=$(echo ${json_data} | jq -c -r '.private += {"avi_tier1": "'$(jq -c -r --arg arg $(jq -c -r '[.avi.config.cloud.networks_data[] | select(has("lbaas_private")).name] | .[0]' ${jsonFile}) '.nsx.config.segments_overlay[] | select(.display_name == $arg).tier1' ${jsonFile})'", "avi_vip_cidr": "'$(jq -c -r '[.avi.config.cloud.networks_data[] | select(has("lbaas_private")).avi_ipam_vip.cidr] | .[0]' ${jsonFile})'"}')
    fi

    echo ${json_data} | tee /root/lbaas.json
    #
    scp -o StrictHostKeyChecking=no /root/lbaas.json ubuntu@${external_gw_ip}:/home/ubuntu/lbaas/lbaas.json
    #
    scp -o StrictHostKeyChecking=no -r /nestedVsphere8/02_external_gateway/lbaas/govc ubuntu@${external_gw_ip}:/home/ubuntu/lbaas
    scp -o StrictHostKeyChecking=no -r /nestedVsphere8/02_external_gateway/lbaas/nsx ubuntu@${external_gw_ip}:/home/ubuntu/lbaas
    scp -o StrictHostKeyChecking=no -r /nestedVsphere8/02_external_gateway/lbaas/avi ubuntu@${external_gw_ip}:/home/ubuntu/lbaas
    scp -o StrictHostKeyChecking=no -r /nestedVsphere8/02_external_gateway/lbaas/python ubuntu@${external_gw_ip}:/home/ubuntu/lbaas
    scp -o StrictHostKeyChecking=no -r /nestedVsphere8/02_external_gateway/lbaas/html ubuntu@${external_gw_ip}:/home/ubuntu/lbaas
    #
    scp -o StrictHostKeyChecking=no /nestedVsphere8/02_external_gateway/templates/backend_userdata.yaml.template ubuntu@${external_gw_ip}:/home/ubuntu/lbaas/govc/backend_userdata.yaml.template
    #
    sed -e "s@\${folder}@/home/ubuntu/lbaas/govc@" \
        -e "s/\${vsphere_host}/$(jq -r .vsphere_nested.vcsa_name $jsonFile)/" \
        -e "s/\${domain}/$(jq -r .external_gw.bind.domain $jsonFile)/" \
        -e "s/\${vsphere_username}/administrator/" \
        -e "s/\${vcenter_domain}/$(jq -r .vsphere_nested.sso.domain_name $jsonFile)/" \
        -e "s/\${vsphere_password}/${TF_VAR_vsphere_nested_password}/" \
        -e "s/\${vsphere_dc}/$(jq -r .vsphere_nested.datacenter $jsonFile)/" \
        -e "s/\${vsphere_cluster}/$(jq -r .vsphere_nested.cluster_list[0] $jsonFile)/" \
        -e "s/\${vsphere_datastore}/$(jq -r .vsphere_nested.datastore_list[0] $jsonFile)/" /nestedVsphere8/02_external_gateway/templates/load_govc_nested.sh.template | tee /root/load_govc_nested.sh > /dev/null
    #
    scp -o StrictHostKeyChecking=no /root/load_govc_nested.sh ubuntu@${external_gw_ip}:/home/ubuntu/lbaas/govc/load_govc_nested.sh
    #
    scp -o StrictHostKeyChecking=no /nestedVsphere8/bash/nsx/create_nsx_api_session.sh ubuntu@${external_gw_ip}:/home/ubuntu/lbaas/nsx/create_nsx_api_session.sh
    scp -o StrictHostKeyChecking=no /nestedVsphere8/bash/nsx/nsx_api.sh ubuntu@${external_gw_ip}:/home/ubuntu/lbaas/nsx/nsx_api.sh
    #
    scp -o StrictHostKeyChecking=no /nestedVsphere8/bash/avi/alb_api.sh ubuntu@${external_gw_ip}:/home/ubuntu/lbaas/avi/alb_api.sh
    #
    scp -o StrictHostKeyChecking=no  /nestedVsphere8/02_external_gateway/lbaas/http_destroy.json  ubuntu@external-gw:/home/ubuntu/lbaas
    scp -o StrictHostKeyChecking=no  /nestedVsphere8/02_external_gateway/lbaas/http_apply_private.json  ubuntu@external-gw:/home/ubuntu/lbaas
    scp -o StrictHostKeyChecking=no  /nestedVsphere8/02_external_gateway/lbaas/http_apply_public.json  ubuntu@external-gw:/home/ubuntu/lbaas
    scp -o StrictHostKeyChecking=no  /nestedVsphere8/02_external_gateway/lbaas/lbaas.sh  ubuntu@external-gw:/home/ubuntu/lbaas
    #
    echo '
    #!/bin/bash
    #
    python3 /home/ubuntu/lbaas/python/lbaas.py
    ' | tee /root/lbaas_service.sh
    #
    scp -o StrictHostKeyChecking=no /root/lbaas_service.sh ubuntu@${external_gw_ip}:/home/ubuntu/lbaas/lbaas_service.sh
    ssh -o StrictHostKeyChecking=no -t ubuntu@${external_gw_ip} "sudo mv /home/ubuntu/lbaas/lbaas_service.sh /usr/bin/lbaas_service.sh ; sudo chown root /usr/bin/lbaas_service.sh ; sudo chgrp root /usr/bin/lbaas_service.sh"
    echo '
    [Unit]
    Description=avi-lbaas

    [Service]
    Type=simple
    ExecStart=/bin/bash /usr/bin/lbaas_service.sh

    [Install]
    WantedBy=multi-user.target
    ' | tee /root/lbaas_service.sh
    scp -o StrictHostKeyChecking=no /root/lbaas_service.sh ubuntu@${external_gw_ip}:/home/ubuntu/lbaas/avi-lbaas.service
    ssh -o StrictHostKeyChecking=no -t ubuntu@${external_gw_ip} "sudo mv /home/ubuntu/lbaas/avi-lbaas.service /etc/systemd/system/avi-lbaas.service
                                                                 sudo chown root /etc/systemd/system/avi-lbaas.service
                                                                 sudo chgrp root /etc/systemd/system/avi-lbaas.service
                                                                 sudo chmod 644 /etc/systemd/system/avi-lbaas.service
                                                                 sudo systemctl start avi-lbaas
                                                                 sudo systemctl enable avi-lbaas"
    #
    ssh -o StrictHostKeyChecking=no -t ubuntu@${external_gw_ip} "sudo chmod 644 /etc/systemd/system/avi-lbaas.service"
    ssh -o StrictHostKeyChecking=no -t ubuntu@${external_gw_ip} "sudo systemctl start avi-lbaas"
    ssh -o StrictHostKeyChecking=no -t ubuntu@${external_gw_ip} "sudo systemctl enable avi-lbaas"
    #
    ssh -o StrictHostKeyChecking=no -t ubuntu@${external_gw_ip} "sudo mv /home/ubuntu/lbaas/html/index.html /var/www/html/
                                                                 sudo chown root /var/www/html/index.html
                                                                 sudo chgrp root /var/www/html/index.html"
    #
    ssh -o StrictHostKeyChecking=no -t ubuntu@${external_gw_ip} "sudo mv /home/ubuntu/lbaas/html/styles.css /var/www/html/
                                                                 sudo chown root /var/www/html/styles.css
                                                                 sudo chgrp root /var/www/html/styles.css"
    #
    sed -e "s@\${external_gw_ip}@${external_gw_ip}@" /nestedVsphere8/02_external_gateway/templates/script.js.template | tee /root/script.js > /dev/null
    scp -o StrictHostKeyChecking=no /root/script.js ubuntu@${external_gw_ip}:/home/ubuntu/lbaas/html/script.js
    #
    sed -e "s@\${external_gw_ip}@${external_gw_ip}@" /nestedVsphere8/02_external_gateway/templates/api.js.template | tee /root/api.js > /dev/null
    scp -o StrictHostKeyChecking=no /root/api.js ubuntu@${external_gw_ip}:/home/ubuntu/lbaas/html/api.js
    #
    ssh -o StrictHostKeyChecking=no -t ubuntu@${external_gw_ip} "sudo mv /home/ubuntu/lbaas/html/script.js /var/www/html/
                                                                 sudo chown root /var/www/html/script.js
                                                                 sudo chgrp root /var/www/html/script.js"
    #
    ssh -o StrictHostKeyChecking=no -t ubuntu@${external_gw_ip} "sudo mv /home/ubuntu/lbaas/html/api.js /var/www/html/
                                                                 sudo chown root /var/www/html/api.js
                                                                 sudo chgrp root /var/www/html/api.js"
    #
    ssh -o StrictHostKeyChecking=no -t ubuntu@${external_gw_ip} "sudo mv /home/ubuntu/lbaas/html/api.css /var/www/html/
                                                                 sudo chown root /var/www/html/api.css
                                                                 sudo chgrp root /var/www/html/api.css"
    #
    ssh -o StrictHostKeyChecking=no -t ubuntu@${external_gw_ip} "sudo mv /home/ubuntu/lbaas/html/api.html /var/www/html/
                                                                 sudo chown root /var/www/html/api.html
                                                                 sudo chgrp root /var/www/html/api.html"
    #
    ssh -o StrictHostKeyChecking=no -t ubuntu@${external_gw_ip} "sudo mv /home/ubuntu/lbaas/html/diagram-demo.jpg /var/www/html/
                                                                 sudo chown root /var/www/html/diagram-demo.jpg
                                                                 sudo chgrp root /var/www/html/diagram-demo.jpg"
    #
    ssh -o StrictHostKeyChecking=no -t ubuntu@${external_gw_ip} "sudo mv /home/ubuntu/lbaas/html/index.html /var/www/html/
                                                                 sudo chown root /var/www/html/index.html
                                                                 sudo chgrp root /var/www/html/index.html"
    #
    ssh -o StrictHostKeyChecking=no -t ubuntu@${external_gw_ip} "sudo mv /home/ubuntu/lbaas/html/styles.css /var/www/html/
                                                                 sudo chown root /var/www/html/styles.css
                                                                 sudo chgrp root /var/www/html/styles.css"
    #
    ssh -o StrictHostKeyChecking=no -t ubuntu@${external_gw_ip} "sudo mv /home/ubuntu/lbaas/html/builtin.png /var/www/html/
                                                                 sudo chown root /var/www/html/builtin.png
                                                                 sudo chgrp root /var/www/html/builtin.png"
    #
    ssh -o StrictHostKeyChecking=no -t ubuntu@${external_gw_ip} "sudo mv /home/ubuntu/lbaas/html/dns.png /var/www/html/
                                                                 sudo chown root /var/www/html/dns.png
                                                                 sudo chgrp root /var/www/html/dns.png"
    #
    ssh -o StrictHostKeyChecking=no -t ubuntu@${external_gw_ip} "sudo mv /home/ubuntu/lbaas/html/ipam.png /var/www/html/
                                                                 sudo chown root /var/www/html/ipam.png
                                                                 sudo chgrp root /var/www/html/ipam.png"
    #
    ssh -o StrictHostKeyChecking=no -t ubuntu@${external_gw_ip} "sudo mv /home/ubuntu/lbaas/html/nsx.png /var/www/html/
                                                                 sudo chown root /var/www/html/nsx.png
                                                                 sudo chgrp root /var/www/html/nsx.png"
    #
    ssh -o StrictHostKeyChecking=no -t ubuntu@${external_gw_ip} "sudo mv /home/ubuntu/lbaas/html/slack.png /var/www/html/
                                                                 sudo chown root /var/www/html/slack.png
                                                                 sudo chgrp root /var/www/html/slack.png"
    #
    ssh -o StrictHostKeyChecking=no -t ubuntu@${external_gw_ip} "sudo mv /home/ubuntu/lbaas/html/vault.png /var/www/html/
                                                                 sudo chown root /var/www/html/vault.png
                                                                 sudo chgrp root /var/www/html/vault.png"
    #
    ssh -o StrictHostKeyChecking=no -t ubuntu@${external_gw_ip} "sudo mv /home/ubuntu/lbaas/html/vsphere.png /var/www/html/
                                                                 sudo chown root /var/www/html/vsphere.png
                                                                 sudo chgrp root /var/www/html/vsphere.png"
    #
    scp -o StrictHostKeyChecking=no ubuntu@${external_gw_ip}:$(jq -c -r .vault.secret_file_path /nestedVsphere8/02_external_gateway/variables.json) /root/$(basename $(jq -c -r .vault.secret_file_path /nestedVsphere8/02_external_gateway/variables.json))
    #
    scp -o StrictHostKeyChecking=no ubuntu@${external_gw_ip}:$(jq -c -r .vault.pki_intermediate.cert.path_signed /nestedVsphere8/02_external_gateway/variables.json) /root/$(basename $(jq -c -r '.vault.pki_intermediate.cert.path_signed' "/nestedVsphere8/02_external_gateway/variables.json"))
    #
    scp -o StrictHostKeyChecking=no ubuntu@${external_gw_ip}:$(jq -c -r .vault.pki.cert.path /nestedVsphere8/02_external_gateway/variables.json) /root/$(basename $(jq -c -r '.vault.pki.cert.path' "/nestedVsphere8/02_external_gateway/variables.json"))
    #

  fi
fi