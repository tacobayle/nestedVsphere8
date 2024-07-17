load_govc () {
  unset GOVC_USERNAME
  unset GOVC_PASSWORD
  unset GOVC_DATACENTER
  unset GOVC_URL
  unset GOVC_DATASTORE
  unset GOVC_CLUSTER
  unset GOVC_INSECURE
  if [[ ${vcenter_domain} == "" ]] ; then
    export GOVC_USERNAME="${vsphere_username}"
  else
    export GOVC_USERNAME="${vsphere_username}@${vcenter_domain}"
  fi
  export GOVC_PASSWORD=${vsphere_password}
  export GOVC_DATACENTER=${vsphere_dc}
  export GOVC_DATASTORE=${vsphere_datastore}
  export GOVC_INSECURE=true
  export GOVC_URL=${vsphere_host}
  export GOVC_CLUSTER=${vsphere_cluster}
}

nextip(){
    IFS=$' \t\n'
    IP=$1
    IP_HEX=$(printf '%.2X%.2X%.2X%.2X\n' `echo $IP | sed -e 's/\./ /g'`)
    NEXT_IP_HEX=$(printf %.8X `echo $(( 0x$IP_HEX + 1 ))`)
    NEXT_IP=$(printf '%d.%d.%d.%d\n' `echo $NEXT_IP_HEX | sed -r 's/(..)/0x\1 /g'`)
    echo "$NEXT_IP"
    IFS=$'\n'
}