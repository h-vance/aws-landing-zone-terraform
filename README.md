# AWS Foundation (Terraform Reference Architecture)

**A single-account AWS network and compute foundation implemented with modular HCL.**

[![Terraform](https://www.shieldcn.dev/badge/Terraform-844FBA.svg?variant=default&logo=Terraform&logoColor=FFFFFF&size=xs)](https://terraform.io)&nbsp;[![GitHub Actions](https://www.shieldcn.dev/badge/GitHub%20Actions-2088FF.svg?variant=default&logo=GitHub+Actions&logoColor=FFFFFF&size=xs)](https://github.com/features/actions)

This repository is a reference architecture for a single AWS account. It moves beyond basic resource provisioning to demonstrate **Professional Infrastructure-as-Code (IaC)** standards, including remote state management, automated validation, and security hardening.

Multi-account governance (AWS Organizations, OUs, service control policies, cross-account roles) is deliberately out of scope. See Scope and Limits below.

## ✦ Professional Foundation
- **Remote State Management:** Integrated S3 backend with DynamoDB state locking to prevent concurrency issues and configuration drift.
- **Automated CI/CD:** GitHub Actions pipeline for automated `terraform validate`, `fmt`, and `tflint` checks on every PR.
- **Security Hardened:**
  - **IMDSv2 Enforced:** All compute resources require session tokens (protection against SSRF).
  - **S3 Versioning:** State buckets are versioned for disaster recovery.
  - **Restricted Access:** Security groups follow a "Strict Ingress" policy, limiting administrative access to authorized IPs.

## Key Features
- **Modular VPC Architecture**: VPC with separated public and private subnets, built as a reusable module.
- **Load Balanced Ingress**: High-availability Application Load Balancer (ALB) with automated health checks.
- **Auto-Scaling Compute**: Dynamic scaling groups (ASG) ensuring service durability across multiple availability zones.
- **GitHub OIDC Integration**: Zero-credential AWS authentication for CI/CD runners using OpenID Connect.

## Repository Structure
- **`modules/vpc/`**: Reusable network isolation component.
- **`main.tf`**: Primary orchestration for compute, storage, and security.
- **`.github/workflows/`**: Automated quality assurance pipelines.

## Getting Started
1. **Initialize Backend:** Run `terraform init` (ensure your AWS credentials have access to the state bucket).
2. **Validate:** `terraform validate` to ensure structural integrity.
3. **Plan:** `terraform plan -out=foundation.plan` to review architectural changes.

## Scope and Limits

This is a portfolio reference architecture, not a platform build. What it is and is not:

**Included and verifiable in the code:**
- One VPC with four subnets, two route tables, and an internet gateway (`modules/vpc/`).
- ALB with listener and target group health checks, a launch template, and an autoscaling group.
- S3 state bucket with versioning, server-side encryption, and public access blocked, plus a DynamoDB lock table.
- GitHub OIDC provider and IAM role for credential-free CI authentication.
- IMDSv2 required on compute via `http_tokens`.

**Deliberately not included:**
- AWS Organizations, organizational units, or service control policies.
- Multiple accounts, cross-account role assumption, or provider aliases. Everything targets a single account and region.
- Centralized logging, GuardDuty, Security Hub, or Config aggregation.
- Environment promotion, secrets management, or a real deployment pipeline beyond validation.

Expanding this into a true landing zone would mean an account structure, IAM boundaries, guardrails, and operational ownership, which is a separate design rather than more resources in this file.

---
Operations & Reliability Engineered (c) 2026 Harrison Vance.
