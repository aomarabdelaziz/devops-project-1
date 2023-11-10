
output "ansible-ec2-ip" {
  value = aws_instance.ansible-ec2.public_ip
}

output "ansible-ec2-id" {
  value = aws_instance.ansible-ec2.id
}
