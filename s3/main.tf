resource "aws_s3_bucket" "helm-bucket" {
  bucket = "helm-charts-bucket-${random_id.rnd.hex}"

  tags = {
    Name        = "Helm Charts Bucket"
    Environment = "Prod"
  }
}

resource "aws_s3_object" "object" {
  count  = length(var.files_to_upload)
  bucket = aws_s3_bucket.helm-bucket.id
  key    = basename(var.files_to_upload[count.index])
  source = var.files_to_upload[count.index]
  acl    = "private"
}


resource "random_id" "rnd" {
  byte_length = 8
}
