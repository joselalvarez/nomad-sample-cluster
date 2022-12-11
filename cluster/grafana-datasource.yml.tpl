apiVersion: 1

datasources:
- name: prometheusdata
  type: prometheus
  access: browser
  orgId: 1
  url: http://{{ env "NOMAD_UPSTREAM_ADDR_prometheus"}}
  isDefault: true
  version: 1
  editable: false