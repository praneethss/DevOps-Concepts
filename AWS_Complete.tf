provider "aws" {
  region     = "us-east-1"
  access_key = ""
  secret_key = ""
}

## Create Internet Gateway ##
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id
}

## Create custom Route table ##
resource "aws_route_table" "route-1" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

## Create a VPC ##
resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"
}
variable "subnet_prefix" {
  description = "cidr block for the subnet"
}

## Create a subnet ##
resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.prod-vpc.id
  cidr_block = var.subnet_prefix

  tags = {
    Name = "Prod-Subnet"
  }
}

## Associate subnet with route table ##
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.route-1.id
}

## Create security group to allow port 80,22,443 ##
resource "aws_security_group" "allow_web_traffic" {
  name        = "allow_web"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description      = "HTTP"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "HTTPS"
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

  tags = {
    Name = "allow_tls"
  }
}

## Create a network interface id with an ip in the subnet ##
resource "aws_network_interface" "test" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web_traffic.id]
}

## Assign an elastic ip to network interface ##
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.test.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.gw]
}

## Create a ubuntu server ##
resource "aws_instance" "web" {
  ami           = "ami-04505e74c0741db8d"
  instance_type = "t2.micro"
  key_name = "DevOps"

  network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.test.id
  }

  tags = {
    Name = "Terraform-demo"
  }

  user_data = <<-EOF
                #!bin/bash
                sudo apt-get update
                sudo apt-get install default-jdk
                EOF
}

  tags = {
    Name = "Prod"
  }
}
