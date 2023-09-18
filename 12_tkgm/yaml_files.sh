#!/bin/bash
#
IFS=$'\n'
#
jsonFile="/root/tkgm.json"
#
cluster_count=1
for cluster in $(jq -c -r .tkg.clusters.workloads[] $jsonFile)
do
  service_engine_group_name=$(echo $cluster | jq -c -r .name)
  vrf_count=1
  for vrf in $(jq -c -r .avi.config.cloud.contexts[0].routing_options[] $jsonFile)
  do
    networkName=$(jq -r .networks.nsx.nsx_external.port_group_name /nestedVsphere8/02_external_gateway/variables.json)
    peer_bgp_label=$(echo $vrf | jq -c -r .label)
    vip_network_cidr=$(jq -r --arg network_name "${networkName}" '.avi.config.cloud.additional_subnets[] | select(.name_ref == $network_name)' $jsonFile | jq -r --arg vrf_name "${peer_bgp_label}" '.subnets[] | select(.bgp_label == $vrf_name).cidr')
#
# AviInfraSetting
#
read -r -d '' infra_setting_yaml_data << EOM
apiVersion: ako.vmware.com/v1alpha1
kind: AviInfraSetting
metadata:
  name: infra-setting-${vrf_count}
spec:
  seGroup:
    name: ${service_engine_group_name}
  network:
    vipNetworks:
      - networkName: ${networkName}
        cidr: ${vip_network_cidr}
    enableRhi: true
    bgpPeerLabels:
      - ${peer_bgp_label}
  l7Settings:
    shardSize: MEDIUM
EOM
    echo "$infra_setting_yaml_data" | tee /root/infra-setting-cluster-${cluster_count}-vrf-${vrf_count}.yml > /dev/null
    scp -o StrictHostKeyChecking=no /root/infra-setting-cluster-${cluster_count}-vrf-${vrf_count}.yml ubuntu@$(jq -c -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile):/home/ubuntu/yaml-files/infra-setting-cluster-${cluster_count}-vrf-${vrf_count}.yml
#
# HTTP Services
#
read -r -d '' svc_yaml_data << EOM
apiVersion: v1
kind: Service
metadata:
  name: svc-vrf-${vrf_count}
  annotations:
    aviinfrasetting.ako.vmware.com/name: infra-setting-${vrf_count}
spec:
  type: LoadBalancer
  selector:
    app: cnf-${vrf_count}
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
EOM
    echo "$svc_yaml_data" | tee /root/svc-vrf-${vrf_count}.yml > /dev/null
    scp -o StrictHostKeyChecking=no /root/svc-vrf-${vrf_count}.yml ubuntu@$(jq -c -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile):/home/ubuntu/yaml-files/svc-vrf-${vrf_count}.yml
#
# CNFs
#
read -r -d '' cnf_yaml_data << EOM
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cnf-${vrf_count}
spec:
  replicas: 2
  selector:
    matchLabels:
      app: cnf-${vrf_count}
  template:
    metadata:
      name: cnf-${vrf_count}
      labels:
        app: cnf-${vrf_count}
    spec:
      containers:
        - name: cnf-${vrf_count}
          image: tacobayle/busybox-v1
          command: [ "sh", "-c"]
          args:
          - while true; do
              echo -e "HTTP/1.1 200 OK\n\n$(date)\nThis is my cnf-${vrf_count}\nNode is $(printenv MY_NODE_NAME)\nPod is $(printenv MY_POD_NAME)\nNamespace is $(printenv MY_POD_NAMESPACE)\nPod IP is $(printenv MY_POD_IP)\nPod Service account is $(printenv MY_POD_SERVICE_ACCOUNT)" | nc -l -p 80
            done
          env:
            - name: MY_NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
            - name: MY_POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: MY_POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            - name: MY_POD_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP
            - name: MY_POD_SERVICE_ACCOUNT
              valueFrom:
                fieldRef:
                  fieldPath: spec.serviceAccountName
      restartPolicy: Always
EOM
    echo "$cnf_yaml_data" | tee /root/cnf-vrf-${vrf_count}.yml > /dev/null
    scp -o StrictHostKeyChecking=no /root/cnf-vrf-${vrf_count}.yml ubuntu@$(jq -c -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile):/home/ubuntu/yaml-files/cnf-vrf-${vrf_count}.yml
    ((vrf_count++))
  done
  ((cluster_count++))
done