#!/bin/bash
#
jsonFile="/home/ubuntu/vsphere_with_tanzu.json"
#
IFS=$'\n'
#
source /nestedVsphere8/bash/vcenter_api.sh
#
api_host="${1}"
vsphere_nested_username=administrator
vcenter_domain="${2}"
kubectl_password="${3}"
api_server_cluster_endpoint="${4}"
name="${5}"
#
# YAML file copying
#
export KUBECTL_VSPHERE_PASSWORD=${kubectl_password}
#
contents=$(cat /home/ubuntu/.profile | grep -v "/home/ubuntu/bin/kubectl")
echo "${contents}" | tee /home/ubuntu/.profile > /dev/null
contents="alias k=/home/ubuntu/bin/kubectl"
echo "${contents}" | tee -a /home/ubuntu/.profile > /dev/null
#
/home/ubuntu/bin/kubectl-vsphere login --insecure-skip-tls-verify --vsphere-username ${vsphere_nested_username}@${vcenter_domain} --server=https://${api_server_cluster_endpoint}
/home/ubuntu/bin/kubectl config use-context ${namespace_ref}

/home/ubuntu/bin/kubectl apply -f /home/ubuntu/tkc/tkc-$${tkc_count}.yml
tkc_count=1
#
for tkc in $(jq -c -r .tanzu.tkc_clusters[] $jsonFile)
do
  /home/ubuntu/bin/kubectl config use-context ${namespace}
#  echo "Wait for 60 seconds..."
#  sleep 60
  /home/ubuntu/bin/kubectl apply -f /home/ubuntu/tkc/tkc-$${tkc_count}.yml
#  echo "waiting 5 minutes"
#  sleep 300
#  retry_tkc=61
#  pause_tkc=120
#  attempt_tkc=1
#  while true ; do
#    echo "attempt: $attempt_tkc // tkc cluster called $(echo $tkc | jq -c -r .name) .status.phase is :  $(/home/ubuntu/bin/kubectl get tanzukubernetesclusters $(echo $tkc | jq -c -r .name) -o json | jq .status.phase)"
#    if [[ $(/home/ubuntu/bin/kubectl get tanzukubernetesclusters $(echo $tkc | jq -c -r .name) -o json | jq -r .status.phase) == "running" ]]; then
#      /home/ubuntu/bin/kubectl-vsphere login --insecure-skip-tls-verify --vsphere-username administrator@${sso_domain_name} --server=https://$(jq -c -r .api_server_cluster_endpoint /home/ubuntu/tanzu/api_server_cluster_endpoint.json) --tanzu-kubernetes-cluster-namespace $(echo $tkc | jq -c -r .namespace_ref) --tanzu-kubernetes-cluster-name $(echo $tkc | jq -c -r .name)
#      /home/ubuntu/bin/kubectl config use-context $(echo $tkc | jq -c -r .name)
#      /home/ubuntu/bin/kubectl create secret docker-registry docker --docker-server=docker.io --docker-username=${docker_registry_username} --docker-password=${docker_registry_password} --docker-email=${docker_registry_email}
#      /home/ubuntu/bin/kubectl patch serviceaccount default -p "{\"imagePullSecrets\": [{\"name\": \"docker\"}]}"
#      /home/ubuntu/bin/kubectl create clusterrolebinding default-tkg-admin-privileged-binding --clusterrole=psp:vmware-system-privileged --group=system:authenticated
#      break
#    fi
#    ((attempt_tkc++))
#    if [ $attempt_tkc -eq $retry_tkc ]; then
#      echo "Timeout after $attempt_tkc attempts"
#      exit 255
#    fi
#    sleep $pause_tkc
#  done
#  ((tkc_count++))
done