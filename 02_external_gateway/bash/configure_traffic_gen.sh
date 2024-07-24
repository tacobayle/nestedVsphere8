#!/bin/bash
jsonFile="/root/external_gw.json"
deployment=$(jq -c -r .deployment $jsonFile)
if [[ ${deployment} == "vsphere_alb_wo_nsx" || ${deployment} == "vsphere_tanzu_alb_wo_nsx" || ${deployment} == "vsphere_nsx_alb" || ${deployment} == "vsphere_nsx_alb_telco" || ${deployment} == "vsphere_nsx_tanzu_alb" || ${deployment} == "vsphere_nsx_alb_vcd" ]]; then
  #
  external_gw_ip=$(jq -c -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile)
  sed -e "s/\${avi_username}/admin/" \
      -e "s/\${avi_password}/${TF_VAR_avi_password}/" \
      -e "s/\${avi_nested_ip}/$(jq -c -r .vsphere_underlay.networks.vsphere.management.avi_nested_ip $jsonFile)/" \
       /nestedVsphere8/02_external_gateway/templates/traffic_gen.sh.template | tee /root/traffic_gen.sh > /dev/null
  #
  scp -o StrictHostKeyChecking=no /root/traffic_gen.sh ubuntu@${external_gw_ip}:/home/ubuntu/traffic_gen/traffic_gen.sh
  ssh -o StrictHostKeyChecking=no -t ubuntu@${external_gw_ip} "chmod u+x /home/ubuntu/traffic_gen/traffic_gen.sh"
  ssh -o StrictHostKeyChecking=no -t ubuntu@${external_gw_ip} "(crontab -l 2>/dev/null; echo \"* * * * * /home/ubuntu/traffic_gen/traffic_gen.sh\") | crontab -"
fi