output "policy_ids" {
  description = "Map of policy name to policy ID, useful for verifying attachments after apply."
  value = {
    protect_organization     = aws_organizations_policy.protect_organization.id
    protect_cloudtrail       = aws_organizations_policy.protect_cloudtrail.id
    restrict_regions         = aws_organizations_policy.restrict_regions.id
    deny_expensive_resources = aws_organizations_policy.deny_expensive_resources.id
  }
}

output "attachment_count" {
  description = "Number of policy attachments created, for a quick post-apply sanity check."
  value       = length(aws_organizations_policy_attachment.baseline) + length(aws_organizations_policy_attachment.compute)
}
