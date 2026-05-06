# AWS Landing Zone (Terraform)

Enterprise-grade multi-account AWS Landing Zone architecture implemented with modular HCL and automated security governance.

## Overview
This repository contains the infrastructure code for a production-ready AWS Landing Zone. It follows AWS best practices for account separation, identity management, and centralized logging.

## Key Features
- **Multi-Account Orchestration**: Automated account provisioning and organizational unit (OU) management.
- **Identity & Access**: Least-privilege IAM roles and SSO integration.
- **Security & Compliance**: Centralized CloudTrail logging and automated AWS Config rule deployment.
- **Networking**: Hub-and-spoke VPC topology with Transit Gateway integration.

## Technical Stack
- **IaC**: Terraform 1.5+
- **Governance**: AWS Organizations, Control Tower
- **Security**: GuardDuty, Security Hub, IAM Access Analyzer
