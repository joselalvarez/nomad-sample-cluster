provider "nomad" {
    address = "http://10.0.2.15:4646"
}

variable "api_expose_port" {
    type = number
    default = 80
}

variable "kibana_expose_port" {
    type = number
    default = 5601
}

variable "grafana_expose_port" {
    type = number
    default = 3000
}

resource "nomad_job" "cluster-api" {
    jobspec = file("cluster-api.nomad.hcl")
    hcl2 {
        enabled  = true
        allow_fs = true
        vars = {
            "api_expose_port" = var.api_expose_port
        }
    }
}

resource "nomad_job" "cluster-efk" {
    jobspec = file("cluster-efk.nomad.hcl")
    hcl2 {
        enabled  = true
        allow_fs = true
        vars = {
            "kibana_expose_port" = var.kibana_expose_port
        }
    }
}

resource "nomad_job" "cluster-metrics" {
    jobspec = file("cluster-metrics.nomad.hcl")
    hcl2 {
        enabled  = true
        allow_fs = true
        vars = {
            "grafana_expose_port" = var.grafana_expose_port
        }
    }
}