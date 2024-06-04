load_govc_esxi () {
  export GOVC_USERNAME="root"
  export GOVC_PASSWORD=$TF_VAR_nested_esxi_root_password
  export GOVC_INSECURE=true
  unset GOVC_DATACENTER
  unset GOVC_CLUSTER
  unset GOVC_URL
}

load_govc_env_with_cluster () {
  export GOVC_USERNAME="$vsphere_nested_username@$vcenter_domain"
  export GOVC_USERNAME="$vsphere_nested_username@$vcenter_domain"
  export GOVC_PASSWORD=$vsphere_nested_password
  export GOVC_DATACENTER=$(jq -r .vsphere_nested.datacenter $jsonFile)
  export GOVC_INSECURE=true
  export GOVC_CLUSTER=$1
  export GOVC_URL=$api_host
}

load_govc_env_wo_cluster () {
  export GOVC_USERNAME="$vsphere_nested_username@$vcenter_domain"
  export GOVC_PASSWORD=$vsphere_nested_password
  export GOVC_DATACENTER=$(jq -r .vsphere_nested.datacenter $jsonFile)
  export GOVC_INSECURE=true
  export GOVC_URL=$api_host
  unset GOVC_CLUSTER
}

load_govc_env () {
  unset GOVC_USERNAME
  unset GOVC_PASSWORD
  unset GOVC_DATACENTER
  unset GOVC_URL
  unset GOVC_CLUSTER
  unset GOVC_INSECURE
  if [[ ${vcenter_domain} == "" ]] ; then
    export GOVC_USERNAME="${vsphere_username}"
  else
    export GOVC_USERNAME="${vsphere_username}@${vcenter_domain}"
  fi
  export GOVC_PASSWORD=${vsphere_password}
  export GOVC_DATACENTER=${vsphere_dc}
  export GOVC_INSECURE=true
  export GOVC_URL=${vsphere_host}
  export GOVC_CLUSTER=${vsphere_cluster}
}
