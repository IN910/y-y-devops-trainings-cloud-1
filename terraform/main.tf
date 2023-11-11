terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  service_account_key_file = "./tf_key.json"
  folder_id                = local.folder_id
  zone                     = "ru-central1-a"
}

output "vms" {
  value = [for instance in yandex_compute_instance_group.group1.instances : instance.network_interface.0.nat_ip_address]
}
resource "yandex_vpc_network" "foo" {}

resource "yandex_vpc_subnet" "foo" {
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.foo.id
  v4_cidr_blocks = ["10.5.0.0/24"]
}

locals {
  folder_id = "b1ggul1r9pffesi964e0"
  service-accounts = toset([
    "catgpt-sa-imran",
  ])
  catgpt-sa-roles = toset([
    "container-registry.images.puller",
    "monitoring.editor",
  ])
}

data "yandex_iam_service_account" "ig-sa" {
  name = "role-for-tf"
}

resource "yandex_iam_service_account" "service-accounts" {
  for_each = local.service-accounts
  name     = each.key
}

resource "yandex_resourcemanager_folder_iam_member" "catgpt-roles" {
  for_each  = local.catgpt-sa-roles
  folder_id = local.folder_id
  member    = "serviceAccount:${yandex_iam_service_account.service-accounts["catgpt-sa-imran"].id}"
  role      = each.key
}

data "yandex_compute_image" "coi" {
  family = "container-optimized-image"
}



resource "yandex_lb_network_load_balancer" "foo" {
  name = "my-network-load-balancer"

  listener {
    name = "my-listener"
    port = 8080
    external_address_spec {
      ip_version = "ipv4"
    }
  }



  attached_target_group {
    target_group_id = yandex_compute_instance_group.group1.load_balancer.0.target_group_id

    healthcheck {
      name                = "http"
      interval            = 20
      timeout             = 10
      healthy_threshold   = 2
      unhealthy_threshold = 2
      http_options {
        port = 8080
        path = "/ping"
      }
    }
  }
}



resource "yandex_compute_instance_group" "group1" {
  name                = "test-ig"
  folder_id           = local.folder_id
  service_account_id  = data.yandex_iam_service_account.ig-sa.id
  deletion_protection = false

  load_balancer {
    target_group_name            = "tg-for-ig"
    max_opening_traffic_duration = 60
  }


  instance_template {



    platform_id = "standard-v2"
    resources {
      cores         = 2
      memory        = 1
      core_fraction = 5
    }
    boot_disk {
      initialize_params {
        type     = "network-hdd"
        size     = "30"
        image_id = data.yandex_compute_image.coi.id
      }
    }

    network_interface {
      network_id = yandex_vpc_network.foo.id
      subnet_ids = [yandex_vpc_subnet.foo.id]
      nat        = true
    }

    service_account_id = yandex_iam_service_account.service-accounts["catgpt-sa-imran"].id


    metadata = {
      docker-compose = file("${path.module}/docker-compose.yaml")
      ssh-keys       = "ubuntu:${file("~/.ssh/hw2_key.pub")}"
    }

  }


  scale_policy {
    fixed_scale {
      size = 2
    }
  }

  allocation_policy {
    zones = ["ru-central1-a"]
  }

  deploy_policy {
    max_unavailable = 1
    max_expansion   = 0
  }
}

