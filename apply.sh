#!/bin/bash
#
echo ""
echo "==> Checking Variables files"
if [ -s "/etc/config/variables.json" ]; then
  jsonFile="/etc/config/variables.json"
  jq . $jsonFile > /dev/null
  jq . $jsonFile
else
  echo "/etc/config/variables.json file is empty!!"
  exit 255
fi
#
# 00_pre_check
#
/bin/bash /nestedVsphere8/00_pre_check/00.sh
if [ $? -ne 0 ] ; then exit 1 ; fi
jsonFile="/root/variables.json"
#
/bin/bash /nestedVsphere8/00_pre_check/01.sh
if [ $? -ne 0 ] ; then exit 1 ; fi
#
/bin/bash /nestedVsphere8/00_pre_check/02.sh
if [ $? -ne 0 ] ; then exit 1 ; fi
#
/bin/bash /nestedVsphere8/00_pre_check/03.sh
if [ $? -ne 0 ] ; then exit 1 ; fi
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_telco" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_tanzu_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_vcd" || $(jq -c -r .deployment $jsonFile) == "vsphere_alb_wo_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_tanzu_alb_wo_nsx" ]]; then
  /bin/bash /nestedVsphere8/00_pre_check/04.sh
   if [ $? -ne 0 ] ; then exit 1 ; fi
fi
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_telco" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_tanzu_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_vcd" ]]; then
  /bin/bash /nestedVsphere8/00_pre_check/05.sh
   if [ $? -ne 0 ] ; then exit 1 ; fi
fi
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_alb_wo_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_tanzu_alb_wo_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_telco" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_tanzu_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_vcd" ]]; then
  /bin/bash /nestedVsphere8/00_pre_check/07.sh
   if [ $? -ne 0 ] ; then exit 1 ; fi
fi
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_alb_wo_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_tanzu_alb_wo_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_tanzu_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_vcd" ]]; then
  /bin/bash /nestedVsphere8/00_pre_check/08.sh
   if [ $? -ne 0 ] ; then exit 1 ; fi
fi
#
if [[ $(jq -c -r .unmanaged_k8s_status $jsonFile) == true ]]; then
  /bin/bash /nestedVsphere8/00_pre_check/09.sh
   if [ $? -ne 0 ] ; then exit 1 ; fi
fi
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_tanzu_alb_wo_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_tanzu_alb" ]]; then
  /bin/bash /nestedVsphere8/00_pre_check/11.sh
   if [ $? -ne 0 ] ; then exit 1 ; fi
fi
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_telco" ]]; then
  /bin/bash /nestedVsphere8/00_pre_check/12.sh
  if [ $? -ne 0 ] ; then exit 1 ; fi
fi
#
echo ""
echo "********* Deployment use case: $(jq -c -r .deployment $jsonFile) *********"
echo ""
#
# Environment Creation
#
/bin/bash /nestedVsphere8/01_underlay_vsphere_directory/apply.sh
if [ $? -ne 0 ] ; then exit 1 ; fi
#
#
#
output_file="/root/output.txt"
rm -f ${output_file}
echo "+++++++++++++++++ O U T P U T S +++++++++++++++++++++" | tee ${output_file} >/dev/null 2>&1
#
# 02_external_gateway
#
/bin/bash /nestedVsphere8/02_external_gateway/apply.sh
if [ $? -ne 0 ] ; then exit 1 ; fi
scp -o StrictHostKeyChecking=no ubuntu@$(jq -c -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile):/home/ubuntu/.ssh/id_rsa /root/.ssh/id_rsa_external >/dev/null 2>&1
scp -o StrictHostKeyChecking=no ubuntu@$(jq -c -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile):/home/ubuntu/.ssh/id_rsa.pub /root/.ssh/id_rsa_external.pub >/dev/null 2>&1
#
# outputs 02_external_gateway
#
echo "" | tee -a ${output_file} >/dev/null 2>&1
echo "+++++++ external-gateway" | tee -a ${output_file} >/dev/null 2>&1
echo "ssh your external gateway from the pod:" | tee -a ${output_file} >/dev/null 2>&1
echo "  > ssh -o StrictHostKeyChecking=no ubuntu@external-gw" | tee -a ${output_file} >/dev/null 2>&1
echo "ssh your external gateway from an external node:" | tee -a ${output_file} >/dev/null 2>&1
echo "  > ssh -o StrictHostKeyChecking=no ubuntu@$(jq -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile)" | tee -a ${output_file} >/dev/null 2>&1
echo "ssh ubuntu password: ${TF_VAR_ubuntu_password}" | tee -a ${output_file} >/dev/null 2>&1
#
# 03_nested_vsphere
#
/bin/bash /nestedVsphere8/03_nested_vsphere/apply.sh
if [ $? -ne 0 ] ; then exit 1 ; fi
#
# outputs 03_nested_vsphere
#
echo "" | tee -a ${output_file} >/dev/null 2>&1
echo "++++++++++++++++ vSphere" | tee -a ${output_file} >/dev/null 2>&1
echo "Configure your /etc/hosts with the following entry:" | tee -a ${output_file} >/dev/null 2>&1
echo "  > $(jq -r .vsphere_underlay.networks.vsphere.management.vcsa_nested_ip $jsonFile) $(jq -r .vsphere_nested.vcsa_name $jsonFile).$(jq -r .external_gw.bind.domain $jsonFile)" | tee -a ${output_file} >/dev/null 2>&1
echo "vSphere server url: https://$(jq -r .vsphere_nested.vcsa_name $jsonFile).$(jq -r .external_gw.bind.domain $jsonFile)" | tee -a ${output_file} >/dev/null 2>&1
echo "ESXi root password: ${TF_VAR_nested_esxi_root_password}" | tee -a ${output_file} >/dev/null 2>&1
echo "vSphere username: administrator@$(jq -c -r .vsphere_nested.sso.domain_name $jsonFile)" | tee -a ${output_file} >/dev/null 2>&1
echo "vSphere password: ${TF_VAR_vsphere_nested_password}" | tee -a ${output_file} >/dev/null 2>&1
#
echo "waiting for 20 minutes to finish the vCenter config..."
sleep 1200
#
# 04_networks
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_telco" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_tanzu_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_vcd" || $(jq -c -r .deployment $jsonFile) == "vsphere_alb_wo_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_tanzu_alb_wo_nsx" ]]; then
  /bin/bash /nestedVsphere8/04_networks/apply.sh
   if [ $? -ne 0 ] ; then exit 1 ; fi
fi
#
# 05_nsx_manager
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_telco" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_tanzu_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_vcd" ]]; then
  /bin/bash /nestedVsphere8/05_nsx_manager/apply.sh
  if [ $? -ne 0 ] ; then exit 1 ; fi
  echo "waiting for 5 minutes to finish the NSX bootstrap..."
  sleep 300
fi
#
# 06_nsx_config
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_telco" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_tanzu_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_vcd" ]]; then
  /bin/bash /nestedVsphere8/06_nsx_config/apply.sh
  if [ $? -ne 0 ] ; then exit 1 ; fi
  #
  # outputs NSX
  #
  if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_telco" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_tanzu_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_vcd" ]]; then
    echo "" | tee -a ${output_file} >/dev/null 2>&1
    echo "++++++++++++++++++++ NSX" | tee -a ${output_file} >/dev/null 2>&1
    echo "  > NSX manager url: https://$(jq -r .vsphere_underlay.networks.vsphere.management.nsx_nested_ip $jsonFile)" | tee -a ${output_file} >/dev/null 2>&1
    echo "NSX admin password: ${TF_VAR_nsx_password}" | tee -a ${output_file} >/dev/null 2>&1
  fi
fi
#
# 07_nsx_alb
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_alb_wo_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_tanzu_alb_wo_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_telco" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_tanzu_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_vcd" ]]; then
  /bin/bash /nestedVsphere8/07_nsx_alb/apply.sh
   if [ $? -ne 0 ] ; then exit 1 ; fi
fi
#
# 08_app
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_alb_wo_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_tanzu_alb_wo_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_tanzu_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_vcd" ]]; then
  /bin/bash /nestedVsphere8/08_app/apply.sh
   if [ $? -ne 0 ] ; then exit 1 ; fi
fi
#
# 09_unmanaged_k8s_clusters
#
if [[ $(jq -c -r .unmanaged_k8s_status $jsonFile) == true ]]; then
  /bin/bash /nestedVsphere8/09_unmanaged_k8s_clusters/apply.sh
   if [ $? -ne 0 ] ; then exit 1 ; fi
  #
  # Output unmanaged K8s clusters
  #
  echo "" | tee -a ${output_file} >/dev/null 2>&1
  echo "+++++++++++++ Deploy AKO" | tee -a ${output_file} >/dev/null 2>&1
  echo "  > helm install --generate-name $(jq -c -r .helm_url /nestedVsphere8/07_nsx_alb/variables.json) --version $(jq -c -r .avi.ako_version $jsonFile) -f path_values.yml --namespace=avi-system" | tee -a ${output_file} >/dev/null 2>&1
fi
#
# 10_nsx_alb_config
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_alb_wo_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_tanzu_alb_wo_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_telco" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_tanzu_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_vcd" ]]; then
  /bin/bash /nestedVsphere8/10_nsx_alb_config/apply.sh
  if [ $? -ne 0 ] ; then exit 1 ; fi
  #
  # output Avi
  #
  echo "" | tee -a ${output_file} >/dev/null 2>&1
  echo "++++++++++++++++ NSX-ALB" | tee -a ${output_file} >/dev/null 2>&1
  echo "  > NSX ALB controller url: https://$(jq -r .vsphere_underlay.networks.vsphere.management.avi_nested_ip $jsonFile)" | tee -a ${output_file} >/dev/null 2>&1
  echo "Avi admin password: ${TF_VAR_avi_password}" | tee -a ${output_file} >/dev/null 2>&1
fi
#
# 11_vsphere_with_tanzu
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_tanzu_alb_wo_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_tanzu_alb" ]]; then
  exit
  echo "-----------------------------------------------------"
  echo "Configuration of vSphere with Tanzu - This should take less than 90 minutes"
  echo "Starting timestamp: $(date)"
  /bin/bash /nestedVsphere8/11_vsphere_with_tanzu/apply.sh 2> /nestedVsphere8/log/11_vsphere_with_tanzu.stderr 1> /nestedVsphere8/log/11_vsphere_with_tanzu.stdin
  if [ $? -ne 0 ] ; then exit 1 ; fi
  echo "Ending timestamp: $(date)"
  #
  # output Tanzu wo NSX
  #
  echo "" | tee -a ${output_file} >/dev/null 2>&1
  echo "+++++ vSphere with Tanzu" | tee -a ${output_file} >/dev/null 2>&1
  echo "Authenticate to the supervisor cluster from the external-gateway:" | tee -a ${output_file} >/dev/null 2>&1
  echo "  > /bin/bash /home/ubuntu/tanzu/auth_supervisor.sh" | tee -a ${output_file} >/dev/null 2>&1
  echo "Authenticate to a specific tkc cluster from the external-gateway:" | tee -a ${output_file} >/dev/null 2>&1
  echo "  > /bin/bash /home/ubuntu/tkc/auth-tkc-*.sh" | tee -a ${output_file} >/dev/null 2>&1
  echo "Add docker credential in your tkc cluster:" | tee -a ${output_file} >/dev/null 2>&1
  echo "  > /home/ubuntu/bin/kubectl create secret docker-registry docker --docker-server=docker.io --docker-username=${TF_VAR_docker_registry_username} --docker-password=****** --docker-email=${TF_VAR_docker_registry_email}" | tee -a ${output_file} >/dev/null 2>&1
  echo '  > /home/ubuntu/bin/kubectl patch serviceaccount default -p "{\"imagePullSecrets\": [{\"name\": \"docker\"}]}"' | tee -a ${output_file} >/dev/null 2>&1
  echo "Enable deployment creation:" | tee -a ${output_file} >/dev/null 2>&1
  echo "  > /home/ubuntu/bin/kubectl create clusterrolebinding default-tkg-admin-privileged-binding --clusterrole=psp:vmware-system-privileged --group=system:authenticated" | tee -a ${output_file} >/dev/null 2>&1
  echo "+++++++++++++ Deploy AKO" | tee -a ${output_file} >/dev/null 2>&1
  echo "  > helm install --generate-name $(jq -c -r .helm_url /nestedVsphere8/07_nsx_alb/variables.json) --version $(jq -c -r .avi.ako_version $jsonFile) -f path_values.yml --namespace=avi-system" | tee -a ${output_file} >/dev/null 2>&1
fi
#
# 12_tkgm
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_telco" ]]; then
  /bin/bash /nestedVsphere8/12_tkgm/apply.sh
  if [ $? -ne 0 ] ; then exit 1 ; fi
  #
  # Output TKGm (telco)
  #
  echo "" | tee -a ${output_file} >/dev/null 2>&1
  echo "+++++ TKGm" | tee -a ${output_file} >/dev/null 2>&1
  echo "To Access your TKG workload cluster from the external gw:" | tee -a ${output_file} >/dev/null 2>&1
  echo "  > tanzu cluster list" | tee -a ${output_file} >/dev/null 2>&1
  echo "  > tanzu cluster kubeconfig get $(jq -c -r .tkg.clusters.workloads[0].name $jsonFile) --admin" | tee -a ${output_file} >/dev/null 2>&1
  echo "  > kubectl config use-context $(jq -c -r .tkg.clusters.workloads[0].name $jsonFile)-admin@$(jq -c -r .tkg.clusters.workloads[0].name $jsonFile)" | tee -a ${output_file} >/dev/null 2>&1
  echo "To ssh your TKG cluster node(s):" | tee -a ${output_file} >/dev/null 2>&1
  echo "  > kubectl get nodes -o json | jq -r .items[].status.addresses[1].address" | tee -a ${output_file} >/dev/null 2>&1
  echo "  > ssh capv@ip_of_tanzu_node -i $(jq -c -r .tkg.clusters.public_key_path /root/tkgm.json)" | tee -a ${output_file} >/dev/null 2>&1
  echo "Add docker credential in your TKG cluster:" | tee -a ${output_file} >/dev/null 2>&1
  echo "  > kubectl create secret docker-registry docker --docker-server=docker.io --docker-username=${TF_VAR_docker_registry_username} --docker-password=****** --docker-email=${TF_VAR_docker_registry_email}" | tee -a ${output_file} >/dev/null 2>&1
  echo '  > kubectl patch serviceaccount default -p "{\"imagePullSecrets\": [{\"name\": \"docker\"}]}"' | tee -a ${output_file} >/dev/null 2>&1
  echo "Add avi-system name space:" | tee -a ${output_file} >/dev/null 2>&1
  echo "  > kubectl create ns avi-system" | tee -a ${output_file} >/dev/null 2>&1
  echo "Deploy AKO for your workload clusters:" | tee -a ${output_file} >/dev/null 2>&1
  echo "  > helm install --generate-name $(jq -c -r .helm_url /nestedVsphere8/07_nsx_alb/variables.json) --version $(jq -c -r .avi.ako_version $jsonFile) -f path_values.yml --namespace=avi-system" | tee -a ${output_file} >/dev/null 2>&1
  echo "Connect to the tier0 to check the routes" | tee -a ${output_file} >/dev/null 2>&1
  echo "  > get logical-routers" | tee -a ${output_file} >/dev/null 2>&1
  echo "  > vrf xxx" | tee -a ${output_file} >/dev/null 2>&1
  echo "  > get route" | tee -a ${output_file} >/dev/null 2>&1
fi
#
#if [[ $(jq -c -r .avi $jsonFile) != "null" &&  $(jq -c -r .nsx $jsonFile) != "null" &&  $(jq -c -r .vcd $jsonFile) != "null" && $(jq -c -r .avi.config.cloud.type $jsonFile) == "CLOUD_NSXT" ]]; then
#  /bin/bash /nestedVsphere8/13_vcd_appliance/apply.sh
##   if [ $? -ne 0 ] ; then exit 1 ; fi
#fi
echo ""
cat ${output_file}
#
# Transfer output to external-gw
#
echo ""
scp -o StrictHostKeyChecking=no ${output_file} ubuntu@$(jq -c -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile):/home/ubuntu/output.txt >/dev/null 2>&1
ssh -o StrictHostKeyChecking=no -t ubuntu@$(jq -c -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile) 'echo "cat /home/ubuntu/output.txt" | tee -a /home/ubuntu/.profile >/dev/null 2>&1' >/dev/null 2>&1
#
#
#
while true ; do sleep 3600 ; done