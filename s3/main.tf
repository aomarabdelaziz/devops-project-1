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

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.helm-bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.helm-bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicReadGetObject",
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "arn:aws:s3:::${aws_s3_bucket.helm-bucket.id}/*"
      }
    ]
  })
}

resource "random_id" "rnd" {
  byte_length = 8
}
