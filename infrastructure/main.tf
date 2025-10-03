provider "aws" {
  region = "us-east-1"
}

# S3 Bucket for AWS Data Exports
resource "aws_s3_bucket" "data_exports_bucket" {
    bucket = "cloud-cost-optimizer-data-exports"
}

resource "aws_s3_bucket_acl" "data_exports_bucket_acl" {
    bucket = aws_s3_bucket.data_exports_bucket.id
    acl    = "private"
}

resource "aws_s3_bucket_versioning" "data_exports_bucket_versioning" {
    bucket = aws_s3_bucket.data_exports_bucket.id
    versioning_configuration {
        status = "Enabled"
    }
}

resource "aws_s3_bucket_lifecycle_configuration" "data_exports_bucket_lifecycle" {
    bucket = aws_s3_bucket.data_exports_bucket.id

    rule {
        id    = "data-exports-bucket-lifecycle-rule"
        status = "Enabled"

        expiration {
            days = 90
        }
    }
}


# Athena DB for AWS Data Exports
resource "aws_athena_database" "data_exports_db" {
  name  = "cloud_cost_optimizer_data_exports_db"
  bucket = aws_s3_bucket.data_exports_bucket.bucket
}