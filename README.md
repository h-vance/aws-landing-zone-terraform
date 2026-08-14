# AWS Landing Zone (Terraform)

**A multi-account AWS foundation: organization, OUs, service control policies, and centralized audit logging, implemented as modular HCL.**

[![Terraform](https://www.shieldcn.dev/badge/Terraform-844FBA.svg?variant=default&logo=Terraform&logoColor=FFFFFF&size=xs)](https://terraform.io)&nbsp;[![GitHub Actions](https://www.shieldcn.dev/badge/GitHub%20Actions-2088FF.svg?variant=default&logo=GitHub+Actions&logoColor=FFFFFF&size=xs)](https://github.com/features/actions)

This repository builds the account structure and guardrails a landing zone needs: an AWS Organization with three OUs, two member accounts, four service control policies attached at the OU level, and an organization-wide CloudTrail writing into an isolated log archive account.

The guardrails are the substance here. An SCP is a ceiling that applies to every principal in an account including the root user, so it holds even when an account's own IAM is misconfigured. That is the property that separates a landing zone from a VPC with good intentions.

## Architecture

```
Management account (owns the organization, holds Terraform state)
│
├── Security OU ........... protect-organization, protect-cloudtrail, restrict-regions
│   └── log-archive account
│       └── S3 bucket receiving the org CloudTrail, 30-day lifecycle
│
├── Workloads OU .......... baseline SCPs + deny-expensive-resources
│   └── workload account
│       └── VPC, ALB, ASG, IMDSv2-enforced launch template
│
└── Sandbox OU ............ baseline SCPs + deny-expensive-resources
```

## Guardrails

| Policy | What it prevents |
|---|---|
| `protect-organization` | An account removing itself from the org, which would escape every other SCP |
| `protect-cloudtrail` | Stopping or deleting the trail, or tampering with the archive bucket |
| `restrict-regions` | Regional API calls outside approved regions, which also caps accidental spend |
| `deny-expensive-resources` | Launching EC2 instance types larger than the allowlist |

Attached at OU level, so a new account placed in an OU inherits them without another Terraform change.

## Two-phase bootstrap

Terraform provider blocks cannot depend on values that are unknown until apply. The member account IDs are created by this configuration, and the cross-account providers need those IDs to build a `role_arn`, so a single apply cannot do both. This is inherent to Terraform, not a workaround.

**Phase 1** creates the organization, OUs, member accounts, and SCPs:

```bash
cp terraform.tfvars.example terraform.tfvars   # fill in emails and bucket name
terraform init
terraform apply
```

**Phase 2** adds the log archive and the workload baseline. Take the two account IDs from the phase 1 outputs, put them in `terraform.tfvars`, and apply again:

```bash
terraform output log_archive_account_id
terraform output workload_account_id
# paste both into terraform.tfvars, then
terraform apply
```

Until those IDs are set, `local.bootstrapped` is false and the two cross-account modules have `count = 0`, so phase 1 plans cleanly rather than erroring on an unresolvable provider.

## Cost

Applying this costs approximately nothing:

- AWS Organizations, OUs, member accounts, and SCPs are free.
- The first copy of an organization trail's management events is free. Data events are not enabled.
- The archive bucket expires objects after 30 days, so storage stays in cents.
- The workload ASG defaults to `desired_capacity = 0`, so no instances run until you raise it.
- No NAT Gateway (~$32/month per AZ) and no AWS Config (per-item charges) anywhere in this configuration.

## Before you apply

**Member accounts are easy to create and slow to close.** Closing one requires a 90-day post-closure period, and the root email cannot be reused during it. Pick the addresses in `terraform.tfvars` deliberately.

`close_on_deletion` is set to `false` on both accounts, so `terraform destroy` will not close real AWS accounts.

## Repository Structure

| Path | Purpose |
|---|---|
| `modules/organization/` | Organization, OUs, member accounts |
| `modules/scp/` | Service control policies and OU attachments |
| `modules/log-archive/` | Org CloudTrail and the hardened archive bucket |
| `modules/account-baseline/` | Per-account VPC, ALB, and compute |
| `modules/vpc/` | Reusable network component |
| `main.tf` | Provider aliases and module composition |

## CI

`terraform fmt`, `terraform validate` at the root and per module, and `tflint` run on every push and pull request. Checkov and Trivy run advisory.

CI uses no AWS credentials and never runs plan or apply, so a pull request from a fork cannot reach the account. Applying is manual.

## Scope and Limits

**Built and verifiable in the code:**
- AWS Organization with `ALL` features, three OUs, and two member accounts.
- Four service control policies attached at OU level.
- Organization-wide CloudTrail, multi-region, with log file validation, writing to a separate account.
- Archive bucket with versioning, SSE, public access blocked, TLS-only bucket policy, and lifecycle expiry.
- Cross-account provider aliases assuming `OrganizationAccountAccessRole`.
- Per-account baseline: VPC with public and private subnets, ALB with health checks, ASG with an IMDSv2-enforced launch template.
- S3 remote state with DynamoDB locking, and a GitHub OIDC role scoped to this repository's branches.

**Still not included:**
- IAM Identity Center. Access to member accounts is via `OrganizationAccountAccessRole`, which is adequate for a reference architecture and not how a real org should hand out human access.
- AWS Config, GuardDuty, or Security Hub. All three bill per item or per finding and are omitted deliberately.
- Multi-region deployment. Everything targets one home region.
- Environment promotion, secrets management, or automated apply.
- Data event logging in CloudTrail, which is the part that costs money at volume.

**Verification status:** the configuration passes `terraform fmt`, `terraform validate`, and `tflint` in CI. It has not been applied against a live organization from this repository, so no `docs/evidence/` capture exists yet. When it is applied, the evidence worth capturing is `aws organizations list-accounts`, `list-policies-for-target` per OU, and a denied action showing an SCP actually blocking something, since an untested SCP is a claim rather than a control.

---
Operations & Reliability Engineered (c) 2026 Harrison Vance.
