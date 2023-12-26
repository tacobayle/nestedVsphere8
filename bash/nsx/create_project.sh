#!/bin/bash
#
source /nestedVsphere8/bash/nsx/nsx_api.sh
#
nsx_nested_ip=${1}
nsx_password=${2}
project_name=${3}
edge_cluster_path=${4}
tier0_path=${5}
#
cookies_file="/root/nsx_$(basename $0 | cut -d"." -f1)_cookie.txt"
headers_file="/root/nsx_$(basename $0 | cut -d"." -f1)_header.txt"
rm -f $cookies_file $headers_file
/bin/bash /nestedVsphere8/bash/nsx/create_nsx_api_session.sh admin $nsx_password $nsx_nested_ip $cookies_file $headers_file
#
json_data='
    {
      "site_infos": [
        {
          "edge_cluster_paths": [
            "'${edge_cluster_path}'"
          ],
          "site_path": "/infra/sites/default"
        }
      ],
      "tier_0s": [
        "'${tier0_path}'"
      ],
      "display_name": "'${project_name}'"
    }'
nsx_api 6 10 "PATCH" $cookies_file $headers_file "${json_data}" $nsx_nested_ip "policy/api/v1/orgs/default/projects/${project_name}"
