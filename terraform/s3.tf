resource "aws_s3_bucket" "payroll_docs" {
  bucket = "${local.name_prefix}-payroll-docs-${random_id.bucket_suffix.hex}"

  tags = {
    Name = "${local.name_prefix}-payroll-docs"
    Tier = "storage"
  }
}

resource "aws_s3_bucket_versioning" "payroll_docs" {
  bucket = aws_s3_bucket.payroll_docs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "payroll_docs" {
  bucket = aws_s3_bucket.payroll_docs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "payroll_docs" {
  bucket                  = aws_s3_bucket.payroll_docs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enforce TLS-only access and deny object uploads that do not request server-side encryption.
resource "aws_s3_bucket_policy" "payroll_docs_boundary" {
  bucket = aws_s3_bucket.payroll_docs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyUnEncryptedObjectUploads"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.payroll_docs.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "AES256"
          }
        }
      },
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = [aws_s3_bucket.payroll_docs.arn, "${aws_s3_bucket.payroll_docs.arn}/*"]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}