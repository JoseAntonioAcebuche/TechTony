# Application Load Balancer - Routes incoming traffic to healthy targets
# Configured as internet-facing ALB with security hardening enabled
resource "aws_lb" "this" {
  name               = "demo-alb"
  internal           = false                    # Internet-facing ALB
  load_balancer_type = "application"           # Layer 7 load balancer
  security_groups    = [var.security_group_id] # Controls inbound/outbound traffic
  subnets            = var.public_subnets      # Deploy across multiple AZs for HA
  drop_invalid_header_fields =  true           # Security: Drop malformed headers
}

# Target Group - Defines health check and routing rules for backend instances
# Routes HTTP traffic on port 80 to registered targets
resource "aws_lb_target_group" "this" {
  name     = "demo-target-group"
  port     = 80          # Port on targets to receive traffic
  protocol = "HTTP"      # Protocol for health checks and traffic routing
  vpc_id   = var.vpc_id  # VPC where targets are located
}

# HTTP Listener - Handles incoming HTTP traffic on port 80
# Conditionally redirects to HTTPS if SSL certificate is provided, otherwise forwards to targets
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    # Redirect to HTTPS if certificate exists, otherwise forward to target group
    type = var.certificate_arn != null ? "redirect" : "forward"
    
    # Dynamic redirect block - only created when certificate is available
    dynamic "redirect" {
      for_each = var.certificate_arn != null ? [1] : []
      content {
        port        = "443"        # Redirect to HTTPS port
        protocol    = "HTTPS"      # Use secure protocol
        status_code = "HTTP_301"   # Permanent redirect
      }
    }
    
    # Forward to target group only when no certificate (HTTP-only setup)
    target_group_arn = var.certificate_arn == null ? aws_lb_target_group.this.arn : null
  }
}

# HTTPS Listener - Handles secure traffic on port 443 (only created if certificate provided)
# Terminates SSL/TLS and forwards decrypted traffic to target group
resource "aws_lb_listener" "https" {
  count             = var.certificate_arn != null ? 1 : 0  # Conditional creation
  load_balancer_arn = aws_lb.this.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"  # TLS 1.2+ security policy
  certificate_arn   = var.certificate_arn                   # SSL certificate from ACM

  default_action {
    type             = "forward"                           # Forward all HTTPS traffic
    target_group_arn = aws_lb_target_group.this.arn       # To the target group
  }
}

# Target Group Attachment - Registers multiple EC2 instances with the target group
# Enables the ALB to route traffic to these instances for load balancing
resource "aws_lb_target_group_attachment" "this" {
  for_each         = toset(var.target_instance_ids) # Loop through all instance IDs
  target_group_arn = aws_lb_target_group.this.arn   # Target group to attach to
  target_id        = each.value                     # Current EC2 instance ID
  port             = 80                             # Port on instance to receive traffic
}