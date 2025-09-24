
resource "aws_instance" "this" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  monitoring    = true

  vpc_security_group_ids = [var.security_group_id]

  root_block_device {
    encrypted = true
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              
              # Install nginx with error handling for different Amazon Linux versions
              if amazon-linux-extras list | grep -q nginx1; then
                amazon-linux-extras install -y nginx1
              else
                yum install -y nginx
              fi
              
              systemctl start nginx
              systemctl enable nginx
              echo "<h1>Hello from Terraform EC2 + ALB!</h1>" > /usr/share/nginx/html/index.html
              EOF

  tags = {
    Name = "Demo-Instance"
  }
}

