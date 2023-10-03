
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


resource "aws_instance" "ansible-ec2" {
  depends_on             = [aws_instance.bootstrap-ec2]
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
    source      = "ansible/playbook.yaml"
    destination = "/home/ec2-user/playbook.yaml"
  }

  provisioner "file" {
    source      = "ansible/ansible.cfg"
    destination = "/home/ec2-user/ansible.cfg"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo amazon-linux-extras install ansible2 -y",
      "echo bootstrap_host ansible_host='${aws_instance.bootstrap-ec2.public_ip}' ansible_user=ec2-user ansible_ssh_private_key_file=/home/ec2-user/${var.bootstrap-key-name}.pem > inventory.txt",
      "sudo chmod 400 ${var.bootstrap-key-name}.pem",
      "ansible-playbook playbook.yaml"
    ]
  }


  tags = {
    Name = "${var.env_prefix}-ansible-server"
  }

}


resource "aws_iam_role" "ec2_role" {
  name = "EC2RoleWithPermissions"
  assume_role_policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Effect"    = "Allow",
        "Principal" = { "Service" : "ec2.amazonaws.com" },
        "Action"    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "ec2_role_policy" {
  name       = "AmazonEC2FullAccess"
  roles      = [aws_iam_role.ec2_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_policy_attachment" "administrator_role_policy" {
  name       = "AdministratorAccess"
  roles      = [aws_iam_role.ec2_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_policy_attachment" "cloudformation_role_policy" {
  name       = "AwsCloudFormationFullAccess"
  roles      = [aws_iam_role.ec2_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AwsCloudFormationFullAccess"
}

resource "aws_iam_policy_attachment" "iam_role_policy" {
  name       = "IAMFullAccess"
  roles      = [aws_iam_role.ec2_role.name]
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}

resource "aws_iam_instance_profile" "ec2-role-profile" {
  name = "EC2IAMInstanceProfile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "bootstrap-ec2" {
  ami                    = data.aws_ami.latest-amazon-linux-image.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.myapp-sg.id]

  subnet_id = var.subnet_id

  iam_instance_profile = aws_iam_instance_profile.ec2-role-profile.name


  availability_zone = var.avail_zone

  associate_public_ip_address = true

  key_name = var.bootstrap-key-name

  tags = {
    Name = "${var.env_prefix}-bootstrap-server"
  }

}
