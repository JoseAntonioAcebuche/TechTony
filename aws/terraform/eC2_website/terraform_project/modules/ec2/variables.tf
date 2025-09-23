variable "ami_id" {
  type        = string
  description = "AMI ID for the EC2 instance"
}
variable "instance_type" {
  type        = string
  description = "EC2 instance type"
}
variable "subnet_id" {
  type        = string
  description = "Subnet ID where EC2 instance will be launched"
}
variable "security_group_id" {
  type        = string
  description = "Security group ID for EC2 instance"
}
