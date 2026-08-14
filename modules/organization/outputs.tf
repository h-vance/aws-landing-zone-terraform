output "organization_id" {
  description = "The organization ID, used by SCP conditions and CloudTrail."
  value       = aws_organizations_organization.this.id
}

output "organization_arn" {
  description = "ARN of the organization."
  value       = aws_organizations_organization.this.arn
}

output "root_id" {
  description = "Root ID of the organization, the parent of every OU."
  value       = aws_organizations_organization.this.roots[0].id
}

output "security_ou_id" {
  description = "OU holding audit and logging accounts."
  value       = aws_organizations_organizational_unit.security.id
}

output "workloads_ou_id" {
  description = "OU holding application accounts."
  value       = aws_organizations_organizational_unit.workloads.id
}

output "sandbox_ou_id" {
  description = "OU for experimentation."
  value       = aws_organizations_organizational_unit.sandbox.id
}

output "log_archive_account_id" {
  description = "Account ID of the log archive account."
  value       = aws_organizations_account.log_archive.id
}

output "workload_account_id" {
  description = "Account ID of the workload account."
  value       = aws_organizations_account.workload.id
}

output "management_account_id" {
  description = "Account ID of the management account, which owns the organization."
  value       = aws_organizations_organization.this.master_account_id
}
