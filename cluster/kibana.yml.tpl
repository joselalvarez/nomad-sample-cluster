server.host: "0.0.0.0"
xpack.monitoring.ui.container.elasticsearch.enabled: true
server.name: "my-kibana"

# The URLs of the Elasticsearch instances to use for all your queries.
elasticsearch.hosts: ["http://{{ env "NOMAD_UPSTREAM_ADDR_elasticsearch"}}"]
