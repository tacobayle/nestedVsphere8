#!/bin/bash
jsonFile="/root/tkgm.json"
deployment=$(jq -c -r .deployment $jsonFile)
if [[ ${deployment} == "vsphere_nsx_alb_telco" ]]; then
  output_file="/root/output.txt"
  source /nestedVsphere8/bash/tf_init_apply.sh
  #
  tf_init_apply "Configuration TKGm - This should take around 120 minutes" /nestedVsphere8/13_tkgm /nestedVsphere8/log/13.stdout /nestedVsphere8/log/13.stderr $jsonFile
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
  echo "  > helm install --generate-name $(jq -c -r .helm_url /nestedVsphere8/07_nsx_alb/variables.json) --version ako_version -f path_values.yml --namespace=avi-system" | tee -a ${output_file} >/dev/null 2>&1
  echo "Connect to the tier0 to check the routes" | tee -a ${output_file} >/dev/null 2>&1
  echo "  > get logical-routers" | tee -a ${output_file} >/dev/null 2>&1
  echo "  > vrf xxx" | tee -a ${output_file} >/dev/null 2>&1
  echo "  > get route" | tee -a ${output_file} >/dev/null 2>&1
  #
  touch "/root/13_tkgm"
  if [ -z "${slack_webhook_url}" ] ; then echo "ignoring slack update" ; else curl -X POST -H 'Content-type: application/json' --data '{"text":"'$(date "+%Y-%m-%d,%H:%M:%S")', '${deployment}': 13_tkgm deployed"}' ${slack_webhook_url} >/dev/null 2>&1; fi
fi