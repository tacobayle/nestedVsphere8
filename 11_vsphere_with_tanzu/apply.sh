#!/bin/bash
jsonFile="/root/vsphere_with_tanzu.json"
source /nestedVsphere8/bash/tf_init_apply.sh
source /nestedVsphere8/bash/vcenter_api.sh
source /nestedVsphere8/bash/ip.sh
#
IFS=$'\n'
#
vcsa_fqdn="$(jq -r .vsphere_nested.vcsa_name $jsonFile).$(jq -r .external_gw.bind.domain $jsonFile)"
vcsa_sso_domain=$(jq -r .vsphere_nested.sso.domain_name $jsonFile)
external_gw_ip=$(jq -c -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile)
#
# registering Avi in the NSX config
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_tanzu_alb" ]]; then
  /bin/bash /nestedVsphere8/bash/nsx/registering_avi_controller.sh \
    "$(jq -r .vsphere_underlay.networks.vsphere.management.nsx_nested_ip $jsonFile)" \
    "${TF_VAR_nsx_password}" \
    "${TF_VAR_avi_password}" \
    "$(jq -c -r .vsphere_underlay.networks.vsphere.management.avi_nested_ip $jsonFile)"
fi
exit
