variable "home_region" {
  description = "Primary region. Must be present in allowed_regions or the SCP will deny your own calls."
  type        = string
  default     = "us-east-2"
}

# --- Member account identity ---
#
# These are empty on the first apply and filled in afterwards. Provider blocks
# cannot depend on values that are unknown until apply, so the account IDs
# cannot be read from module.organization outputs. See README, "Two-phase
# bootstrap".

variable "log_archive_account_id" {
  description = "Log archive account ID. Leave empty on the first apply, then set it from the organization module output."
  type        = string
  default     = ""
}

variable "workload_account_id" {
  description = "Workload account ID. Leave empty on the first apply, then set it from the organization module output."
  type        = string
  default     = ""
}

variable "log_archive_account_email" {
  description = "Root email for the log archive account. Must be globally unique across AWS."
  type        = string
}

variable "workload_account_email" {
  description = "Root email for the workload account. Must be globally unique across AWS."
  type        = string
}

# --- Guardrails ---

variable "allowed_regions" {
  description = "Regions permitted by the restrict-regions SCP."
  type        = list(string)
  default     = ["us-east-1", "us-east-2"]
}

# --- Logging ---

variable "log_archive_bucket_name" {
  description = "Globally unique bucket name for the organization CloudTrail archive."
  type        = string
}

variable "log_retention_days" {
  description = "Days before archived CloudTrail logs expire."
  type        = number
  default     = 30
}

# --- Management account state ---

variable "state_bucket_name" {
  description = "Bucket holding Terraform remote state. Must match the backend block."
  type        = string
  default     = "wonkyyie-tf-state-hvc"
}

variable "state_lock_table_name" {
  description = "DynamoDB table for state locking. Must match the backend block."
  type        = string
  default     = "enterprise-tf-lock"
}

# --- Workload account ---

variable "admin_cidr" {
  description = "CIDR permitted to reach the workload ALB."
  type        = string
}

variable "workload_instance_type" {
  description = "EC2 instance type in the workload account."
  type        = string
  default     = "t3.micro"
}

variable "workload_asg_min_size" {
  description = "Minimum ASG size in the workload account."
  type        = number
  default     = 0
}

variable "workload_asg_max_size" {
  description = "Maximum ASG size in the workload account."
  type        = number
  default     = 2
}

variable "workload_asg_desired_capacity" {
  description = "Desired ASG capacity in the workload account. Zero keeps an apply free."
  type        = number
  default     = 0
}
