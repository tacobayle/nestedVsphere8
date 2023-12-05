```
ubuntu@external-gw-20231204183248:~$ more "/home/ubuntu/tkc/create-antrea-1.yml"
apiVersion: cni.tanzu.vmware.com/v1alpha1
kind: AntreaConfig
metadata:
  name: tenant-1
  namespace: tenant-1
spec:
  antrea:
    config:
      featureGates:
        AntreaProxy: true
        EndpointSlice: false
        AntreaPolicy: true
        FlowExporter: true
        Egress: true
        NodePortLocal: true
        AntreaTraceflow: true
        NetworkPolicyStats: true
```
```
ubuntu@external-gw-20231204183248:~$ more "/home/ubuntu/tkc/create-clusterbootstrap-1.yml"
apiVersion: run.tanzu.vmware.com/v1alpha3
kind: ClusterBootstrap
metadata:
  annotations:
    tkg.tanzu.vmware.com/add-missing-fields-from-tkr: v1.24.9---vmware.1-tkg.4
  name: tenant-1
  namespace: tenant-1
spec:
  cni:
    refName: antrea.tanzu.vmware.com.1.7.2+vmware.1-tkg.1-advanced
    valuesFrom:
      providerRef:
        apiGroup: cni.tanzu.vmware.com
        kind: AntreaConfig
        name: tenant-1
ubuntu@external-gw-20231204183248:~$
```
```
ubuntu@external-gw-20231204183248:~$ k apply -f "/home/ubuntu/tkc/create-clusterbootstrap-1.yml"
Warning: resource clusterbootstraps/tenant-1 is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
clusterbootstrap.run.tanzu.vmware.com/tenant-1 configured
ubuntu@external-gw-20231204183248:~$
```

