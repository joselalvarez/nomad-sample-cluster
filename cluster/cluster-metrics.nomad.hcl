variable "grafana_expose_port" {
    type = string
}

job "cluster-metrics" {

    datacenters = ["dc1"]

    group "grafana-ingress" {
        network {
            mode = "bridge"
            port "http" {
               static = var.grafana_expose_port
            }
        }

        service {
            name = "grafana-ingress"
            port = var.grafana_expose_port
            connect {
                gateway {
                    ingress {
                        listener {
                            port = var.grafana_expose_port
                            protocol = "tcp"
                            service {
                                name = "grafana"
                            }
                        }
                    }
                }
            }
        }
    }

    group "prometheus" {

        network {
            mode = "bridge"
            port "http" {
                to = 9090
            }
        }

        service {
            name = "prometheus"
            port = 9090
            connect {
                sidecar_service {}
                sidecar_task {
                    resources {
                        cpu    = 50
                        memory = 128
                    }
                }
            }
        }

        volume "prometheus" {
            type = "host"
            read_only = false
            source = "prometheus-vol"
        }

        task "app" {

            driver = "docker"

            user = 1000

            template {
                data = file("./prometheus.yml.tpl")
                destination = "prometheus.yml"
            }

            config {
                image = "prom/prometheus:v2.40.5"
                ports = ["http"]
                volumes = ["prometheus.yml:/etc/prometheus/prometheus.yml"]
            }

            volume_mount {
                volume = "prometheus"
                destination = "/prometheus"
                read_only = false
            }

            resources {
                cpu = 100
                memory = 256
            }
        } 
    }

    group "grafana" {

        network {
            mode = "bridge"
            port "http" {
                to = 3000
            }
        }

        service {
            name = "grafana"
            port = 3000

            connect {
                sidecar_service {
                    proxy {
                        upstreams {
                            destination_name = "prometheus"
                            local_bind_port  = 9090
                        }
                    }
                }
                sidecar_task {
                    resources {
                        cpu    = 50
                        memory = 128
                    }
                }
            }
        }

        volume "grafana" {
            type = "host"
            read_only = false
            source = "grafana-vol"
        }

        task "app" {
        
            driver = "docker"

            user = 472
            
            template {
                data = file("./grafana-datasource.yml.tpl")
                destination = "grafana-datasource.yml"
            }

            template {
                data = file("./grafana-dashboard-provider.yml.tpl")
                destination = "grafana-dashboard-provider.yml"
            }

            template {
                data = file("./grafana-dashboard-prototype-service.json.tpl")
                destination = "grafana-dashboard-prototype-service.json"
            }

            template {
                data = file("./grafana.ini.tpl")
                destination = "grafana.ini"
            }

            config {
                image = "grafana/grafana:9.3.1"
                ports = ["http"]
                volumes = [
                    "grafana-datasource.yml:/etc/grafana/provisioning/datasources/datasource.yml", 
                    "grafana-dashboard-provider.yml:/etc/grafana/provisioning/dashboards/provider.yml", 
                    "grafana-dashboard-prototype-service.json:/etc/dashboards/Services/prototype-service.json",
                    "grafana.ini:/etc/grafana/grafana.ini"
                ]
            }

            volume_mount {
                volume = "grafana"
                destination = "/var/lib/grafana"
                read_only = false
            }

            resources {
                cpu = 500
                memory = 256
            }
        }
    }
}