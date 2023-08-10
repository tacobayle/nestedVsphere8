#!/bin/bash
avi_password='xxx'
echo $avi_password
#json_data=$(cat templates/supervisor_wo_nsx.json)
json_data='
{
  "cluster_proxy_config": {
    "proxy_settings_source": "VC_INHERITED"
  },
  "workload_ntp_servers":["10.41.134.210"],
  "image_storage":
  {
    "storage_policy":"aa6d5a82-1c88-45da-85d3-3d74b91a5bad"
  },
  "master_NTP_servers":["10.41.134.210"],
  "ephemeral_storage_policy":"aa6d5a82-1c88-45da-85d3-3d74b91a5bad",
  "service_cidr":
  {
    "address":"10.96.0.0",
    "prefix":23
  },
  "size_hint":"SMALL",
  "worker_DNS":["10.41.134.210"],
  "master_DNS":["10.41.134.210"],
  "network_provider":"VSPHERE_NETWORK",
  "master_storage_policy":"aa6d5a82-1c88-45da-85d3-3d74b91a5bad",
  "master_management_network":
  {
    "mode":"STATICRANGE","address_range":
  {
    "subnet_mask":"255.255.255.0",
    "starting_address":"10.0.120.21",
    "gateway":"10.0.120.1",
    "address_count":5
  },
    "network":"dvportgroup-42"
  },
  "load_balancer_config_spec": {
    "address_ranges": [],
    "avi_config_create_spec": {
      "certificate_authority_chain": "-----BEGIN CERTIFICATE-----\nMIIC0zCCAbugAwIBAgIUGy2UCuFMxDHIBm3LUqP2uKR9fqYwDQYJKoZIhvcNAQEL\nBQAwGTEXMBUGA1UEAwwOYWxiLmFsYjEyMy5jb20wHhcNMjMwODAzMTE0MDM5WhcN\nMjQwODAyMTE0MDM5WjAZMRcwFQYDVQQDDA5hbGIuYWxiMTIzLmNvbTCCASIwDQYJ\nKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMsSqEFCyEvu5IyU/v3+EjH27Onuc92L\n+c1/dBobRo/Hw5acvH/HOaPLSdsvr7qGX2k6Ep6v0DIyGby6TgwAXUNbPSR63g5U\nqH19YHr14nyk0cXEV8xdrvV3c8um1X2o0U7RB8PEf5eckFjqYiZHtH+4HPR4E7s5\nj2VHeDtzBddZ6x2ppK18A+N7IjVnYLgzS78xa0Pv75I4yr89QB1I7ehUSoGzoPMt\nxn6Lu7Lwz1OUF8uQYOQirOXU4uBTQLxosBhzgUlRD8MFoBvW+qTyo1RBHIhJAxVs\nHR3O6snjUk/nUOHkHPR6JIRDXVSrW6txUmNLFTkXKICrk4iKsOdwLj0CAwEAAaMT\nMBEwDwYDVR0RBAgwBocECimG1zANBgkqhkiG9w0BAQsFAAOCAQEABeBdK5h/MgxY\nIbawz4Lt4OSxcamxMNKeRYOKMQN8RgEyGTL0TRZC3wMntVDxpoXE1vlOxYJcmTMW\nvvdHb8ulHQY3Vx7OXzisK7hJ5l0ycJyJlvPvyIR3aYKON0BqBxdoWCPvUrfybj79\n0gJBbkX6TBMB3+CuFj+Re+KdOHxiFvkZn6COejg+ozgrlIb+zg/TSscibPvhUo9j\nLB5ohLrFmpmnOsWP8JNX+5kcSj8uGSeLcLlneDjN9++cuyWrqoAExXj/YXkdfh5i\nIh+40XKEUTOrkFKDZslCRMBsuu+EshM2guhDMgbKq/1VDsOdJimYWSI/G64Nq3bj\nGBujokotZQ==\n-----END CERTIFICATE-----",
      "password": "'${avi_password}'",
      "server": {
        "host": "10.41.134.215",
        "port": 443
      },
      "username": "admin"
    },
    "id": "avi",
    "provider": "AVI"
  },
  "Master_DNS_names":["tanzu.alb123.com"],
  "default_kubernetes_service_content_library":"42bf330d-26d7-4ead-994a-0997251e0d8e",
  "workload_networks_spec": {
    "supervisor_primary_workload_network": {
      "network": "backend-pg",
      "network_provider": "VSPHERE_NETWORK",
      "vsphere_network": {
        "address_ranges": [
          {
            "address": "10.0.118.51",
            "count": 19
          }
        ],
        "gateway": "10.0.118.1",
        "ip_assignment_mode": "STATICRANGE",
        "portgroup": "dvportgroup-44",
        "subnet_mask": "255.255.255.0"
      }
    }
  }
}
'
echo $json_data | jq .