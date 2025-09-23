output "vpc_id" {
  value = module.vpc.vpc_id
}

output "security_group_id" {
  value = module.sg.security_group_id
}

output "ec2_1_public_ip" {
  value = module.ec2_1.public_ip
}

output "ec2_2_public_ip" {
  value = module.ec2_2.public_ip
}

output "alb_dns" {
  value = module.alb.dns_name
}
