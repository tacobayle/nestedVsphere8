#!/bin/bash
#
jsonFile="/home/ubuntu/external_gw.json"
#
IFS=$'\n'
#
domain="'$(jq -c -r '.avi_domain_prefix' $jsonFile)'.'$(jq -c -r '.external_gw.bind.domain' $jsonFile)'"
# ingress - update host
ingress=$(yq . /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-http-ingress.yml)
ingress=$(echo $ingress | jq '. | del (.spec.rules[0].host)')
ingress=$(echo $ingress | jq '.spec.rules[0] += {"host": "ingress.'${domain}'"}')
echo $ingress | yq -y . | tee /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-http-ingress.yml > /dev/null
# crd - update fqdn
crd=$(yq . /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-http-crds.yml)
crd=$(echo $crd | jq '. | del (.spec.virtualhost.fqdn)')
crd=$(echo $crd | jq '.spec.virtualhost += {"fqdn": "ingress.'${domain}'"}')
echo $crd | yq -y . | tee /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-http-crds.yml > /dev/null