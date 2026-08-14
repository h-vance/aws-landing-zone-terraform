# AWS Organizations foundation: the organization itself, the OU hierarchy, and
# the member accounts.
#
# This is the piece that makes "landing zone" accurate rather than aspirational.
# Without an organization there is no boundary to govern, no OU to attach a
# service control policy to, and no separate account to isolate audit logs in.

resource "aws_organizations_organization" "this" {
  # ALL is required for service control policies. CONSOLIDATED_BILLING alone
  # cannot attach an SCP, which would defeat the point of this module.
  feature_set = "ALL"

  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "sso.amazonaws.com",
  ]

  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
  ]
}

# --- Organizational Units ---
#
# Three OUs, each with a different governance posture:
#   Security   tightest controls, holds the audit and log archive accounts
#   Workloads  runs application accounts
#   Sandbox    room to experiment, still fenced by the org-wide guardrails

resource "aws_organizations_organizational_unit" "security" {
  name      = "Security"
  parent_id = aws_organizations_organization.this.roots[0].id

  tags = merge(var.tags, { Purpose = "audit-and-logging" })
}

resource "aws_organizations_organizational_unit" "workloads" {
  name      = "Workloads"
  parent_id = aws_organizations_organization.this.roots[0].id

  tags = merge(var.tags, { Purpose = "application-workloads" })
}

resource "aws_organizations_organizational_unit" "sandbox" {
  name      = "Sandbox"
  parent_id = aws_organizations_organization.this.roots[0].id

  tags = merge(var.tags, { Purpose = "experimentation" })
}

# --- Member accounts ---
#
# Two accounts are created, both free. Note that AWS accounts are trivial to
# create and slow to close: closure requires a 90-day post-closure period and
# the email address cannot be reused during it. Treat these as long-lived.
#
# close_on_deletion is deliberately false. Setting it true means a
# `terraform destroy` closes real AWS accounts, which is not a mistake worth
# leaving available in a portfolio repo.

resource "aws_organizations_account" "log_archive" {
  name      = var.log_archive_account_name
  email     = var.log_archive_account_email
  parent_id = aws_organizations_organizational_unit.security.id

  # Terraform cannot delete an account from state without closing it, and the
  # log archive is the last thing that should disappear by accident.
  close_on_deletion = false

  lifecycle {
    # Recreating an account because a name or email changed would orphan the
    # original and its audit history.
    ignore_changes = [role_name]
  }

  tags = merge(var.tags, { AccountType = "log-archive" })
}

resource "aws_organizations_account" "workload" {
  name      = var.workload_account_name
  email     = var.workload_account_email
  parent_id = aws_organizations_organizational_unit.workloads.id

  close_on_deletion = false

  lifecycle {
    ignore_changes = [role_name]
  }

  tags = merge(var.tags, { AccountType = "workload" })
}
