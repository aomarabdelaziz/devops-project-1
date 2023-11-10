
data "aws_ami" "latest-amazon-linux-image" {

  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

}

resource "aws_security_group" "myapp-sg" {
  name   = "myapp-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {
    Name = "${var.env_prefix}-sg"
  }
}

resource "aws_instance" "ansible-ec2" {
  depends_on             = [aws_instance.bootstrap-ec2, aws_instance.agent-ec2]
  ami                    = data.aws_ami.latest-amazon-linux-image.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.myapp-sg.id]

  subnet_id = var.subnet_id

  availability_zone = var.avail_zone

  associate_public_ip_address = true

  key_name = var.ansible-key-name


  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = var.ansible-key-pem
  }

  provisioner "file" {
    source      = "${var.bootstrap-key-name}.pem"
    destination = "/home/ec2-user/${var.bootstrap-key-name}.pem"
  }

  provisioner "file" {
    source      = "${var.agent-key-name}.pem"
    destination = "/home/ec2-user/${var.agent-key-name}.pem"
  }

  provisioner "file" {
    source      = "ansible/playbook.yaml"
    destination = "/home/ec2-user/playbook.yaml"
  }

  provisioner "file" {
    source      = "ansible/ansible.cfg"
    destination = "/home/ec2-user/ansible.cfg"
  }

  provisioner "file" {
    source      = "helm-charts/jenkins-0.1.0.tgz"
    destination = "/home/ec2-user/jenkins-0.1.0.tgz"
  }

  provisioner "file" {
    source      = "helm-charts/jenkins-0.1.0.tgz"
    destination = "/home/ec2-user/regapp-0.1.0.tgz"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo amazon-linux-extras install ansible2 -y",
      "echo bootstrap_host ansible_host='${aws_instance.bootstrap-ec2.public_ip}' ansible_user=ec2-user ansible_ssh_private_key_file=/home/ec2-user/${var.bootstrap-key-name}.pem > inventory.txt",
      "echo agent_host ansible_host='${aws_instance.agent-ec2.public_ip}' ansible_user=ubuntu ansible_ssh_private_key_file=/home/ec2-user/${var.agent-key-name}.pem >> inventory.txt",
      "sudo chmod 400 ${var.bootstrap-key-name}.pem ${var.agent-key-name}.pem",
      "sudo echo helm install jenkins ${var.jenkins-chart-url} --namespace=devops-tools --create-namespace > /home/ec2-user/install-charts.sh",
      "sudo helm install regapp ${var.regapp-chart-url} >> /home/ec2-user/install-charts.sh",
      #"ansible-playbook playbook.yaml",
      "ansible-playbook playbook.yaml -e 'jenkins_chart_url=${var.jenkins-chart-url} regapp_chart_url=${var.regapp-chart-url}'"
    ]
  }


  tags = {
    Name = "${var.env_prefix}-ansible-server"
  }

}


resource "aws_instance" "bootstrap-ec2" {
  ami                    = data.aws_ami.latest-amazon-linux-image.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.myapp-sg.id]

  subnet_id = var.subnet_id

  iam_instance_profile = var.ec2-role-profile-name #aws_iam_instance_profile.ec2-role-profile.name

  availability_zone = var.avail_zone

  associate_public_ip_address = true

  key_name = var.bootstrap-key-name

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = var.bootstrap-key-pem
  }
  provisioner "remote-exec" {
    inline = [
      "echo helm install jenkins ${var.jenkins-chart-url} --namespace=devops-tools --create-namespace > /home/ec2-user/install-charts.sh",
      "echo helm install regapp ${var.regapp-chart-url} >> /home/ec2-user/install-charts.sh",
      "chmod +x /home/ec2-user/install-charts.sh"
    ]
  }



  tags = {
    Name = "${var.env_prefix}-bootstrap-server"
  }

}

resource "aws_instance" "agent-ec2" {
  ami                    = "ami-053b0d53c279acc90"
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.myapp-sg.id]

  subnet_id = var.subnet_id

  availability_zone = var.avail_zone

  associate_public_ip_address = true

  key_name = var.agent-key-name

  tags = {
    Name = "${var.env_prefix}-agent-server"
  }

}
