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