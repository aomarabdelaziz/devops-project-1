resource "tls_private_key" "ssh-pk" {
  count     = length(var.key-pairs-names)
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ssh-keys" {
  count      = length(var.key-pairs-names)
  key_name   = var.key-pairs-names[count.index]
  public_key = tls_private_key.ssh-pk[count.index].public_key_openssh
}

resource "local_file" "ssh_key" {
  count    = length(aws_key_pair.ssh-keys)
  filename = "${var.key-pairs-names[count.index]}.pem"
  content  = tls_private_key.ssh-pk[count.index].private_key_pem
}


