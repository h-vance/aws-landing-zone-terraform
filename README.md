# AWS Landing Zone (Terraform Reference Architecture)

**Enterprise-grade multi-account governance and foundation implemented with modular HCL.**

[![Terraform](https://img.shields.io/badge/Terraform-844FBA?style=for-the-badge&logo=Terraform&logoColor=FFFFFF)](https://terraform.io)&nbsp;[![GitHub Actions](https://img.shields.io/badge/GitHub%20Actions-2088FF?style=for-the-badge&logo=GitHub+Actions&logoColor=FFFFFF)](https://github.com/features/actions)

This repository implements a production-ready AWS Landing Zone foundation. It moves beyond basic resource provisioning to demonstrate **Professional Infrastructure-as-Code (IaC)** standards, including remote state management, automated validation, and security hardening.

## ✦ Professional Foundation
- **Remote State Management:** Integrated S3 backend with DynamoDB state locking to prevent concurrency issues and configuration drift.
- **Automated CI/CD:** GitHub Actions pipeline for automated `terraform validate`, `fmt`, and `tflint` checks on every PR.
- **Security Hardened:** 
    - **IMDSv2 Enforced:** All compute resources require session tokens (protection against SSRF).
    - **S3 Versioning:** State buckets are versioned for disaster recovery.
    - **Restricted Access:** Security groups follow a "Strict Ingress" policy, limiting administrative access to authorized IPs.

## Key Features
- **Modular VPC Architecture**: Hub-and-spoke ready VPC with separated public and private subnets.
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
3. **Plan:** `terraform plan -out=landing-zone.plan` to review architectural changes.

---
Operations & Reliability Engineered (c) 2026 Harrison Vance.
