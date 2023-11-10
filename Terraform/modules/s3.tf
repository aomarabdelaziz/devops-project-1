module "s3-module" {
  source          = "../s3"
  files_to_upload = ["helm-charts/jenkins-0.1.0.tgz", "helm-charts/regapp-0.1.0.tgz"]

}
