data "aws_eks_cluster" "example" {
  depends_on = [var.ansible-ec2-id] #[aws_instance.ansible-ec2]
  name       = "demo-cluster"
}

data "tls_certificate" "cluster" {
  depends_on = [var.ansible-ec2-id] #[aws_instance.ansible-ec2]
  url        = data.aws_eks_cluster.example.identity[0].oidc[0].issuer

}
data "aws_caller_identity" "current" {}

locals {
  issuer_parts = split("/", data.aws_eks_cluster.example.identity[0].oidc[0].issuer)
  identifier   = element(local.issuer_parts, length(local.issuer_parts) - 1)
}

locals {
  account_id = data.aws_caller_identity.current.account_id
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


resource "aws_iam_instance_profile" "ec2-role-profile" {
  name = "EC2IAMInstanceProfile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_role_policy_attachment" "ec2_role_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}
resource "aws_iam_role_policy_attachment" "administrator_role_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
resource "aws_iam_role_policy_attachment" "iam_role_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}
resource "aws_iam_role_policy_attachment" "cloudformation_role_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCloudFormationFullAccess"
}


resource "aws_iam_openid_connect_provider" "openid-cluster" {
  depends_on = [var.ansible-ec2-id]

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = concat([data.tls_certificate.cluster.certificates.0.sha1_fingerprint])
  url             = data.aws_eks_cluster.example.identity[0].oidc[0].issuer
}





resource "aws_iam_policy" "loadbalancer-controller-policy" {
  depends_on = [var.ansible-ec2-id]

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


resource "aws_iam_role_policy_attachment" "loadbalancer-policy-attachment" {
  depends_on = [aws_iam_role.loadbalancer-controller-role]
  role       = aws_iam_role.loadbalancer-controller-role.name
  policy_arn = aws_iam_policy.loadbalancer-controller-policy.arn
}

resource "aws_iam_role_policy_attachment" "elastic-load-balancing-full-access" {
  depends_on = [aws_iam_role.loadbalancer-controller-role]
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
  role       = aws_iam_role.loadbalancer-controller-role.name
}
