
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

####

data "aws_eks_cluster" "example" {
  depends_on = [aws_instance.ansible-ec2]
  name       = "demo-cluster"
}
/* output "identity-oidc-issuer" {
  value = data.aws_eks_cluster.example.identity[0].oidc[0].issuer
} */

data "tls_certificate" "cluster" {
  depends_on = [aws_instance.ansible-ec2]
  url        = data.aws_eks_cluster.example.identity[0].oidc[0].issuer
}

locals {
  issuer_parts = split("/", data.aws_eks_cluster.example.identity[0].oidc[0].issuer)
  identifier   = element(local.issuer_parts, length(local.issuer_parts) - 1)
}

/* output "identifier" {
  value = local.identifier
} */

/* output "tls_certificate-oidc-issuer" {
  value = data.tls_certificate.cluster.certificates.0.sha1_fingerprint
} */

resource "aws_iam_openid_connect_provider" "openid-cluster" {
  depends_on = [aws_instance.ansible-ec2]

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = concat([data.tls_certificate.cluster.certificates.0.sha1_fingerprint])
  url             = data.aws_eks_cluster.example.identity[0].oidc[0].issuer
}

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

/* output "account_id" {
  value = local.account_id
} */

resource "aws_iam_policy" "loadbalancer-controller-policy" {
  depends_on = [aws_instance.ansible-ec2]

  name = "loadbalancer-controller-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["iam:CreateServiceLinkedRole"],
        Resource = "*",
        Condition = {
          StringEquals = {
            "iam:AWSServiceName" = "elasticloadbalancing.amazonaws.com"
          }
        }
      },
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeVpcs",
          "ec2:DescribeVpcPeeringConnections",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTags",
          "ec2:GetCoipPoolUsage",
          "ec2:DescribeCoipPools",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeListenerCertificates",
          "elasticloadbalancing:DescribeSSLPolicies",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeTags"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "cognito-idp:DescribeUserPoolClient",
          "acm:ListCertificates",
          "acm:DescribeCertificate",
          "iam:ListServerCertificates",
          "iam:GetServerCertificate",
          "waf-regional:GetWebACL",
          "waf-regional:GetWebACLForResource",
          "waf-regional:AssociateWebACL",
          "waf-regional:DisassociateWebACL",
          "wafv2:GetWebACL",
          "wafv2:GetWebACLForResource",
          "wafv2:AssociateWebACL",
          "wafv2:DisassociateWebACL",
          "shield:GetSubscriptionState",
          "shield:DescribeProtection",
          "shield:CreateProtection",
          "shield:DeleteProtection"
        ],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = ["ec2:AuthorizeSecurityGroupIngress", "ec2:RevokeSecurityGroupIngress"],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = ["ec2:CreateSecurityGroup"],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = ["ec2:CreateTags"],
        Resource = "arn:aws:ec2:*:*:security-group/*",
        Condition = {
          StringEquals = {
            "ec2:CreateAction" = "CreateSecurityGroup"
          },
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect   = "Allow",
        Action   = ["ec2:CreateTags", "ec2:DeleteTags"],
        Resource = "arn:aws:ec2:*:*:security-group/*",
        Condition = {
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster"  = "true"
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow",
        Action = [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DeleteSecurityGroup"
        ],
        Resource = "*",
        Condition = {
          Null = {
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect   = "Allow",
        Action   = ["elasticloadbalancing:CreateLoadBalancer", "elasticloadbalancing:CreateTargetGroup"],
        Resource = "*",
        Condition = {
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow",
        Action = [
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:CreateRule",
          "elasticloadbalancing:DeleteRule"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = ["elasticloadbalancing:AddTags", "elasticloadbalancing:RemoveTags"],
        Resource = [
          "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
        ],
        Condition = {
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster"  = "true"
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow",
        Action = ["elasticloadbalancing:AddTags", "elasticloadbalancing:RemoveTags"],
        Resource = [
          "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:SetIpAddressType",
          "elasticloadbalancing:SetSecurityGroups",
          "elasticloadbalancing:SetSubnets",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:DeleteTargetGroup"
        ],
        Resource = "*",
        Condition = {
          Null = {
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect   = "Allow",
        Action   = ["elasticloadbalancing:RegisterTargets", "elasticloadbalancing:DeregisterTargets"],
        Resource = "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
      },
      {
        Effect = "Allow",
        Action = [
          "elasticloadbalancing:SetWebAcl",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:AddListenerCertificates",
          "elasticloadbalancing:RemoveListenerCertificates",
          "elasticloadbalancing:ModifyRule"
        ],
        Resource = "*"
      },
    ]
  })
}


resource "aws_iam_role" "loadbalancer-controller-role" {
  depends_on = [aws_iam_openid_connect_provider.openid-cluster]

  name = "loadbalancer-controller-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : "arn:aws:iam::${local.account_id}:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/${local.identifier}"
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "oidc.eks.us-east-1.amazonaws.com/id/${local.identifier}:aud" : "sts.amazonaws.com",
            "oidc.eks.us-east-1.amazonaws.com/id/${local.identifier}:sub" : "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })
}


resource "aws_iam_policy_attachment" "loadbalancer-policy-attachment" {
  depends_on = [aws_iam_role.loadbalancer-controller-role]

  name       = "loadbalancer-policy-attachment"
  policy_arn = aws_iam_policy.loadbalancer-controller-policy.arn
  roles      = [aws_iam_role.loadbalancer-controller-role.name]
}

resource "aws_iam_policy_attachment" "elastic-load-balancing-full-access" {
  depends_on = [aws_iam_role.loadbalancer-controller-role]

  name       = "ElasticLoadBalancingFullAccess"
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
  roles      = [aws_iam_role.loadbalancer-controller-role.name]
}
