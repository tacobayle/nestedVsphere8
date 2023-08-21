# nestedVsphere8

## Goal

This Infrastructure as code will deploy a nested ESXi/vCenter environment (on the top of vCenter environment which does not support 802.1q or vlan tagged).
Several deployments/scenarios are supported:
- vsphere deploys a nested vsphere environment
- vsphere-alb deploys a nested vsphere with and NSX ALB on the top
- vsphere-nsx deploys a nested vsphere included NSX (overlay use case)
- vsphere-nsx-alb deploys a nested vsphere included NSX (overlay use case) and NSX ALB on the top

## shared resources regardless of the deployments/scenarios

### VM(s)

On the top of an underlay/outer vCenter environment, this repo will create the following:

![img.png](imgs/img01.png)
