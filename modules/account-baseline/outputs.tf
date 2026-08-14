output "vpc_id" {
  description = "VPC created for this account."
  value       = module.vpc.vpc_id
}

output "alb_dns_name" {
  description = "Public DNS name of the ALB."
  value       = aws_lb.main.dns_name
}

output "asg_name" {
  description = "Name of the autoscaling group."
  value       = aws_autoscaling_group.main.name
}
