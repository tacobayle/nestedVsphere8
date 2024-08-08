#!/bin/bash
jsonFile="/root/avi.json"
source /nestedVsphere8/bash/tf_init_apply.sh
#
tf_init_apply "Configuration of ALB controller - This should take less than 60 minutes" /nestedVsphere8/11_nsx_alb_config /nestedVsphere8/log/11.stdout /nestedVsphere8/log/11.stderr $jsonFile
#
if [[ $(jq -c -r .vsphere_underlay.networks.alb $jsonFile) == "null" && $(jq -c -r .nsx $jsonFile) != "null" ]]; then
  if [[ $(jq '[.nsx.config.segments_overlay[] | select(has("lbaas_public")).display_name] | length' ${jsonFile}) -eq 1 && \
        $(jq '[.nsx.config.segments_overlay[] | select(has("lbaas_private")).display_name] | length' ${jsonFile}) -eq 1 && \
        $(jq '[.avi.config.cloud.networks_data[] | select(has("lbaas_public")).display_name] | length' ${jsonFile}) -eq 1 && \
        $(jq '[.avi.config.cloud.networks_data[] | select(has("lbaas_private")).display_name] | length' ${jsonFile}) -eq 1 ]]; then
    ssh -o StrictHostKeyChecking=no -t ubuntu@${external_gw_ip} "/bin/bash /nestedVsphere8/02_external_gateway/lbaas/cleanup.sh"
  fi
fi