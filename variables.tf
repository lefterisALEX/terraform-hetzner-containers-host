# variable "hcloud_token" {
#   sensitive   = true
#   description = "(Required) The API key for your hetzner project."
# }

variable "name" {
  default     = "server"
  description = "The name of your server"
}

variable "tailscale_auth_key" {
  default     = ""
  sensitive   = true
  description = "The auth key for your tailscale network"
}

variable "tailscale_routes" {
  default     = "10.10.0.2/32"
  description = "The routes which will be advertised in the tailscale network."
}

variable "region" {
  default     = "nbg1"
  description = "The cloud region where resources will be deployed."
}

variable "ip_range" {
  default     = "10.10.0.0/24"
  description = "The IP range of the network."
}

variable "hcloud_network_id" {
  type = number
  description = "The network ID from your private network"
}

variable "image" {
  default     = "ubuntu-22.04"
  description = "The image the server is created from."
}

variable "server_type" {
  default     = "cax11"
  description = "The server type this server should be created with."
}

variable "server_ip" {
  default     = "10.10.0.2"
  description = "The IP of the interface which will be attached to your server."
}

variable "root_disk_size" {
  type        = number
  default     = 80
  description = "The size of the main disk in GB for the instance."
}
variable "volume_size" {
  default     = "15"
  description = "The size of the volume which will be attached to the server"
}

variable "volume_delete_protection" {
  default     = false
  description = "If set to true is going to protect volume from deletion."
}

variable "timezone" {
  default     = "Europe/Amsterdam"
  description = "The timezone which the server will be configured."
}

variable "ssh_keys" {
  type        = list(string)
  default     = []
  description = "A list of SSH key names which will be imported while creating the server"
}

variable "private_key" {
  type        = string
  sensitive   = true
  default     = ""
  description = "The private key which can be used to connect to the server."
}

variable "public_access" {
  type        = bool
  default     = false
  description = "If false a firewall that block all public access will be attached to the server."
}

variable "infisical_client_id" {
  type        = string
  sensitive   = true
  default     = "xxx-xx"
  description = "The infisical client id."
}

variable "infisical_client_secret" {
  type        = string
  sensitive   = true
  default     = "xxx-xx"
  description = "The infisical client secret."
}

variable "infisical_project_id" {
  type        = string
  sensitive   = true
  default     = "xxx-xx"
  description = "The infisical project ID."
}
variable "enable_infisical" {
  type        = bool
  default     = false
  description = "Set to true to enable accessing secrets from infisical."
}

variable "github_token" {
  type        = string
  sensitive   = true
  default     = ""
  description = "The GitHub token for accessing private repositories."
}

variable "github_repo_url" {
  type        = string
  default     = ""
  description = "The URL of the applications repository."
}

variable "apps_directory" {
  type        = string
  default     = "examples/basic/apps"
  description = "The local directory where the applications repository will be cloned."
}


