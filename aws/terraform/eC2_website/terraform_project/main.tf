# Main Terraform Configuration - AWS Infrastructure Deployment
# Creates a complete web application infrastructure with VPC, EC2 instances, and Application Load Balancer
# Architecture: Multi-AZ deployment with public subnets for high availability

# VPC Module - Creates isolated network environment with public/private subnets
# Provides foundation networking for all AWS resources
module "vpc" {
  source   = "./modules/vpc"
  vpc_cidr = "10.0.0.0/16"                    # Main VPC CIDR block

  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]  # Public subnets for ALB and EC2
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]  # Private subnets for future use
}

# Security Group Module - Defines firewall rules for EC2 instances and ALB
# Controls inbound/outbound traffic to ensure security
module "sg" {
  source = "./modules/sg"
  vpc_id = module.vpc.vpc_id                  # Reference to VPC created above
}

# Data Source - Fetches latest Amazon Linux 2 AMI for EC2 instances
# Ensures instances use the most recent stable AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]                    # Official Amazon AMIs only

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]  # Amazon Linux 2 with HVM virtualization
  }
}

# EC2 Instances - Web servers deployed across multiple availability zones
# Uses for_each to create instances dynamically for better maintainability
module "ec2" {
  for_each = toset(["0", "1"])                        # Create 2 instances
  source   = "./modules/ec2"
  
  subnet_id         = module.vpc.public_subnet_ids[tonumber(each.key)]  # Distribute across AZs
  security_group_id = module.sg.security_group_id
  instance_type     = "t3.micro"                       # Cost-effective instance type
  ami_id            = data.aws_ami.amazon_linux.id     # Latest Amazon Linux 2
}

# Application Load Balancer - Distributes traffic between EC2 instances
# Provides high availability and automatic failover
module "alb" {
  source             = "./modules/alb"
  vpc_id             = module.vpc.vpc_id
  public_subnets     = module.vpc.public_subnet_ids    # Deploy across both AZs
  security_group_id  = module.sg.security_group_id
  target_instance_ids = [for k, v in module.ec2 : v.instance_id]  # All EC2 instances as targets
}