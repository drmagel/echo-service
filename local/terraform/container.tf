resource "docker_image" "echo_service" {
  name = "echo-service"
  build {
    path = "../.."
    tag = ["echo-service:latest"]
    dockerfile = "Dockerfile"
  }
}

resource "docker_volume" "sqlite" {
  name = "sqlite-volume"
}

resource "docker_container" "echo_service" {
  count = var.echo_service_replicas
  name = "echo-service-${count.index}"
  image = docker_image.echo_service.latest

  env = ["DB_PATH=/opt/echo-service/db"]

  mounts {
    target    = "/opt/echo-service/db"
    source    = docker_volume.sqlite.name
    type      = "volume"
    read_only = false

    volume_options {
      no_copy = false
      driver_name = "local"
    }
  }

  logs = true
}