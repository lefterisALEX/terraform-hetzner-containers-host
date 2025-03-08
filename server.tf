resource "hcloud_server" "this" {

  name         = var.name
  image        = var.image
  server_type  = var.server_type
  location     = var.region
  firewall_ids = var.public_access ? [] : [hcloud_firewall.this[0].id]
  ssh_keys     = concat(var.ssh_keys, ["server"])

  user_data = templatefile("${path.module}/scripts/bootstrap.sh", {
    tailscale_auth_key      = var.tailscale_auth_key,
    linux_device            = hcloud_volume.this.linux_device
    tailscale_routes        = var.tailscale_routes
    timezone                = var.timezone
    apps_repository_url     = format("https://%s@%s", var.github_token, replace(var.github_repo_url, "https://", ""))
    apps_directory          = var.apps_directory
    INFISICAL_CLIENT_ID     = var.infisical_client_id
    INFISICAL_CLIENT_SECRET = var.infisical_client_secret
    INFISICAL_PROJECT_ID    = var.infisical_project_id
    INFISICAL_API_URL       = "https://eu.infisical.com"
  })

  lifecycle {
    replace_triggered_by = [
      hcloud_volume.this.size
    ]
  }

  network {
    network_id = var.hcloud_network_id
    ip         = var.server_ip
  }

  public_net {
    ipv6_enabled = false
    ipv4_enabled = true
  }
}

resource "hcloud_volume" "this" {
  name              = "${var.name}-data"
  size              = var.volume_size
  location          = var.region
  automount         = false
  format            = "ext4"
  delete_protection = var.volume_delete_protection
}

resource "hcloud_volume_attachment" "this" {
  volume_id = hcloud_volume.this.id
  server_id = hcloud_server.this.id
  automount = false
}


