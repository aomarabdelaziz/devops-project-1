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

resource "aws_s3_bucket_policy" "s3_get_bucket_policy" {
  depends_on = [aws_iam_role.s3_put_bucket_policy_role, aws_iam_policy.s3_put_bucket_policy]
  bucket     = aws_s3_bucket.helm-bucket.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Statement1",
        "Principal" : "*",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject"
        ],
        "Resource" : [
          "arn:aws:s3:::${aws_s3_bucket.helm-bucket.id}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "s3_put_bucket_policy_role" {
  name = "s3-put-bucket-policy-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "s3.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}


resource "aws_iam_policy" "s3_put_bucket_policy" {
  name = "s3-put-bucket-policy"
  policy = jsonencode({
    "Id" : "Policy1696720443040",
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Stmt1696720442122",
        "Action" : [
          "s3:PutBucketPolicy"
        ],
        "Effect" : "Allow",
        "Resource" : "arn:aws:s3:::${aws_s3_bucket.helm-bucket.id}/*"
      }
    ]
  })
}




resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  role       = aws_iam_role.s3_put_bucket_policy_role.name
  policy_arn = aws_iam_policy.s3_put_bucket_policy.arn
}

resource "random_id" "rnd" {
  byte_length = 8
}
