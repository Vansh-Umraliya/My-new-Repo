provider "aws" {
   region = "us-east-1"
}

# Generate SSH Key Pair
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create Key Pair in AWS
resource "aws_key_pair" "tf-ec2" {
  key_name   = "tf-ec2"
  public_key = tls_private_key.example.public_key_openssh
}

resource "local_file" "private_key" {
  filename = "/c/Users/vansh/Downloads/tf-ec2.pem"
  content  = tls_private_key.example.private_key_pem
}

# Create VPC
resource "aws_vpc" "demo_vpc" {
  cidr_block = "10.10.0.0/16"
  tags = { Name = "demo-vpc" }
}

# Create Subnet
resource "aws_subnet" "demo_subnet" {
  vpc_id                  = aws_vpc.demo_vpc.id
  cidr_block              = "10.10.1.0/24"
  map_public_ip_on_launch = true
  tags = { Name = "Main" }
}

# Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.demo_vpc.id
  tags = { Name = "main" }
}

# Create Route Table
resource "aws_route_table" "demo_rt" {
  vpc_id = aws_vpc.demo_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = { Name = "demo-rt" }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "demo_rt_asso" {
  subnet_id      = aws_subnet.demo_subnet.id
  route_table_id = aws_route_table.demo_rt.id
}

# Create Security Group
resource "aws_security_group" "demo_sg" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.demo_vpc.id
  tags = { Name = "allow_tls" }
}

# Ingress Rule for IPv4 (Allow HTTPS)
resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.demo_sg.id
  cidr_ipv4         = "0.0.0.0/0"
                                                      