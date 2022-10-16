// Local Variables
locals {
  repo_name = "moviesgit2.0"
  tags = {
    env              = var.env
    project-name     = "aws-project-1"
    data-sensitivity = "public"
    repo             = "https://github.com/smurthw8/moviesgit2.0"
  }
}

// Dev or Prd
variable "env" {
  type = string
}

// VPC
resource "aws_vpc" "vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  tags = local.tags
}

// Basic internet gateway
resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id
  tags = local.tags
}

// Allow all external traffic
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.ig.id
  }

  tags = local.tags
}

// Public subnet 1
resource "aws_subnet" "pub-sub1"{
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  tags = local.tags
}

// Private subnet 2
resource "aws_subnet" "pri-sub1"{
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-west-2b"

  tags = local.tags
}

// Private subnet 3
resource "aws_subnet" "pri-sub2"{
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-west-2c"

  tags = local.tags
}

resource "aws_route_table_association" "ta"{
  subnet_id = aws_subnet.pub-sub1.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "server-sg" {
  name        = "allow_server_trafic"
  description = "Allow internet traffic to our server"
  vpc_id      = aws_vpc.vpc.id


  ingress {
    description      = "API"
    from_port        = 3000
    to_port          = 3000
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  # ingress {
  #   description      = "HTTPS"
  #   from_port        = 443
  #   to_port          = 443
  #   protocol         = "tcp"
  #   cidr_blocks      = ["0.0.0.0/0"]
  # }

  # ingress {
  #   description      = "HTTP"
  #   from_port        = 80
  #   to_port          = 80
  #   protocol         = "tcp"
  #   cidr_blocks      = ["0.0.0.0/0"]
  # }

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
  subnet_id = aws_subnet.pub-sub1.id
  private_ips = ["10.0.1.50"]
  security_groups = [aws_security_group.server-sg.id]
}

resource "aws_eip" "server-ip"{
  vpc = true
  network_interface = aws_network_interface.web-server-ni.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.ig]
}

resource "aws_instance" "web-server"{
  ami = "ami-08e2d37b6a0129927"
  instance_type = "t2.micro"
  availability_zone = "us-west-2a"
  key_name = "lab_key" // Created before we started

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.web-server-ni.id
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update
              curl --silent --location https://rpm.nodesource.com/setup_14.x | sudo bash -
              sudo yum install -y nodejs
              sudo yum install git
              git clone https://github.com/smurthw8/moviesgit2.0.git
              cd moviesgit2.0
              npm install
              node index.js
              EOF
  tags = local.tags
}

resource "aws_db_instance" "mysql-db" {
  allocated_storage    = 10
  db_name              = "movies"
  engine               = "mysql"
  engine_version       = "8.0.30"
  instance_class       = "db.t3.micro"
  username             = "Change Me" // Dont ever commit your credentials
  password             = "Change Me" // Dont ever commit your credentials
  skip_final_snapshot  = true
  db_subnet_group_name  = aws_db_subnet_group.db-subnet-group.name
  vpc_security_group_ids = [aws_security_group.db-sg.id]
  availability_zone = aws_subnet.pri-sub1.availability_zone
}

resource "aws_security_group" "db-sg" {
  name        = "allow_db_traffic"
  description = "Allow ec2 access to db"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description      = "Mysql"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    cidr_blocks      = ["10.0.1.50/32"]
  }

  ingress {
    description      = "Mysql"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    source_security_group_id = aws_security_group.server-sg.id
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

resource "aws_db_subnet_group" "db-subnet-group" {
  name       = "db-subnet-group"
  subnet_ids = [aws_subnet.pri-sub1.id,aws_subnet.pri-sub2.id]
}

resource "aws_network_interface" "db-ni" {
  subnet_id = aws_subnet.pub-sub1.id
  private_ips = ["10.0.2.51"]
  security_groups = [aws_security_group.db-sg.id]
}

resource "aws_s3_bucket" "bucket" {
  bucket = "is-531-pictures-bucket"
  hosted_zone_id = aws_subnet.pub-sub1.id
  acl    = "public-read"
}