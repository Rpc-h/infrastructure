resource "hcloud_server" "main" {
  count       = var.instances
  name        = "${var.name}-${count.index}"
  server_type = "cx31"
  location    = "hel1"
  image       = "debian-11"
  ssh_keys = [
    "martins.eglitis",
    "tino.breddin",
    "tino.breddin-2",
    "steven.noni",
    "ronny.esterluss",
    "ronny.esterluss-2"
  ]
}