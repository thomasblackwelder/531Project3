// Local Variables
locals {
  repo_name = "change_me"
  tags = {
    env              = var.env
    project-name     = "aws-project-1"
    data-sensitivity = "public"
    repo             = "https://github.com/byu-oit/${local.repo_name}"
  }
}

// Needed pass in Variables
variable "env" {
  type = string
}

// VPC
resource "aws_vpc" "main_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  tags = local.tags
}

resource "aws_internet_gateway" "prj_gateway" {
  vpc_id = aws_vpc.main_vpc.id
  tags = local.tags
}

resource "aws_route_table" "prj_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.prj_gateway.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.prj_gateway.id
  }

  tags = local.tags
}

resource "aws_subnet" "subnet-public"{
  vpc_id = aws_vpc.main_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  tags = local.tags
}

resource "aws_subnet" "subnet-private"{
  vpc_id = aws_vpc.main_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-west-2b"

  tags = local.tags
}

resource "aws_route_table_association" "table_association_one"{
  subnet_id = aws_subnet.subnet-public.id
  route_table_id = aws_route_table.prj_route_table.id
}

resource "aws_security_group" "server-sg" {
  name        = "allow_server_trafic"
  description = "Allow internet traffic to our server"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "SSH"
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
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = local.tags
}

resource "aws_network_interface" "web-server-ni" {
  subnet_id = aws_subnet.subnet-public.id
  private_ips = ["10.0.1.50"]
  security_groups = [aws_security_group.server-sg.id]
}

resource "aws_eip" "server-ip"{
  vpc = true
  network_interface = aws_network_interface.web-server-ni.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.prj_gateway]
}

resource "aws_instance" "web-server-instance"{
  ami = "ami-08e2d37b6a0129927"
  instance_type = "t2.micro"
  availability_zone = "us-west-2a"
  key_name = "lab_key"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.web-server-ni.id
  }

  user_data = <<-EOF
              #!/bin/bash

              EOF
  tags = local.tags
}



resource "aws_db_instance" "mysql-db" {
  allocated_storage    = 10
  db_name              = "movies"
  engine               = "mysql"
  engine_version       = "8.0.30"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = "password"
  skip_final_snapshot  = true
  
}

resource "aws_security_group" "db-sg" {
  name        = "allow_db_traffic"
  description = "Allow ec2 access to db"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description      = "Mysql"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    cidr_blocks      = ["10.0.1.50/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = local.tags
}

resource "aws_network_interface" "db-ni" {
  subnet_id = aws_subnet.subnet-private.id
  private_ips = ["10.0.1.50"]
  security_groups = [aws_security_group.db-sg.id]
}