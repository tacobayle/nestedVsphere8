#!/bin/bash
#
jsonFile="/home/ubuntu/tanzu_wo_nsx.json"
#
IFS=$'\n'
#
for tkc in $(jq -c -r .tanzu.tkc_clusters[] $jsonFile)
do
  /home/ubuntu/bin/kubectl config use-context $(echo $tkc | jq -c -r .namespace_ref)
  /home/ubuntu/bin/kubectl delete tanzukubernetesclusters $(echo $tkc | jq -c -r .name)
done