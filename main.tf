terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.39.1"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

# Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.15.0.0/16"

   tags = {
    Name = "demo_Vpc"
  }
}
#creating a aws_subnet

resource "aws_subnet" "pub_subnet1" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.15.1.0/24"
  availability_zone = "us-east-2b"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "my-pub-sub1"
  }
}

resource "aws_subnet" "pub_subnet2" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.15.2.0/24"
  availability_zone = "us-east-2a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "my-pub-sub2"
  }
}
#creating an internet gateway

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my_igw"
  }
}

#Public route table

resource "aws_route_table" "pub_rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }


  tags = {
    Name = "pub route table"
  }
}

#attaching the subnets to the aws_route_table

resource "aws_route_table_association" "a_public_subnet" {
  subnet_id      = aws_subnet.pub_subnet1.id
  route_table_id = aws_route_table.pub_rt.id
}

resource "aws_route_table_association" "b_public_subnet" {
  subnet_id     = aws_subnet.pub_subnet2.id
  route_table_id = aws_route_table.pub_rt.id
}




# creating an Instance

data "aws_ami" "Amazonlinux2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023.3.20240219.0-kernel-6.1-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Canonical
}




#creating security groups

resource "aws_security_group" "allow_tcp" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic "
  vpc_id      = aws_vpc.my_vpc.id


ingress{
    description= "TLS from VPC"
    from_port=22
    to_port=22
    protocol="tcp"
    cidr_blocks =["0.0.0.0/0"]
}

egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "ssh_allow_tls"
  }
}


resource "aws_instance" "pub_server" {
  ami    = data.aws_ami.Amazonlinux2.id
  subnet_id = aws_subnet.pub_subnet1.id
  instance_type = "t3.micro"
  key_name = "terraform"

security_groups = ["${aws_security_group.allow_tcp.id}"]

  tags = {
    Name = "public_server" 
}
}

