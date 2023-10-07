output "jenkins-chart-url" {
  value = "https://${aws_s3_bucket.helm-bucket.id}.s3.amazonaws.com/${var.files_to_upload[0]}"
}

output "regapp-chart-url" {
  value = "https://${aws_s3_bucket.helm-bucket.id}.s3.amazonaws.com/${var.files_to_upload[1]}"
}
