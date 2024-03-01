resource "aws_s3_bucket" "cache" {
  bucket        = "${lower(local.name)}-query-cache"
  force_destroy = !var.deletion_protection
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cache" {
  bucket = aws_s3_bucket.cache.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
