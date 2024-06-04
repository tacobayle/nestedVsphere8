#!/bin/bash
#
source /nestedVsphere8/bash/govc/variables.sh
#
vsphere_host="$(jq -r .vsphere_underlay.vcsa $jsonFile)"
vsphere_username=${TF_VAR_vsphere_underlay_username}
vcenter_domain=""
vsphere_password=${TF_VAR_vsphere_underlay_password}
vsphere_dc="$(jq -r .vsphere_underlay.datacenter $jsonFile)"
vsphere_cluster="$(jq -r .vsphere_underlay.cluster $jsonFile)"
#
load_govc_env
