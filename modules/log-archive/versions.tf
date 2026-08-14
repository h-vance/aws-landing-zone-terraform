terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
      # The default provider creates the trail in the management account; the
      # log_archive alias creates the bucket in the log archive account.
      configuration_aliases = [aws.log_archive]
    }
  }
}
