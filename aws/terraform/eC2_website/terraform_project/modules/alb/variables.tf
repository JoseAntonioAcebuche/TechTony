variable "vpc_id" {
  type        = string
  description = "VPC ID where ALB will be created"
}
variable "public_subnets" {
  type        = list(string)
  description = "List of public subnet IDs for ALB"
}
variable "security_group_id" {
  type        = string
  description = "Security group ID for ALB"
}
variable "target_instance_ids" {
  type        = list(string)
  description = "List of EC2 instance IDs to attach to target group"
  default     = []
}
variable "certificate_arn" {
  type        = string
  description = "ARN of SSL certificate for HTTPS listener"
  default     = null
}
