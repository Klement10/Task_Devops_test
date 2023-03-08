# PROVIDER BLOCK
terraform {
required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.23"
    }
  }
  required_version = ">= 1.2.0"

# Backup in S3 before that, create a bucket manually
  backend "s3" {
    bucket              = "mycomponents-tfstate1"
    key                 = "state/terraform.tfstate"
    region              = "us-east-1"
    encrypt             = true
 }
}
provider "aws" {
 region  = "us-east-1"
    shared_credentials_files = ["$HOME/.aws/credentials"]
    profile                  = var.prof
}

# VPC BLOCK

# creating VPC
resource "aws_vpc" "main" {
   cidr_block       = var.vpc-cidr

   tags = {
      name = "custom-vpc"
   }
}


# public subnet 1
resource "aws_subnet" "public-1" {   
   vpc_id            = aws_vpc.main.id
   cidr_block        = var.public-1
   availability_zone = var.az1

   tags = {
      name = "public-1"
   }
}


# public subnet 2
resource "aws_subnet" "public-2" {  
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public-2
  availability_zone = var.az2

  tags = {
     name = "public-2"
  }
}


# private subnet 1
resource "aws_subnet" "private-1" {   
   vpc_id            = aws_vpc.main.id
   cidr_block        = var.private-1
   availability_zone = var.az1

   tags = {
      name = "private-1"
   }
}


# private subnet 2
resource "aws_subnet" "private-2" {   
   vpc_id            = aws_vpc.main.id
   cidr_block        = var.private-2
   availability_zone = var.az2

   tags = {
      name = "private-2"
   }
}

#creating gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

# creating route table for public
resource "aws_route_table" "pubrt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    name = "pubic rt"
  }
}

# associate route table to the public subnet 1
resource "aws_route_table_association" "public-rt1" {
  subnet_id      = aws_subnet.public-1.id
  route_table_id = aws_route_table.pubrt.id
}

 
# associate route table to the public subnet 2
resource "aws_route_table_association" "public-rt2" {
  subnet_id      = aws_subnet.public-2.id
  route_table_id = aws_route_table.pubrt.id
}

#Elastic ip for NAT
resource "aws_eip" "elastic" {
  vpc      = true
  
  tags = {
    Name = "Nat gateway eip"
  }

  depends_on = [aws_internet_gateway.gw]
}

#Creating NAT gateway
resource "aws_nat_gateway" "ntgw" {
  allocation_id = aws_eip.elastic.id
  subnet_id     = aws_subnet.public-1.id

  tags = {
    Name = "nat gw"
  }

 depends_on = [aws_internet_gateway.gw]
}

# creating route table for private sub
resource "aws_route_table" "privrt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ntgw.id
  }

  tags = {
    name = "private rt"
  }
}

# associate route table to the private subnet 1
resource "aws_route_table_association" "private-rt1" {
  subnet_id      = aws_subnet.private-1.id
  route_table_id = aws_route_table.privrt.id
}

 
# associate route table to the private subnet 2
resource "aws_route_table_association" "private-rt2" {
  subnet_id      = aws_subnet.private-2.id
  route_table_id = aws_route_table.privrt.id
}

# SECURITY BLOCK

# custom vpc security group 
resource "aws_security_group" "websg" {
  name        = "web-sg"
  description = "allow inbound HTTP traffic"
  vpc_id      = aws_vpc.main.id

  # HTTP from vpc
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   
    # allow inbound ssh traffic 
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #only for the test task
  }

   # allow inbound icmp traffic 
  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound rules
  # internet access to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    name = "web_sg"
  }
}

# web tier security group
resource "aws_security_group" "webserver-sg" {
  name        = "webserver-sg"
  description = "allow inbound traffic from ALB"
  vpc_id      = aws_vpc.main.id

  # allow inbound traffic from web
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.websg.id]
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    name = "webserver-sg"
  }
}
# database security group
resource "aws_security_group" "database-sg" {
  name        = "databasesg"
  description = "allow inbound traffic from ALB"
  vpc_id      = aws_vpc.main.id

  # allow traffic from ALB 
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #only for the test task
  }

  egress {
    from_port   = 32768
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    name = "database-sg"
  }
}

# INSTANCES BLOCK - EC2 and DATABASE

# 1st ec2 instance on public subnet 1
resource "aws_instance" "ec2-1" {
  ami                    = var.ec2_instance_ami
  instance_type          = var.ec2_instance_type
  availability_zone      = var.az1
  subnet_id              = aws_subnet.public-1.id
  key_name               = "terra"
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.websg.id]

  tags = {
    name = "ec2-1"
  }

  depends_on = [aws_internet_gateway.gw]
}

# 2nd ec2 instance on private subnet 2
resource "aws_instance" "ec2-2" {
  ami                    = var.ec2_instance_ami
  instance_type          = var.ec2_instance_type
  availability_zone      = var.az2
  subnet_id              = aws_subnet.private-2.id
  key_name               = "terra"
  vpc_security_group_ids = [aws_security_group.websg.id]
  
  tags = {
    name = "ec2-2"
  }

  depends_on = [aws_nat_gateway.ntgw]
}


# RDS subnet group
resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = [aws_subnet.private-1.id, aws_subnet.private-2.id]

  tags = {
    name = "rds-subnet-gr"
  }
}

# RDS database on mysql engine
resource "aws_db_instance" "my-db" {
  allocated_storage      = 10
  db_subnet_group_name   = aws_db_subnet_group.default.id
  engine                 = var.db_engine
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  multi_az               = false
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.database-sg.id]
}

# ALB BLOCK

# alb target group
resource "aws_lb_target_group" "external-targ" {
  name        = "external-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
}

resource "aws_lb_target_group_attachment" "ec2-1targ" {
  target_group_arn  = aws_lb_target_group.external-targ.arn
  target_id         = aws_instance.ec2-1.id
  port              = 80
}

# ALB
resource "aws_lb" "external-ab" {
  name                = "external-ALB"
  internal            = false
  load_balancer_type  = "application"
  security_groups     = [aws_security_group.websg.id]
  subnets             = [aws_subnet.public-1.id,aws_subnet.public-2.id]
   
  tags = {
      name = "external-ALB"
  }
}

# create ALB listener
resource "aws_lb_listener" "alb_listen" {
  load_balancer_arn = aws_lb.external-ab.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type              = "forward"
    target_group_arn  = aws_lb_target_group.external-targ.arn
  }
}

# OUTPUTS

# get the DNS of the load balancer 

output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = "${aws_lb.external-ab.dns_name}"
}

output "db_connect_string" {
  description = "MyRDS database connection string"
  value       = "server=${aws_db_instance.my-db.address}; database=ExampleDB; Uid=${var.db_username}; Pwd=${var.db_password}"
  sensitive   = true
}
