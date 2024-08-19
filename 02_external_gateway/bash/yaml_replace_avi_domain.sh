#!/bin/bash
#
jsonFile="/home/ubuntu/external_gw.json"
#
IFS=$'\n'
#
domain="$(jq -c -r '.avi_domain_prefix' $jsonFile).$(jq -c -r '.external_gw.bind.domain' $jsonFile)"
# ingress - update host
ingress=$(yq . /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-http-ingress.yml)
ingress=$(echo $ingress | jq '. | del (.spec.rules[0].host)')
ingress=$(echo $ingress | jq '.spec.rules[0] += {"host": "v1.'${domain}'"}')
ingress=$(echo $ingress | jq '. | del (.spec.rules[1].host)')
ingress=$(echo $ingress | jq '.spec.rules[1] += {"host": "v2.'${domain}'"}')
ingress=$(echo $ingress | jq '. | del (.spec.rules[2].host)')
ingress=$(echo $ingress | jq '.spec.rules[2] += {"host": "v3.'${domain}'"}')
echo $ingress | yq -y . | tee /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-http-ingress.yml > /dev/null
# crd - update fqdn
crd=$(yq . /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-http-crd-1.yml)
crd=$(echo $crd | jq '. | del (.spec.virtualhost.fqdn)')
crd=$(echo $crd | jq '.spec.virtualhost += {"fqdn": "v1.'${domain}'"}')
echo $crd | yq -y . | tee /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-http-crd-1.yml > /dev/null
#
crd=$(yq . /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-http-crd-2.yml)
crd=$(echo $crd | jq '. | del (.spec.virtualhost.fqdn)')
crd=$(echo $crd | jq '.spec.virtualhost += {"fqdn": "v2.'${domain}'"}')
echo $crd | yq -y . | tee /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-http-crd-2.yml > /dev/null
#
crd=$(yq . /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-http-crd-3.yml)
crd=$(echo $crd | jq '. | del (.spec.virtualhost.fqdn)')
crd=$(echo $crd | jq '.spec.virtualhost += {"fqdn": "v3.'${domain}'"}')
echo $crd | yq -y . | tee /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-http-crd-3.yml > /dev/null
#
cat /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-http-crd-1.yml | tee /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-http-crds.yml
echo "---" tee -a /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-http-crds.yml
cat /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-http-crd-2.yml | tee -a /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-http-crds.yml
echo "---" tee -a /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-http-crds.yml
cat /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-http-crd-3.yml | tee -a /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-http-crds.yml
rm /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-http-crd-1.yml > /dev/null
rm /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-http-crd-2.yml > /dev/null
rm /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-http-crd-3.yml > /dev/null