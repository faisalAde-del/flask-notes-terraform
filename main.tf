provider "aws" {
    region = var.aws_region
  }

resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
  
}

resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id

tags = {
    name = var.project_name 
}
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = var.project_name
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route  {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = {
    Name = var.project_name
  }
}
resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}
resource "aws_security_group" "flask_app" {
name = var.project_name
vpc_id = aws_vpc.main.id

ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    from_port        = 5000
    to_port          = 5000
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = var.project_name
  public_key = file(var.public_key_path)
}

locals {
  user_data = templatefile(
    "${path.module}/user_data.sh", 
    {
      github_repo = var.github_repo
      app_name    = var.project_name  
    }
    )
}

resource "aws_instance" "main" {
  ami           = "ami-08982f1c5bf93d976"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.flask_app.id]
  associate_public_ip_address = true
  user_data = local.user_data
  key_name = aws_key_pair.deployer.key_name

  tags = {
    Name = var.project_name
  }
}

















# provisioner "remote-exec" {
#     inline = [
#         "cloud-init status --wait"
#     ]
#     connection {
#         type = "ssh"
#         user = "ec2-user"
#         private_key = file(var.private_key_path)
#         host = self.public.ip
#         timeout = "10m"
#     }
# }