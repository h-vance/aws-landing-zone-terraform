# Centralized audit logging.
#
# An organization trail in the management account writes every member account's
# API activity into a bucket that lives in a separate log archive account. The
# separation is the point: an attacker with full control of a workload account
# still cannot reach the bucket, and the protect-cloudtrail SCP stops them
# disabling the trail from inside.
#
# Cost note: the first copy of an organization trail's management events is
# free. Data events are not enabled here, and a 30-day lifecycle rule keeps
# storage in the pennies.

# The bucket is created with the log archive account's provider, passed in as
# the aws.log_archive alias.

resource "aws_s3_bucket" "trail" {
  provider = aws.log_archive

  bucket = var.bucket_name

  # Losing the audit log to a stray destroy would defeat the purpose.
  lifecycle {
    prevent_destroy = true
  }

  tags = merge(var.tags, { Purpose = "org-cloudtrail-archive" })
}

resource "aws_s3_bucket_versioning" "trail" {
  provider = aws.log_archive

  bucket = aws_s3_bucket.trail.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "trail" {
  provider = aws.log_archive

  bucket = aws_s3_bucket.trail.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "trail" {
  provider = aws.log_archive

  bucket                  = aws_s3_bucket.trail.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "trail" {
  provider = aws.log_archive

  bucket = aws_s3_bucket.trail.id

  rule {
    id     = "expire-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = var.log_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.log_retention_days
    }
  }
}

# CloudTrail must be able to write into the bucket from the management account.
data "aws_iam_policy_document" "trail_bucket" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.trail.arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudtrail:${var.region}:${var.management_account_id}:trail/${var.trail_name}"]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = ["s3:PutObject"]
    # The o- prefix path is what an organization trail writes to.
    resources = ["${aws_s3_bucket.trail.arn}/AWSLogs/${var.organization_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudtrail:${var.region}:${var.management_account_id}:trail/${var.trail_name}"]
    }
  }

  statement {
    sid    = "DenyUnencryptedTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.trail.arn,
      "${aws_s3_bucket.trail.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "trail" {
  provider = aws.log_archive

  bucket = aws_s3_bucket.trail.id
  policy = data.aws_iam_policy_document.trail_bucket.json
}

# The trail itself is created in the management account, which is the only
# place an organization trail can live.
resource "aws_cloudtrail" "organization" {
  name           = var.trail_name
  s3_bucket_name = aws_s3_bucket.trail.id

  is_organization_trail         = true
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true

  depends_on = [aws_s3_bucket_policy.trail]

  tags = merge(var.tags, { Purpose = "org-audit-trail" })
}
