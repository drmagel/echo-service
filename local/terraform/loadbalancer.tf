locals {
  containers = tolist(docker_container.echo_service)
  servers_http = join("\n    ",  data.template_file.nginx_server_node_http.*.rendered)
}

data "template_file" "nginx_server_node_http" {
  count    = length(docker_container.echo_service)
  template = "server $${server_ip}:8080 max_fails=3 fail_timeout=5s;"

  vars = {
    server_ip = element(local.containers.*.ip_address, count.index)
  }
}

data "template_file" "nginx_conf" {
  template = <<EOF
worker_processes 2;
worker_rlimit_nofile 20000;

events {
  worker_connections 4096;
}

stream {
  upstream echo_servers_http {
    least_conn;
    ${local.servers_http}
  }
  server {
    listen   80;
    # https://www.exploit.cz/how-to-solve-kubernetes-ingress-nginx-real-ip/
    #proxy_protocol    on; #uncomment if you got 127.0.0.1 remote ip issue
    proxy_pass echo_servers_http;
  }
  
}
EOF
}

data "docker_registry_image" "nginx" {
  name = "nginx:stable"
}

resource "docker_container" "nginx" {
  name = "nginx-loadbalancer"
  image = data.docker_registry_image.nginx.name

  volumes {
    host_path      = "/tmp/nginx-lb.conf"
    container_path = "/etc/nginx/nginx.conf"
  }

  logs = true

  ports {
    internal = "80"
    external = var.lb_external_port
  }

  depends_on = [local_file.nginx_conf]
}

resource "local_file" "nginx_conf" {
    content  = data.template_file.nginx_conf.template
    filename = "/tmp/nginx-lb.conf"
    file_permission = "0664"
    directory_permission = "0775"
}
