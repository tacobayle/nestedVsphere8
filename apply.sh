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
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_telco" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_vcd" || $(jq -c -r .deployment $jsonFile) == "vsphere_alb_wo_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_tanzu_alb_wo_nsx" ]]; then
  /bin/bash /nestedVsphere8/00_pre_check/04.sh
   if [ $? -ne 0 ] ; then exit 1 ; fi
fi
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_telco" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_vcd" ]]; then
  /bin/bash /nestedVsphere8/00_pre_check/05.sh
   if [ $? -ne 0 ] ; then exit 1 ; fi
fi
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_alb_wo_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_tanzu_alb_wo_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_telco" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_vcd" ]]; then
  /bin/bash /nestedVsphere8/00_pre_check/07.sh
   if [ $? -ne 0 ] ; then exit 1 ; fi
fi
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_alb_wo_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_tanzu_alb_wo_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_vcd" ]]; then
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
/bin/bash /nestedVsphere8/02_external_gateway/apply.sh
if [ $? -ne 0 ] ; then exit 1 ; fi
#
/bin/bash /nestedVsphere8/03_nested_vsphere/apply.sh
if [ $? -ne 0 ] ; then exit 1 ; fi
echo "waiting for 20 minutes to finish the vCenter config..."
sleep 1200
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_telco" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_vcd" || $(jq -c -r .deployment $jsonFile) == "vsphere_alb_wo_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_tanzu_alb_wo_nsx" ]]; then
  /bin/bash /nestedVsphere8/04_networks/apply.sh
   if [ $? -ne 0 ] ; then exit 1 ; fi
fi
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_telco" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_vcd" ]]; then
  /bin/bash /nestedVsphere8/05_nsx_manager/apply.sh
  if [ $? -ne 0 ] ; then exit 1 ; fi
  echo "waiting for 5 minutes to finish the NSX bootstrap..."
  sleep 300
fi
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_telco" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_vcd" ]]; then
  /bin/bash /nestedVsphere8/06_nsx_config/apply.sh
  if [ $? -ne 0 ] ; then exit 1 ; fi
fi
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_alb_wo_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_tanzu_alb_wo_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_telco" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_vcd" ]]; then
  /bin/bash /nestedVsphere8/07_nsx_alb/apply.sh
   if [ $? -ne 0 ] ; then exit 1 ; fi
fi
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_alb_wo_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_tanzu_alb_wo_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_vcd" ]]; then
  /bin/bash /nestedVsphere8/08_app/apply.sh
   if [ $? -ne 0 ] ; then exit 1 ; fi
fi
#
if [[ $(jq -c -r .unmanaged_k8s_status $jsonFile) == true ]]; then
  /bin/bash /nestedVsphere8/09_unmanaged_k8s_clusters/apply.sh
   if [ $? -ne 0 ] ; then exit 1 ; fi
fi
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_alb_wo_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_tanzu_alb_wo_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_telco" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_vcd" ]]; then
  /bin/bash /nestedVsphere8/10_nsx_alb_config/apply.sh
  if [ $? -ne 0 ] ; then exit 1 ; fi
fi
#
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_tanzu_alb_wo_nsx" ]]; then
  /bin/bash /nestedVsphere8/11_vsphere_with_tanzu/apply.sh
  if [ $? -ne 0 ] ; then exit 1 ; fi
fi
#
#if [[ $(jq -c -r .avi $jsonFile) != "null" &&  $(jq -c -r .nsx $jsonFile) != "null" &&  $(jq -c -r .vcd $jsonFile) != "null" && $(jq -c -r .avi.config.cloud.type $jsonFile) == "CLOUD_NSXT" ]]; then
#  /bin/bash /nestedVsphere8/13_vcd_appliance/apply.sh
##   if [ $? -ne 0 ] ; then exit 1 ; fi
#fi
#
# outputs
#
rm -f /root/output.txt
echo ""
echo ""
echo "+++++++++++++++++ O U T P U T S +++++++++++++++++++++" | tee /root/output.txt
echo ""
echo "+++++++ external-gateway" | tee -a /root/output.txt
echo "ssh your external gateway from the pod:" | tee -a /root/output.txt
echo "  > ssh -o StrictHostKeyChecking=no ubuntu@external-gw" | tee -a /root/output.txt
echo "ssh your external gateway from an external node:" | tee -a /root/output.txt
echo "  > ssh -o StrictHostKeyChecking=no ubuntu@$(jq -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile)" | tee -a /root/output.txt
echo ""
echo "++++++++++++++++ vSphere" | tee -a /root/output.txt
echo "Configure your /etc/hosts with the following entry:" | tee -a /root/output.txt
echo "  > $(jq -r .vsphere_underlay.networks.vsphere.management.vcsa_nested_ip $jsonFile) $(jq -r .vsphere_nested.vcsa_name $jsonFile).$(jq -r .external_gw.bind.domain $jsonFile)" | tee -a /root/output.txt
echo "vSphere server url: https://$(jq -r .vsphere_nested.vcsa_name $jsonFile).$(jq -r .external_gw.bind.domain $jsonFile)" | tee -a /root/output.txt
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_telco" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_vcd" ]]; then
  echo ""
  echo "++++++++++++++++++++ NSX" | tee -a /root/output.txt
  echo "  > NSX manager url: https://$(jq -r .vsphere_underlay.networks.vsphere.management.nsx_nested_ip $jsonFile)" | tee -a /root/output.txt
fi
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_alb_wo_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_tanzu_alb_wo_nsx" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_telco" || $(jq -c -r .deployment $jsonFile) == "vsphere_nsx_alb_vcd" ]]; then
  echo ""
  echo "++++++++++++++++ NSX-ALB" | tee -a /root/output.txt
  echo "  > NSX ALB controller url: https://$(jq -r .vsphere_underlay.networks.vsphere.management.avi_nested_ip $jsonFile)" | tee -a /root/output.txt
fi
if [[ $(jq -c -r .deployment $jsonFile) == "vsphere_tanzu_alb_wo_nsx" ]]; then
  echo ""
  echo "+++++ vSphere with Tanzu" | tee -a /root/output.txt
  echo "Authenticate to the supervisor cluster from the external-gateway:" | tee -a /root/output.txt
  echo "  > /bin/bash /home/ubuntu/tanzu/auth_supervisor.sh" | tee -a /root/output.txt
  echo "Authenticate to a specific tkc cluster from the external-gateway:" | tee -a /root/output.txt
  echo "  > /bin/bash /home/ubuntu/tkc/auth-tkc-*.sh" | tee -a /root/output.txt
  echo "Add docker credential in yur tkc cluster:" | tee -a /root/output.txt
  echo "  > /home/ubuntu/bin/kubectl create secret docker-registry docker --docker-server=docker.io --docker-username=${TF_VAR_docker_registry_username} --docker-password=****** --docker-email=${TF_VAR_docker_registry_email}" | tee -a /root/output.txt
  echo '  > /home/ubuntu/bin/kubectl patch serviceaccount default -p "{\"imagePullSecrets\": [{\"name\": \"docker\"}]}"' | tee -a /root/output.txt
  echo "Enable deployment creation:" | tee -a /root/output.txt
  echo "  > /home/ubuntu/bin/kubectl create clusterrolebinding default-tkg-admin-privileged-binding --clusterrole=psp:vmware-system-privileged --group=system:authenticated" | tee -a /root/output.txt
fi
#echo "  - configure $(jq -c -r .vcenter.dvs.portgroup.management.external_gw_ip $jsonFile) as a socks proxy" | tee -a /root/output.txt
#echo "  - Avi url: https://$(jq -c -r .avi.controller.cidr avi.json | cut -d'/' -f1 | cut -d'.' -f1-3).$(jq -c -r .avi.controller.ip avi.json)" | tee -a /root/output.txt
#echo "To Access your TKG cluster:" | tee -a /root/output.txt
#echo '  - tanzu cluster list' | tee -a /root/output.txt
#echo "  - tanzu cluster kubeconfig get $(jq -c -r .tkg.clusters.workloads[0].name $jsonFile) --admin" | tee -a /root/output.txt
#echo "  - kubectl config use-context $(jq -c -r .tkg.clusters.workloads[0].name $jsonFile)-admin@$(jq -c -r .tkg.clusters.workloads[0].name $jsonFile)" | tee -a /root/output.txt
#echo "To ssh your TKG cluster node(s):" | tee -a /root/output.txt
#echo "  - kubectl get nodes -o json | jq -r .items[].status.addresses[1].address" | tee -a /root/output.txt
#echo "  - ssh capv@ip_of_tanzu_node -i $(jq -c -r .tkg.clusters.workloads[0].public_key_path $jsonFile)" | tee -a /root/output.txt
#echo "To Add Docker registry Account to your TKG cluster:" | tee -a /root/output.txt
#echo '  - kubectl create secret docker-registry docker --docker-server=docker.io --docker-username=******** --docker-password=******** --docker-email=********' | tee -a /root/output.txt
#echo '  - kubectl patch serviceaccount default -p "{\"imagePullSecrets\": [{\"name\": \"docker\"}]}"' | tee -a /root/output.txt
#echo "Avi/NSX: Configure BGP sessions between tier0s and service Engines" | tee -a /root/output.txt
#for network in $(jq -c -r .avi.config.cloud.networks[] $jsonFile)
#do
#  if [[ $(echo $network | jq -c -r .name) == $(echo $(jq -c -r .vcenter.dvs.portgroup.nsx_external.name $jsonFile)-pg) ]] ; then
#    echo "  - pool of IP used by Service Engines: $(echo $network | jq -c -r .avi_ipam_pool)" | tee -a /root/output.txt
#  fi
#done
#echo "  - IPs used by tier0 interfaces: $(jq -c -r '.vcenter.dvs.portgroup.nsx_external.tier0_ips' $jsonFile)" | tee -a /root/output.txt
#echo "Avi: Configure the following subnets on the top the network called $(jq -r .vcenter.dvs.portgroup.nsx_external.name $jsonFile)-pg" | tee -a /root/output.txt
#for network in $(jq -c -r .avi.config.cloud.additional_subnets[] $jsonFile)
#do
#  if [[ $(echo $network | jq -c -r .name_ref) == $(echo $(jq -c -r .vcenter.dvs.portgroup.nsx_external.name $jsonFile)-pg) ]] ; then
#    for subnet in $(echo $network | jq -c -r '.subnets[]')
#    do
#      echo "  - $(echo $subnet | jq -c -r .cidr)" | tee -a /root/output.txt
#    done
#  fi
#done
#echo "To Add avi-system name space:" | tee -a /root/output.txt
#echo "  - kubectl create ns avi-system" | tee -a /root/output.txt
#echo "AKO with ClusterIp requires a dedicated Service Engine Group per K8s workload cluster: The current deployment has created only one Service Engine Group" | tee -a /root/output.txt
#echo "To Add AKO leveraging helm Install (from the external-gw):" | tee -a /root/output.txt
#echo "  - helm --debug install ako/ako --generate-name --version $(jq -c -r .tkg.clusters.ako_version $jsonFile) -f path-to-values.yml --namespace=avi-system" | tee -a /root/output.txt
#echo "Create InfraSetting CRD (from the external-gw):" | tee -a /root/output.txt
#echo "  - kubectl apply -f avi-infra-settings-workload-vrf-X.yml" | tee -a /root/output.txt
#echo "Create CNF/App (from the external-gw):" | tee -a /root/output.txt
#echo "  - kubectl apply -f k8s-deployment-X.yml" | tee -a /root/output.txt
#echo "Create svc (from the external-gw):" | tee -a /root/output.txt
#echo "  - kubectl apply -f k8s-svc-X.yml" | tee -a /root/output.txt
#echo "Connect to the tier0 to check the routes" | tee -a /root/output.txt
#echo "  - get logical-routers" | tee -a /root/output.txt
#echo "  - vrf xxx" | tee -a /root/output.txt
#echo "  - get route" | tee -a /root/output.txt

while true ; do sleep 3600 ; done