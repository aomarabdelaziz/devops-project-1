module "iam-module" {
  source         = "../iam"
  ansible-ec2-id = module.server-module.ansible-ec2-id

}
