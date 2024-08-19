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
#
# crd - update fqdn
#
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
echo "---" | tee -a /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-http-crds.yml
cat /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-http-crd-2.yml | tee -a /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-http-crds.yml
echo "---" | tee -a /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-http-crds.yml
cat /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-http-crd-3.yml | tee -a /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-http-crds.yml
rm /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-http-crd-1.yml > /dev/null
rm /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-http-crd-2.yml > /dev/null
rm /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-http-crd-3.yml > /dev/null
#
# gw - domain update and cert update
#
gw=$(yq . /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-gw.yml)
gw=$(echo ${gw} | jq '. | del (.spec.listeners[0].hostname)')
gw=$(echo ${gw} | jq '. | del (.spec.listeners[1].hostname)')
gw=$(echo ${gw} | jq '.spec.listeners[0] += {"hostname": "*.'${domain}'"}')
gw=$(echo ${gw} | jq '.spec.listeners[1] += {"hostname": "*.'${domain}'"}')
echo ${gw} | yq -y . | tee /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-gw.yml > /dev/null
#
# gw http routes update
#
route=$(yq . /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-gw-http-route-1.yml)
route=$(echo ${route} | jq '. | del (.spec.hostnames)')
route=$(echo ${route} | jq '.spec += {"hostnames": ["v1.'"${domain}"'"]}')
echo ${route} | yq -y . | tee /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-gw-http-route-1.yml > /dev/null
route=$(echo ${route} | jq '. | del (.spec.hostnames)')
route=$(echo ${route} | jq '.spec += {"hostnames": ["v2.'"${domain}"'"]}')
route=$(yq . /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-gw-http-route-2.yml)
echo ${route} | yq -y . | tee /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-gw-http-route-2.yml > /dev/null
route=$(yq . /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-gw-http-route-3.yml)
route=$(echo ${route} | jq '. | del (.spec.hostnames)')
route=$(echo ${route} | jq '.spec += {"hostnames": ["v3.'"${domain}"'"]}')
echo ${route} | yq -y . | tee /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-gw-http-route-3.yml > /dev/null
#
cat /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-gw-http-route-1.yml | tee /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-gw-http-routes.yml
echo "---" | tee -a /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-gw-http-routes.yml
cat /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-gw-http-route-2.yml | tee -a /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-gw-http-routes.yml
echo "---" | tee -a /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-gw-http-routes.yml
cat /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-gw-http-route-3.yml | tee -a /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-gw-http-routes.yml
rm /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-gw-http-route-1.yml > /dev/null
rm /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-gw-http-route-2.yml > /dev/null
rm /home/ubuntu/$(jq -c -r .yaml_directory $jsonFile)/demo-gw-http-route-3.yml > /dev/null
