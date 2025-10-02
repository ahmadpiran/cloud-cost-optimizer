provider "aws" {
  region = us-east-1
}

# S3 Bucket for CUR
resource "aws_s3_bucket" "cur_bucket" {
    bucket = "cloud-cost-optimizer-cur"
}

resource "aws_s3_bucket_acl" "cur_bucket_acl" {
    bucket = aws_s3_bucket.cur_bucket.id
    acl    = "private"
}

resource "aws_s3_bucket_versioning" "cur_bucket_versioning" {
    bucket = aws_s3_bucket.cur_bucket.id
    versioning_configuration {
        status = "Enabled"
    }
}

resource "aws_s3_bucket_lifecycle_configuration" "cur_bucket_lifecycle" {
    bucket = aws_s3_bucket.cur_bucket.id

    rule {
        id    = "cur-lifecycle-rule"
        status = "Enabled"

        expiration {
            days = 90
        }
    }
}