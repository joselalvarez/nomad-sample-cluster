variable "kibana_expose_port" {
    type = number
}

job "cluster-efk" {
    
    datacenters = ["dc1"]

    group "kibana-ingress" {
        network {
            mode = "bridge"
            port "http" {
               static = var.kibana_expose_port
            }
        }

        service {
            name = "kibana-ingress"
            port = var.kibana_expose_port
            connect {
                gateway {
                    ingress {
                        listener {
                            port = var.kibana_expose_port
                            protocol = "tcp"
                            service {
                                name = "kibana"
                            }
                        }
                    }
                }
            }
        }
    }


    group "elasticsearch" {

        network {
            mode = "bridge"
            port "http" {
                to = 9200
            }
        }

        service {
            name = "elasticsearch"
            port = 9200
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

        volume "elasticsearch" {
            type = "host"
            read_only = false
            source = "elasticsearch-vol"
        }

        task "app" {

            driver = "docker"

            user = 1000
            
            env = {
                "discovery.type" = "single-node"
                "xpack.security.enabled" = false
                "logger.org.elasticsearch.discovery" = "DEBUG"
            }

            config {
                image = "elasticsearch:7.17.7"
                ports = ["http"]
            }

            volume_mount {
                volume = "elasticsearch"
                destination = "/usr/share/elasticsearch/data"
                read_only = false
            }

            resources {
                cpu = 500
                memory = 2048
            }
        }
    }

    group "fluentd" {

        network {
            mode = "bridge"
            port "http" {
                to = 24224
            }
        }

        service {
            name = "fluentd"
            port = "http"
            address_mode = "host"
            
            connect {
                sidecar_service {
                    proxy {
                        upstreams {
                            destination_name = "elasticsearch"
                            local_bind_port  = 9200
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

        task "app" {
            driver = "docker"

            user = 1000

            template {
                data = file("./fluent.conf.tpl")
                destination = "fluent.conf"
            }

            config {
                image = "fluentd:v1.12.0-els"
                ports = ["http"]
                volumes = ["fluent.conf:/fluentd/etc/fluent.conf"]
            }

            resources {
                cpu = 100
                memory = 256
            }
        }
    }

    group "kibana" {

        network {
            mode = "bridge"
            port "http" {
                to = 5601
            }
        }

        service {
            name = "kibana"
            port = 5601
            connect {
                sidecar_service {
                    proxy {
                        upstreams {
                            destination_name = "elasticsearch"
                            local_bind_port  = 9200
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

        volume "kibana" {
            type = "host"
            read_only = false
            source = "kibana-vol"
        }

        task "app" {
            driver = "docker"

            user = 1000

            template {
                data = file("./kibana.yml.tpl")
                destination = "kibana.yml"
            }

            config {
                image = "kibana:7.17.7"
                ports = ["kibana"]
                volumes = ["kibana.yml:/opt/kibana/config/kibana.yml"]
            }

            volume_mount {
                volume = "kibana"
                destination = "/usr/share/kibana/data"
                read_only = false
            }

            resources {
                cpu = 500
                memory = 1024
            }
        }
    }
}