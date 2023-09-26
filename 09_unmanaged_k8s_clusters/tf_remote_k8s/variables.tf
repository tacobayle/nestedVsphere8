variable "vsphere_nested" {}
variable "external_gw" {}
variable "vsphere_underlay" {}
variable "vsphere_nested_password" {}
variable "ubuntu_ova_path" {}
variable "ubuntu_password" {}
variable "docker_registry_username" {}
variable "docker_registry_password" {}
variable "docker_registry_email" {}
variable "deployment" {}
variable "avi" {}
variable "avi_password" {}
#
variable "unmanaged_k8s_clusters_nodes" {}
variable "unmanaged_k8s_masters_ips" {}
variable "unmanaged_k8s_masters_segments" {}
variable "unmanaged_k8s_masters_cidr" {}
variable "unmanaged_k8s_masters_gw" {}
variable "unmanaged_k8s_masters_cluster_name" {}
variable "unmanaged_k8s_masters_version" {}
variable "unmanaged_k8s_masters_cni" {}
variable "unmanaged_k8s_masters_cni_version" {}
variable "unmanaged_k8s_masters_ako_disableStaticRouteSync" {}
variable "unmanaged_k8s_masters_ako_serviceType" {}
variable "unmanaged_k8s_masters_vip_networks" {}
#
variable "unmanaged_k8s_workers_count" {}
variable "unmanaged_k8s_workers_associated_master_ips" {}
variable "unmanaged_k8s_workers_ips" {}
variable "unmanaged_k8s_workers_cidr" {}
variable "unmanaged_k8s_workers_gw" {}
variable "unmanaged_k8s_workers_cluster_name" {}
variable "unmanaged_k8s_workers_segments" {}
variable "unmanaged_k8s_workers_version" {}
variable "unmanaged_k8s_workers_cni" {}
variable "unmanaged_k8s_workers_cni_version" {}
#
variable "k8s" {}
