variable "files_to_upload" {
  description = "List of file paths to upload to S3"
  type        = list(string)
  #default     = ["jenkins-0.1.0.tgz", "regapp-0.1.0.tgz"]
}

