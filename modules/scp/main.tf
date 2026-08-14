# Service control policies.
#
# SCPs set the ceiling on what any principal in an account may do, including
# the root user. They do not grant anything: an action must be allowed by both
# the SCP and an IAM policy. That makes them the right place for guardrails
# that must hold even if an account's IAM is misconfigured.
#
# Every policy here is a deny. Deny statements cannot be escaped by a
# permissive IAM policy inside the member account, which is the property that
# makes them worth having.

# --- Protect the organization boundary ---

data "aws_iam_policy_document" "protect_organization" {
  statement {
    sid    = "DenyLeavingOrganization"
    effect = "Deny"
    # An account that can remove itself from the org escapes every SCP below.
    actions   = ["organizations:LeaveOrganization"]
    resources = ["*"]
  }
}

resource "aws_organizations_policy" "protect_organization" {
  name        = "protect-organization"
  description = "Prevents member accounts from leaving the organization"
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.protect_organization.json

  tags = var.tags
}

# --- Protect the audit trail ---

data "aws_iam_policy_document" "protect_cloudtrail" {
  statement {
    sid    = "DenyCloudTrailTampering"
    effect = "Deny"
    actions = [
      "cloudtrail:StopLogging",
      "cloudtrail:DeleteTrail",
      "cloudtrail:UpdateTrail",
      "cloudtrail:PutEventSelectors",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DenyLogArchiveBucketDeletion"
    effect = "Deny"
    actions = [
      "s3:DeleteBucket",
      "s3:DeleteBucketPolicy",
      "s3:PutBucketPolicy",
      "s3:PutLifecycleConfiguration",
    ]
    resources = [
      "arn:aws:s3:::${var.log_archive_bucket_name}",
      "arn:aws:s3:::${var.log_archive_bucket_name}/*",
    ]
  }
}

resource "aws_organizations_policy" "protect_cloudtrail" {
  name        = "protect-cloudtrail"
  description = "Prevents disabling org CloudTrail or tampering with the log archive bucket"
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.protect_cloudtrail.json

  tags = var.tags
}

# --- Restrict regions ---

data "aws_iam_policy_document" "restrict_regions" {
  statement {
    sid    = "DenyOutsideApprovedRegions"
    effect = "Deny"
    not_actions = [
      # Global services whose endpoints live in us-east-1 regardless of where
      # the caller is. Denying these by region would break IAM and billing.
      "iam:*",
      "organizations:*",
      "route53:*",
      "cloudfront:*",
      "support:*",
      "sts:*",
      "budgets:*",
      "ce:*",
      "waf:*",
      "shield:*",
    ]
    resources = ["*"]

    condition {
      test     = "StringNotEquals"
      variable = "aws:RequestedRegion"
      values   = var.allowed_regions
    }
  }
}

resource "aws_organizations_policy" "restrict_regions" {
  name        = "restrict-regions"
  description = "Confines regional API calls to approved regions, which also caps accidental spend"
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.restrict_regions.json

  tags = var.tags
}

# --- Restrict expensive resources ---

data "aws_iam_policy_document" "deny_expensive_resources" {
  statement {
    sid    = "DenyLargeInstanceTypes"
    effect = "Deny"
    actions = [
      "ec2:RunInstances",
    ]
    resources = ["arn:aws:ec2:*:*:instance/*"]

    condition {
      test     = "StringNotLike"
      variable = "ec2:InstanceType"
      values   = var.allowed_instance_types
    }
  }
}

resource "aws_organizations_policy" "deny_expensive_resources" {
  name        = "deny-expensive-resources"
  description = "Limits EC2 to small instance types so a mistake stays cheap"
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.deny_expensive_resources.json

  tags = var.tags
}

# --- Attachments ---
#
# Attached at the OU level rather than per account, so a new account placed in
# an OU inherits the guardrails without another Terraform change.

locals {
  # Every OU gets the organization and CloudTrail protections plus region
  # restriction. Only Sandbox and Workloads get the instance-type cap, since
  # the Security OU runs no compute.
  baseline_policies = {
    protect_organization = aws_organizations_policy.protect_organization.id
    protect_cloudtrail   = aws_organizations_policy.protect_cloudtrail.id
    restrict_regions     = aws_organizations_policy.restrict_regions.id
  }

  baseline_attachments = merge([
    for ou_name, ou_id in var.target_ou_ids : {
      for policy_name, policy_id in local.baseline_policies :
      "${ou_name}-${policy_name}" => { ou_id = ou_id, policy_id = policy_id }
    }
  ]...)

  compute_attachments = {
    for ou_name, ou_id in var.compute_ou_ids :
    "${ou_name}-deny-expensive" => {
      ou_id     = ou_id
      policy_id = aws_organizations_policy.deny_expensive_resources.id
    }
  }
}

resource "aws_organizations_policy_attachment" "baseline" {
  for_each = local.baseline_attachments

  policy_id = each.value.policy_id
  target_id = each.value.ou_id
}

resource "aws_organizations_policy_attachment" "compute" {
  for_each = local.compute_attachments

  policy_id = each.value.policy_id
  target_id = each.value.ou_id
}
