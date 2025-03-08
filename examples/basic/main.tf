terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

variable "hcloud_token" {
  type = string
}
variable "network_id" {
  type = number
}
variable "tailscale_auth_key" {
  type = string
}
variable "infisical_client_id" {
  type = string
  default   = "xxx-xxx"
  sensitive = true
}
variable "infisical_client_secret" {
  type = string
  default   = "xxx-xxx"
  sensitive = true
}
variable "infisical_project_id" {
  type = string
  default   = "xxx-xxx"
  sensitive = true
}

variable "github_repo_url" {
  type    = string
  default = "https://github.com/lefterisALEX/terraform-hetzner-cloudstack.git"
}

variable "github_token" {
  type      = string
  sensitive = true
}


module "server" {
  source = "../.."

  name                     = "cloudstack-dev-123"
  image                    = "ubuntu-22.04"
  server_type              = "cax11"
  region                   = "nbg1"
  volume_size              = 10
  hcloud_network_id        = var.network_id 
  server_ip                = "192.168.156.10"
  public_access            = false
  volume_delete_protection = false
  tailscale_auth_key       = var.tailscale_auth_key
  enable_infisical         = true
  infisical_client_id      = var.infisical_client_id
  infisical_client_secret  = var.infisical_client_secret
  infisical_project_id     = var.infisical_project_id 
  github_repo_url          = var.github_repo_url   
  github_token             = var.github_token

  timezone         = "Europe/Amsterdam"
  ssh_keys         = ["main"]
  tailscale_routes = "192.168.156.10/32,172.29.0.0/16"
}



