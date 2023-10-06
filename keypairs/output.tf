output "ansible-key-name" {
  value = var.key-pairs-names[0]
}

output "ansible-private-key-pem" {
  value = tls_private_key.ssh-pk[0].private_key_pem
}
output "bootstrap-key-name" {
  value = var.key-pairs-names[1]
}

output "bootsrap-private-key-pem" {
  value = tls_private_key.ssh-pk[1].private_key_pem
}

output "agent-key-name" {
  value = var.key-pairs-names[2]
}

output "agent-private-key-pem" {
  value = tls_private_key.ssh-pk[2].private_key_pem
}
