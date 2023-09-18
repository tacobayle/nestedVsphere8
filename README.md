# nestedVsphere8

## Goal

This Infrastructure as code will deploy a nested ESXi/vCenter environment (on the top of vCenter environment which does not support 802.1q or vlan tagged).
Several deployments/scenarios are supported:
- vsphere_wo_nsx deploys a nested vSphere environment without NSX
- vsphere_alb_wo_nsx deploys a nested vSphere with and NSX ALB on the top
- vsphere_tanzu_alb_wo_nsx deploys a nested vSphere with Tanzu (VDS use case) and NSX ALB on the top
- vsphere_nsx deploys a nested vSphere included NSX (overlay use case)
- vsphere_nsx_alb deploys a nested vSphere included NSX (overlay use case) and NSX ALB on the top
- vsphere_nsx_alb_telco deploys a nested vSphere included NSX (overlay use case) and NSX ALB (vCenter Cloud) with BGP between Service Engines and tiers 0 - TKGm is included and configured on the top of this along with AKO

## How to consume this repo? - Prerequisites
The starting point to consume this repo is to have a K8s cluster to deploy the following:
- secrets
- config-map
- pod (it requires connectivity: to the Internet, to the web servers which contains the iso/ova files (defined in the config map) and to outer/underlay vSphere API)

Additionally, you need to have an external web server configured where the ISO/OVA files needed will be downloaded.

All the variables are stored in K8s secrets (mostly credentials) and in one configmap for non-sensitive variables.

Here are below the links of the yaml manifest (data model) file for the different deployments/scenarios:

### vsphere_wo_nsx
https://raw.githubusercontent.com/tacobayle/k8sYaml/master/nestedVsphere8/secrets-vsphere_wo_nsx.yml
https://raw.githubusercontent.com/tacobayle/k8sYaml/master/nestedVsphere8/cm-vsphere.yml
https://raw.githubusercontent.com/tacobayle/k8sYaml/master/nestedVsphere8/pod-vsphere.y

### vsphere_alb_wo_nsx
https://raw.githubusercontent.com/tacobayle/k8sYaml/master/nestedVsphere8/secrets-vsphere-alb.yml
https://raw.githubusercontent.com/tacobayle/k8sYaml/master/nestedVsphere8/cm-vsphere-alb.yml
https://raw.githubusercontent.com/tacobayle/k8sYaml/master/nestedVsphere8/pod-vsphere-alb.yml

### vsphere_tanzu_alb_wo_nsx
https://raw.githubusercontent.com/tacobayle/k8sYaml/master/nestedVsphere8/secrets-vsphere-tanzu-alb-wo-nsx.yml
https://raw.githubusercontent.com/tacobayle/k8sYaml/master/nestedVsphere8/cm-vsphere-tanzu-alb-wo-nsx.yml
https://raw.githubusercontent.com/tacobayle/k8sYaml/master/nestedVsphere8/pod-vsphere-tanzu-alb-wo-nsx.yml

### vsphere_nsx
https://raw.githubusercontent.com/tacobayle/k8sYaml/master/nestedVsphere8/secrets-vsphere-nsx.yml
https://raw.githubusercontent.com/tacobayle/k8sYaml/master/nestedVsphere8/cm-vsphere-nsx.yml
https://raw.githubusercontent.com/tacobayle/k8sYaml/master/nestedVsphere8/pod-vsphere-nsx.yml

### vsphere_nsx_alb
https://raw.githubusercontent.com/tacobayle/k8sYaml/master/nestedVsphere8/secrets-vsphere-nsx-alb.yml
https://raw.githubusercontent.com/tacobayle/k8sYaml/master/nestedVsphere8/cm-vsphere-nsx-alb.yml
https://raw.githubusercontent.com/tacobayle/k8sYaml/master/nestedVsphere8/pod-vsphere-nsx-alb.yml

### vsphere_nsx_alb_telco
https://raw.githubusercontent.com/tacobayle/k8sYaml/master/nestedVsphere8/secrets-vsphere-nsx-alb-telco.yml
https://raw.githubusercontent.com/tacobayle/k8sYaml/master/nestedVsphere8/cm-vsphere-nsx-alb-telco.yml
https://raw.githubusercontent.com/tacobayle/k8sYaml/master/nestedVsphere8/pod-vsphere-nsx-alb-telco.yml

### vsphere_nsx_tanzu_alb (under-dev)

### vsphere_nsx_alb_vcd (under-dev)

## Shared resources regardless of the deployments/scenarios

### VM(s)

On the top of an underlay/outer vSphere, this repo will create the following VMs:

![img.png](imgs/img01.png)

### Nested VM(s) connectivity

- if \.vsphere_underlay.networks_vsphere_dual_attached == false

![img.png](imgs/underlay_architecture.png)

- if \.vsphere_underlay.networks_vsphere_dual_attached == true

![img.png](imgs/underlay_architecture_dual_attached.png)

Regardless of the deployments/scenarios, all the other VM(s) will be deployed on the top of the nested environment.
Here are below a list of the VM(s) that will be deployed on the top of the nested environment:
- NSX manager
- NSX ALB controller
- Apps VM
- VM for unmanaged K8s clusters

Depending on the selected deployment/scenario, VMs deployed will vary. For example, all the scenarios/deployments "wo_nsx" will not include the NSX manager and its configuration.