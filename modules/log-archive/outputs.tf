output "bucket_name" {
  description = "Name of the CloudTrail archive bucket."
  value       = aws_s3_bucket.trail.id
}

output "bucket_arn" {
  description = "ARN of the CloudTrail archive bucket."
  value       = aws_s3_bucket.trail.arn
}

output "trail_arn" {
  description = "ARN of the organization CloudTrail."
  value       = aws_cloudtrail.organization.arn
}
