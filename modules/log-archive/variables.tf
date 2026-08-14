variable "bucket_name" {
  description = "Globally unique name for the CloudTrail archive bucket."
  type        = string
}

variable "trail_name" {
  description = "Name of the organization CloudTrail."
  type        = string
  default     = "org-audit-trail"
}

variable "organization_id" {
  description = "Organization ID, used to scope the bucket policy to this org's log path."
  type        = string
}

variable "management_account_id" {
  description = "Management account ID, which owns the trail. Used in the SourceArn conditions."
  type        = string
}

variable "region" {
  description = "Region the trail is created in. Only affects the trail ARN in bucket policy conditions."
  type        = string
  default     = "us-east-1"
}

variable "log_retention_days" {
  description = "Days before archived logs expire. Kept short so storage cost stays negligible."
  type        = number
  default     = 30

  validation {
    condition     = var.log_retention_days >= 1
    error_message = "log_retention_days must be at least 1."
  }
}

variable "tags" {
  description = "Tags applied to the bucket and trail."
  type        = map(string)
  default     = {}
}
