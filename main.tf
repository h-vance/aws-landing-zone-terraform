terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "wonkyyie-tf-state-hvc"
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "enterprise-tf-lock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# --- Providers ---
#
# The default provider is the management account, which owns the organization.
#
# The aliased providers assume OrganizationAccountAccessRole, the role AWS
# creates automatically in every account made by Organizations. This is how one
# Terraform run reaches into member accounts without long-lived credentials in
# each one.
#
# Note the two-phase bootstrap below: provider configuration cannot depend on
# values that are unknown until apply, so member account IDs must be supplied
# as variables rather than read from module.organization outputs.

provider "aws" {
  region = var.home_region
  default_tags {
    tags = local.common_tags
  }
}

provider "aws" {
  alias  = "log_archive"
  region = var.home_region

  assume_role {
    role_arn = "arn:aws:iam::${var.log_archive_account_id}:role/OrganizationAccountAccessRole"
  }

  default_tags {
    tags = local.common_tags
  }
}

provider "aws" {
  alias  = "workload"
  region = var.home_region

  assume_role {
    role_arn = "arn:aws:iam::${var.workload_account_id}:role/OrganizationAccountAccessRole"
  }

  default_tags {
    tags = local.common_tags
  }
}

locals {
  common_tags = {
    ManagedBy = "terraform"
    Repo      = "aws-landing-zone-terraform"
  }

  # Phase 2 resources only materialize once the member account IDs are known.
  # See README, "Two-phase bootstrap".
  bootstrapped = var.log_archive_account_id != "" && var.workload_account_id != ""
}

# --- Phase 1: the organization ---

module "organization" {
  source = "./modules/organization"

  log_archive_account_email = var.log_archive_account_email
  workload_account_email    = var.workload_account_email

  tags = local.common_tags
}

# --- Phase 2: guardrails, logging, and the workload baseline ---

module "scp" {
  source = "./modules/scp"

  target_ou_ids = {
    security  = module.organization.security_ou_id
    workloads = module.organization.workloads_ou_id
    sandbox   = module.organization.sandbox_ou_id
  }

  compute_ou_ids = {
    workloads = module.organization.workloads_ou_id
    sandbox   = module.organization.sandbox_ou_id
  }

  log_archive_bucket_name = var.log_archive_bucket_name
  allowed_regions         = var.allowed_regions
  tags                    = local.common_tags
}

module "log_archive" {
  source = "./modules/log-archive"
  count  = local.bootstrapped ? 1 : 0

  providers = {
    aws             = aws
    aws.log_archive = aws.log_archive
  }

  bucket_name           = var.log_archive_bucket_name
  organization_id       = module.organization.organization_id
  management_account_id = module.organization.management_account_id
  region                = var.home_region
  log_retention_days    = var.log_retention_days
  tags                  = local.common_tags
}

module "workload_baseline" {
  source = "./modules/account-baseline"
  count  = local.bootstrapped ? 1 : 0

  providers = {
    aws = aws.workload
  }

  admin_cidr           = var.admin_cidr
  instance_type        = var.workload_instance_type
  asg_min_size         = var.workload_asg_min_size
  asg_max_size         = var.workload_asg_max_size
  asg_desired_capacity = var.workload_asg_desired_capacity
  tags                 = local.common_tags
}

# --- Management account: remote state and CI access ---

resource "aws_s3_bucket" "terraform_state" {
  bucket = var.state_bucket_name

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_encryption" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state_public_access" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_lock" {
  name         = var.state_lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# --- GitHub OIDC Configuration ---

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  # GitHub's OIDC endpoint uses a publicly trusted CA, so IAM no longer
  # verifies this thumbprint. It is retained because the argument is required.
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "github_actions_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Scoped to this repository's branches rather than repo:owner/name:* , so a
    # pull request from a fork cannot assume the role.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:h-vance/aws-landing-zone-terraform:ref:refs/heads/*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "github-actions-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume.json
}

# Read-only by default. CI in this repo runs fmt, validate, and lint, none of
# which need write access. An earlier version attached AdministratorAccess,
# which handed full control of the account to anything that could satisfy the
# trust policy.
resource "aws_iam_role_policy_attachment" "github_actions_readonly" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
