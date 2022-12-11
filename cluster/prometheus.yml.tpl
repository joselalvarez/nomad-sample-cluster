global:
    scrape_interval: 15s 
    evaluation_interval: 15s

scrape_configs:
    - job_name: 'prometheus'
      static_configs:
        - targets: ['{{ env "NOMAD_ADDR_http" }}']
    - job_name: 'consul-services'
      consul_sd_configs:
        - server: '{{ env "NOMAD_IP_http" }}:8500'
        - services: ['prototype']
      relabel_configs:
        - source_labels: [__meta_consul_service_metadata_sidecar_expose_addr]
          replacement: '$1'
          target_label: __address__