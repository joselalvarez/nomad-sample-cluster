variable "api_expose_port" {
    type = string
}

job "cluster-api" {

    datacenters = ["dc1"]

    group "api-ingress" {
        network {
            mode = "bridge"
            port "http" {
               static = var.api_expose_port
            }
        }

        service {
            name = "api-ingress"
            port = var.api_expose_port
            connect {
                gateway {
                    ingress {
                        listener {
                            port = var.api_expose_port
                            protocol = "tcp"
                            service {
                                name = "api-gateway"
                            }
                        }
                    }
                }
            }
        }
    }

    group "api-gateway" {
        network {
            mode = "bridge"
            port "http" {
                to = 8080
            }
        }

        service {
            name = "api-gateway"
            port = 8080
            connect {
                sidecar_service {
                    proxy {
                        upstreams {
                            destination_name = "prototype"
                            local_bind_port  = 8001
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

            template {
                data = file("./krakend.json.tpl")
                destination = "krakend.json"
            }

            config {
                image = "devopsfaith/krakend:2.1.3"
                ports = ["http"]
                volumes = ["krakend.json:/etc/krakend/krakend.json"]
            }

            resources {
                cpu    = 100
                memory = 256
            }
        }
    }

    group "prototype" {
        count = 2

        network {
            mode = "bridge"
            port "http" {
                to = 8001
            }
            port "expose" {}
        }

        service {
            name = "prototype"
            port = 8001

            meta {
                sidecar_expose_addr = "${NOMAD_IP_expose}:${NOMAD_HOST_PORT_expose}"
            }

            connect {
                sidecar_service {
                    proxy {
                        expose {
                            path {
                                path = "/metrics"
                                protocol = "http"
                                local_path_port = 8001
                                listener_port = "expose"
                            }
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

            check {
                type = "http"
                name = "prototype-health"
                port = "http"
                path = "/health"
                interval = "20s"
                timeout = "5s"
            }
        }

        task "app" {
            driver = "docker"

            template {
                data = <<EOH
                FLUENT_ADDR={{with service "fluentd"}}{{with index . 0}}{{.Address}}:{{.Port}}{{end}}{{end}}
                EOH
                destination = "fluentd.env"
                env = true
            }

            config {
                image = "prototype-service:0.0.1"
                ports = ["http"]

                logging {
                    type = "fluentd"
                    config {
                        fluentd-address = "${FLUENT_ADDR}"
                        tag = "prototype-group"
                        fluentd-async = "true"
                    }
                }
            }

            resources {
                cpu    = 100
                memory = 128
            }
        }

    }

}