variable "admin_cidr" {
  description = "CIDR permitted to reach the ALB on port 80."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.admin_cidr))
    error_message = "admin_cidr must be valid CIDR notation, for example 203.0.113.4/32."
  }

  validation {
    condition     = var.admin_cidr != "0.0.0.0/0"
    error_message = "admin_cidr must not be 0.0.0.0/0; the point of this variable is to restrict ingress."
  }
}

variable "instance_type" {
  description = "EC2 instance type. Must satisfy the deny-expensive-resources SCP."
  type        = string
  default     = "t3.micro"
}

variable "asg_min_size" {
  description = "Minimum ASG size. Zero by default so no instances run until deliberately scaled."
  type        = number
  default     = 0
}

variable "asg_max_size" {
  description = "Maximum ASG size."
  type        = number
  default     = 2
}

variable "asg_desired_capacity" {
  description = "Desired ASG capacity. Zero by default to keep an apply free."
  type        = number
  default     = 0
}

variable "tags" {
  description = "Tags applied to resources in this account."
  type        = map(string)
  default     = {}
}
