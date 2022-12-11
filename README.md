# Implementación de microservicio *Rust* con *Actix web framework* y orquestación dentro de cluster *Nomad*

![Nomad cluster](https://raw.githubusercontent.com/joselalvarez/nomad-sample-cluster/main/_img/cluster.png)

El proyecto incluye los siguientes componentes:

- Prototipo de Microservicio escrito en *Rust* usando el *framework* [Actix web](https://actix.rs) con las siguientes características:
    - Configuración del microservicio estilo *Spring Boot* con fichero de propiedades en formato *TOML*, soporte para múltiples entornos y diferentes formas de inyectar la configuración (variables de entorno, plantillas, etc.)
    - Configuración de logs usando *env_logger*.
    - Configuración del registro de métricas *Prometheus* con ejemplos de un contador y un histograma.
    - *Endpoint* para la prueba de vida.
    - *Endpoint* para la publicación de las métricas del registro.
    - *Endpoint* de ejemplo para el API.
    - *Dockerfile* para la compilación y construcción usando la imagen *docker* oficial de *RUST* v1.65.
    - *Dockerfile* para la compilación y construcción desde un entorno local.

- Descriptores *Terraform* y *Nomad*, junto a las plantillas de configuración de los contenedores necesarios para desplegar el cluster:
    - [Prometheus](https://prometheus.io).
      - Configuración de *scraping* usando el catálogo de servicios de *Consul*.
      - Configuración como servicio dentro de la [service mesh](https://developer.hashicorp.com/consul/docs/connect).
    - [Grafana](https://grafana.com).
      - Configuración del servicio *Prometheus* como datasource.
      - Dos gráficas predefinidas (*as code*) con número de peticiones por segundo y tamaño medio del tráfico en un *endpoint*.
      - Configuración del *ingress gateway*.
    - [Fluentd](https://www.fluentd.org).
      - *Dockerfile* para construir una imagen a medida para la versión 7.17.7 de *Elasticsearch*. 
      - Configuración del envío de logs al servicio *Elasticsearch*.
    - [Elasticsearch](https://www.elastic.co).
      - Configuración de un cluster con nodo único.
      - Configuración como servicio dentro de la *service mesh*.
    - [Kibana](https://www.elastic.co).
      - Configuración del servicio *Elasticsearch* como datasource.
      - Configuración del *ingress gateway*.
    - Microservicio [Rust](https://www.rust-lang.org).
      - Configuración como servicio dentro la *service mesh* con dos instancias balanceadas.
      - Configuración de la prueba de vida.
      - Configuración del envío de logs a *Fluentd* usando el driver de docker.
    - [KrakenD](https://www.krakend.io) *API gateway*.
      - Configuración como servicio dentro de la *service mesh*.
      - Configuración de un *endpoint* de ejemplo.
      - Configuración del *ingress gateway*.

## Requisitos previos de instalación
La distribución de Linux y las versiones de los componentes son solo a modo de orientación:
- [Rocky Linux 9](https://rockylinux.org) (distribución RHEL 9 compatible)
- [Rust](https://www.rust-lang.org/es/tools/install) (rustup 1.25.1, rustc/cargo 1.65.0)
- [Docker](https://docs.docker.com/get-docker) 20.10.21
- [HashiCorp Nomad](https://www.nomadproject.io) 1.4.3
- [HashiCorp Consul](https://www.consul.io) 1.14.2
- [HashiCorp Terraform](https://www.terraform.io) 1.3.6

### Instalación de Rust
Descargar y ejecutar el instalador (En este caso, se ha realizado una instalación seleccionando todas las opciones por defecto):
```
$ sudo curl https://sh.rustup.rs -sSf | sh
```

Verificar la instalación:
```
$ rustc --version
$ cargo --version
```

### Instalación de Docker
Actualizar el sistema operativo si fuera necesario, y añadir un repositorio *Docker* compatible con nuestra distribución de Linux:
```
$ sudo dnf --refresh update
$ sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
```
Borrar la instalación previa (si fuera necesario) e instalar la del repositorio añadido anteriormente: 
```
$ sudo dnf remove docker docker-common docker-selinux docker-engine
$ sudo dnf install device-mapper-persistent-data lvm2
$ sudo dnf install docker-ce docker-ce-cli containerd.io docker-compose-plugin --allowerasing
```

Verificar la instalación:
```
$ docker --version
``` 

Arrancar e instalar *Docker* como servicio en el inicio del sistema:
```
$ sudo systemctl start docker
$ sudo systemctl enable docker
$ sudo systemctl status docker
```
    
Añadir nuestro usuario al grupo de docker:
```
$ sudo groupadd docker
$ sudo usermod -aG docker $USER
$ newgrp docker
$ id $USER
```

Verificar la ejecución del contenedor de prueba: 
```
$ docker run hello-world
```

### Instalación y ejecución de *Consul*
Añadir el repositorio de *HashiCorp* específico para la distribución usada e instalar el paquete *consul*:
```
$ sudo dnf config-manager --add-repo=https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
$ sudo dnf install consul
```

Verificar la instalación:
```
$ consul --version
```

Por lo general todas las utilidades de *HashiCorp* tiene un modo de ejecución llamado "desarrollo", este modo no está pensado para entornos productivos, pero es una manera rápida de tener una instancia del servicio ejecutando y lista para realizar pruebas:
```
$ sudo consul agent -dev -client "0.0.0.0"
```

Se añade una configuración extra (-client) para que el servicio atienda peticiones en cualquier interfaz de red, y no solo en el bucle local:

La consola web estará disponible en el puerto 8500:
```
http://[IP_INTERFAZ]:8500
```

### Instalación y ejecución de Nomad

Añadir el repositorio de *HashiCorp* específico para la distribución usada (si no se hizo en el paso anterior) e instalar el paquete *nomad*:
```
$ sudo dnf config-manager --add-repo=https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
$ sudo dnf install nomad
```

Instalar el plugin para usar el modo *network* "bridge" (Necesario para poder crear la *service mesh* del cluster con *Consul* como proveedor):

```
$ sudo curl -L -o cni-plugins.tgz "https://github.com/containernetworking/plugins/releases/download/v1.0.0/cni-plugins-linux-$( [ $(uname -m) = aarch64 ] && echo arm64 || echo amd64)"-v1.0.0.tgz
$ sudo mkdir -p /opt/cni/bin
$ sudo tar -C /opt/cni/bin -xzf cni-plugins.tgz
```

Verificar la instalación:
```
$ nomad --version
```

Para ejecutar *Nomad* también existe una opción "desarrollo", pero en este caso es necesario crear volúmenes así que se ejecutará con una configuración predeterminada:
```
$ sudo nomad agent -config=/etc/nomad -network-interface enp0s3
```
Se arranca *Nomad* en una interfaz de red diferente al bucle local para poder tener acceso desde fuera de la máquina, también se indica un directorio donde hay un fichero (nomad.hcl) con la configuración de arranque y la definición de los volúmenes. Dentro del fichero también hay definida una configuración específica para que no se borren las imágenes de docker que no se usan durante un determinado periodo de tiempo, de esta manera se evita que en cada despliegue se tengan que descargar otra vez:
```
data_dir  = "/var/lib/nomad"

bind_addr = "0.0.0.0"

log_level = "INFO"

server {
  enabled = true
  bootstrap_expect = 1
}

client {
  enabled = true

  host_volume "prometheus-vol" {
    path = "/var/volumes/prometheus"
    read_only = false
  }

  host_volume "grafana-vol" {
    path = "/var/volumes/grafana"
    read_only = false
  }

  host_volume "elasticsearch-vol" {
    path = "/var/volumes/elasticsearch"
    read_only = false
  }

  host_volume "kibana-vol" {
    path = "/var/volumes/kibana"
    read_only = false
  }

}

plugin "docker" {
  config {
    volumes {
      enabled = true
    }
    gc {
      image = false
      image_delay = "8760h"
    }
  }
}
```

Los directorios de los volúmenes tienen como propietario el usuario con el que se ejecuta el contenedor de *Docker*, en este caso es siempre el usuario 1000, salvo para *Grafana* que es el 472:
```
drwxr-xr-x.  3 rocky root   19 Dec  4 15:36 elasticsearch
drwxr-xr-x.  7   472 root  101 Dec  8 17:08 grafana
drwxr-xr-x. 26 rocky root 4096 Dec  8 17:09 kibana
drwxr-xr-x.  9 rocky root 4096 Dec  8 17:16 prometheus
```

La consola web de *Nomad* estará disponible en el puerto 4646:
```
http://[IP_INTERFAZ]:4646
```

### Instalación de Terraform
Añadir el repositorio de *HashiCorp* específico para la distribución usada (si no se hizo en pasos anteriores) e instalar el paquete *terraform*:
```
$ sudo dnf config-manager --add-repo=https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
$ sudo dnf install terraform
```

Verificar la instalación:
```
$ terraform --version
```

### Construcción de la imagen de Fluentd
No he logrado encontrar una imagen de *Fluentd* preconstruida para trabajar con la versión 7.17.7 de *Elasticsearch*. Dentro de los fuentes del cluster viene un *Dockerfile* para construirla:

```
$ cd cluster
$ docker build -f Dockerfile.fluentd -t fluentd:v1.12.0-els .
```

### Construcción de la imagen del servicio
Existen dos *Dockerfile* para construir la imagen del microservicio, la opción por defecto usa la imagen oficial de RUST 1.65 para realizar la compilación, en este caso no es necesario tener instalado *RUST* en el equipo local:
```
$ cd prototype-service
$ docker build -t prototype-service:0.0.1 .
```
La otra opción es compilar desde el equipo local y a continuación crear la imagen. Esta opción es ideal para realizar pruebas durante los desarrollos, ya que es mucho más rápida:
```
$ cd prototype-service
$ cargo build --realease
$ docker build -f Dockerfile.local -t prototype-service:0.0.1 .
```

Como curiosidad decir que la imagen final creada en ambos casos usa una distribución de Linux diferente, esto se debe a que aunque *RUST* tiene un sistema de compilación cruzada, hay librerías de la distribución cuya versión tiene que coincidir exactamente con la versión de las que se usaron para compilar la aplicación. La imagen oficial usa una distribución *Debian* y en este caso de ejemplo se usa *Rocky Linux* para el entorno local. Esto no quiere decir que un programa *RUST* compilado en una distribución concreta de Linux no sea compatible con otras distribuciones, si no que las versiones de las librerías de las distribuciones usadas tienen que estar alineadas.

## Despliegue del cluster
Para desplegar el cluster primero hay que configurar la dirección del servidor *Nomad* en el archivo "cluster.tf":
```
provider "nomad" {
    address = "http://[IP_INTERFAZ]:4646"
}
```

Para ejecutar el despliegue ir a la carpeta del cluster y ejecutar terraform:
```
$ cd cluster
$ terraform init
$ terraform apply
```
Si el sistema tiene recursos suficientes todos los *jobs* del cluster deberián arrancar, se puede consultar el estado del cluster en la consola web del *Nomad*:

![Consola web Nomad](https://raw.githubusercontent.com/joselalvarez/nomad-sample-cluster/main/_img/nomad.png)

Y en la consola web de *Consul* se puede ver todos los servicios registrados en el catálogo:

![Consola web Consul](https://raw.githubusercontent.com/joselalvarez/nomad-sample-cluster/main/_img/consul.png)

Se puede hacer una pequeña prueba para comprobar que el cluster está funcionando correctamente, para ello se hace la siguiente petición al API gateway:
```
$ curl -d "Hola mundo" -X POST http://[IP_INTERFAZ]/v1/echo
```

En el *Kibana* deberiamos poder ver la traza del log de la petición:

![Consola web Consul](https://raw.githubusercontent.com/joselalvarez/nomad-sample-cluster/main/_img/kibana.png)

y en el *Grafana* la petición contabilizada:

![Consola web Consul](https://raw.githubusercontent.com/joselalvarez/nomad-sample-cluster/main/_img/grafana.png)

Para eliminar el cluster:
```
$ terraform destroy
```
