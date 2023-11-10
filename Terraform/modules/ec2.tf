module "server-module" {
  source                = "../instances"
  env_prefix            = "prod"
  instance_type         = "t2.micro"
  vpc_id                = module.network-module.vpc_id
  subnet_id             = module.network-module.subnet_id
  avail_zone            = "us-east-1a"
  ansible-key-name      = module.keypairs-module.ansible-key-name
  bootstrap-key-name    = module.keypairs-module.bootstrap-key-name
  ansible-key-pem       = module.keypairs-module.ansible-private-key-pem
  bootstrap-key-pem     = module.keypairs-module.bootsrap-private-key-pem
  agent-key-name        = module.keypairs-module.agent-key-name
  agent-key-pem         = module.keypairs-module.agent-private-key-pem
  ec2-role-profile-name = module.iam-module.aws_iam_profile_name
  jenkins-chart-url     = module.s3-module.jenkins-chart-url
  regapp-chart-url      = module.s3-module.regapp-chart-url

}
