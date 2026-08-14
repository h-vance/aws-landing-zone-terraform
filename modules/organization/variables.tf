variable "log_archive_account_name" {
  description = "Display name for the log archive account."
  type        = string
  default     = "log-archive"
}

variable "log_archive_account_email" {
  description = <<-EOT
    Root email for the log archive account. Must be globally unique across all
    of AWS and cannot be reused for 90 days after an account is closed. A plus
    address on an existing mailbox works, for example you+log-archive@example.com.
  EOT
  type        = string

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.log_archive_account_email))
    error_message = "log_archive_account_email must be a valid email address."
  }
}

variable "workload_account_name" {
  description = "Display name for the workload account."
  type        = string
  default     = "workload"
}

variable "workload_account_email" {
  description = "Root email for the workload account. Same uniqueness rules as the log archive address."
  type        = string

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.workload_account_email))
    error_message = "workload_account_email must be a valid email address."
  }
}

variable "tags" {
  description = "Tags applied to organizational units and accounts."
  type        = map(string)
  default     = {}
}
