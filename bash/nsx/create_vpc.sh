#!/bin/bash
#
source /nestedVsphere8/bash/nsx/nsx_api.sh
#
nsx_nested_ip=${1}
nsx_password=${2}
project_name=${3}
vpc_name=${4}
edge_cluster_path=${5}
tier0_path=${6}
external_ipv4_block=${7}
private_ipv4_block=${8}
dns_ip=${9}
#
cookies_file="/root/nsx_$(basename $0 | cut -d"." -f1)_cookie.txt"
headers_file="/root/nsx_$(basename $0 | cut -d"." -f1)_header.txt"
rm -f $cookies_file $headers_file
/bin/bash /nestedVsphere8/bash/nsx/create_nsx_api_session.sh admin $nsx_password $nsx_nested_ip $cookies_file $headers_file
#
json_data='
  {
    "service_gateway": {
      "disable": false,
      "auto_snat": true
    },
    "default_gateway_path": "'${tier0_path}'",
    "site_infos": [
      {
        "edge_cluster_paths": [
          "'${edge_cluster_path}'"
        ],
        "site_path": "/infra/sites/default"
      }
    ],
    "load_balancer_vpc_endpoint": {
      "enabled": true
    },
    "external_ipv4_blocks": [
      "'${external_ipv4_block}'"
    ],
    "private_ipv4_blocks": [
      "'${private_ipv4_block}'"
    ],
    "ip_address_type": "IPV4",
    "ipv6_profile_paths": [],
    "subnet_profiles": {},
    "dhcp_config": {
      "enable_dhcp": true,
      "dns_client_config": {
        "dns_server_ips": [
          "'${dns_ip}'"
        ]
      }
    },
    "display_name": "'${vpc_name}'"
  }'
#
nsx_api 2 2 "PATCH" $cookies_file $headers_file "${json_data}" $nsx_nested_ip "policy/api/v1/orgs/default/projects/${project_name}/vpcs/${vpc_name}"
#
json_data='
  {
    "ipv4_subnet_size": 32,
    "access_mode": "Private",
    "display_name": "'${vpc_name}'-subnet"
  }'
#
nsx_api 2 2 "PATCH" $cookies_file $headers_file "${json_data}" $nsx_nested_ip "policy/api/v1/orgs/default/projects/${project_name}/vpcs/${vpc_name}/subnets/subnet-1"