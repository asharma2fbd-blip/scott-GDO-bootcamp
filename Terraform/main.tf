terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

# 1. Dynamically retrieve the Golden AMI baked by Packer in Task 5
data "aws_ami" "packer_golden_image" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["gdo-bootcamp-golden-image-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# 2. Security Group for the Web Server (EC2)
resource "aws_security_group" "web_sg" {
  name        = "gdo-bootcamp-web-sg"
  description = "Security group for GDO Bootcamp Web Server"

  ingress {
    description = "Allow inbound HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip]
  }

  ingress {
    description = "Allow inbound SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip]
  }

  ingress {
    description = "Allow inbound Jenkins UI strictly from authorized IP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "gdo-bootcamp-web-sg"
    Project = "GDO-Bootcamp"
    Task    = "7"
  }
}

# 3. Security Group for the Managed Database (RDS)
resource "aws_security_group" "rds_sg" {
  name        = "gdo-bootcamp-rds-sg"
  description = "Security group for GDO Bootcamp RDS instance"

  ingress {
    description     = "Allow MySQL/MariaDB from Web Security Group only"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "gdo-bootcamp-rds-sg"
    Project = "GDO-Bootcamp"
    Task    = "6"
  }
}

# 4. Provision the EC2 Instance using the Packer Golden AMI
resource "aws_instance" "web_instance" {
  ami                    = data.aws_ami.packer_golden_image.id
  instance_type          = "t2.micro"
  key_name               = "gdo-shared-key"
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name    = "GDO-Bootcamp-Terraform-Web"
    Project = "GDO-Bootcamp"
    Task    = "6"
  }
}

# 5. Provision the Managed RDS Database
resource "aws_db_instance" "rds_instance" {
  identifier             = "gdo-bootcamp-db-tf"
  allocated_storage      = 20
  max_allocated_storage  = 20
  storage_type           = "gp2"
  engine                 = "mariadb"
  engine_version         = "10.5"
  instance_class         = "db.t3.micro"
  username               = var.db_username
  password               = var.db_password
  publicly_accessible    = false
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  tags = {
    Name    = "gdo-bootcamp-db-tf"
    Project = "GDO-Bootcamp"
    Task    = "6"
  }
}

# 6. Outputs
output "web_public_ip" {
  description = "Public IP address of the provisioned web server"
  value       = aws_instance.web_instance.public_ip
}

output "rds_endpoint" {
  description = "Connection endpoint of the managed RDS database"
  value       = aws_db_instance.rds_instance.endpoint
}

# 7. Variables Declaration
variable "db_username" {
  description = "RDS master username"
  type        = string
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

# Add this variable at the bottom of main.tf with your other variables:
variable "admin_ip" {
  description = "Authorized administrative public IP address in CIDR format"
  type        = string
}
