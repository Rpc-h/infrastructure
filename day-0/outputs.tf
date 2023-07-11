#output "main" {
#  value = one(hcloud_server.main[*].ipv4_address)
#  value = [for i in range(hcloud_server.main): hcloud_server.main[i].ipv4_address]
#  value = hcloud_server.main[count.index].ipv4_address
#}

output "main" {
  value = {
    for server in hcloud_server.main :
    server.name => server.ipv4_address
  }
}