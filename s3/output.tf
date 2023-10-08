locals {
  jenkins_filename = basename(var.files_to_upload[0])
  regapp_filename  = basename(var.files_to_upload[1])

}

output "jenkins-chart-url" {
  value = "https://${aws_s3_bucket.helm-bucket.id}.s3.amazonaws.com/${local.jenkins_filename}"
}

output "regapp-chart-url" {
  value = "https://${aws_s3_bucket.helm-bucket.id}.s3.amazonaws.com/${local.regapp_filename}"
}
