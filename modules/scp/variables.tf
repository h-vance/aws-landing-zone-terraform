variable "target_ou_ids" {
  description = "OUs receiving the baseline guardrails, keyed by name for readable attachment addresses."
  type        = map(string)
}

variable "compute_ou_ids" {
  description = "OUs that run compute and therefore receive the instance-type cap."
  type        = map(string)
  default     = {}
}

variable "log_archive_bucket_name" {
  description = "Bucket the CloudTrail protection SCP defends. Must match the bucket created by the log-archive module."
  type        = string
}

variable "allowed_regions" {
  description = <<-EOT
    Regions where regional API calls are permitted. Keep this short: it is a
    security boundary and a spend cap at the same time.
  EOT
  type        = list(string)
  default     = ["us-east-1", "us-east-2"]

  validation {
    condition     = length(var.allowed_regions) > 0
    error_message = "allowed_regions must not be empty, which would deny every regional action."
  }
}

variable "allowed_instance_types" {
  description = "EC2 instance types permitted in compute OUs. Wildcards are allowed, for example t3.*."
  type        = list(string)
  default     = ["t2.micro", "t3.micro", "t3.small", "t4g.micro", "t4g.small"]
}

variable "tags" {
  description = "Tags applied to the policies."
  type        = map(string)
  default     = {}
}
