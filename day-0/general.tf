terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.40.0, < 2.0.0"
    }
  }
}

provider "hcloud" {
  token = var.token
}