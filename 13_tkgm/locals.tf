locals {
  avi_control_plane_network_cidr = join(", ", [for segment in var.nsx.config.segments_overlay: segment.cidr if segment.display_name == var.tkg.clusters.management.avi_control_plane_network])
  avi_data_network_cidr = join(", ", [for segment in var.nsx.config.segments_overlay: segment.cidr if segment.display_name == var.tkg.clusters.management.avi_data_network])
  avi_mgmt_cluster_control_plane_vip_network_cidr = join(", ", [for segment in var.nsx.config.segments_overlay: segment.cidr if segment.display_name == var.tkg.clusters.management.avi_mgmt_cluster_control_plane_vip_network_name])
  avi_mgmt_cluster_vip_network_cidr = join(", ", [for segment in var.nsx.config.segments_overlay: segment.cidr if segment.display_name == var.tkg.clusters.management.avi_mgmt_cluster_vip_network_name])
}