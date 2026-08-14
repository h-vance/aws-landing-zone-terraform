output "organization_id" {
  description = "Organization ID."
  value       = module.organization.organization_id
}

output "management_account_id" {
  description = "Management account that owns the organization."
  value       = module.organization.management_account_id
}

# Feed these two back into terraform.tfvars to unlock phase 2.
output "log_archive_account_id" {
  description = "Log archive account ID. Set this as var.log_archive_account_id for the second apply."
  value       = module.organization.log_archive_account_id
}

output "workload_account_id" {
  description = "Workload account ID. Set this as var.workload_account_id for the second apply."
  value       = module.organization.workload_account_id
}

output "organizational_unit_ids" {
  description = "OU IDs, useful for verifying SCP attachments after apply."
  value = {
    security  = module.organization.security_ou_id
    workloads = module.organization.workloads_ou_id
    sandbox   = module.organization.sandbox_ou_id
  }
}

output "scp_policy_ids" {
  description = "Service control policy IDs created by this configuration."
  value       = module.scp.policy_ids
}

output "scp_attachment_count" {
  description = "Total SCP attachments. Expect 11: three baseline policies across three OUs, plus the compute cap on two."
  value       = module.scp.attachment_count
}

output "log_archive_bucket" {
  description = "CloudTrail archive bucket, once phase 2 has run."
  value       = try(module.log_archive[0].bucket_name, null)
}

output "workload_alb_dns_name" {
  description = "Workload ALB DNS name, once phase 2 has run."
  value       = try(module.workload_baseline[0].alb_dns_name, null)
}
