resource "aws_vpc" "packer_vpc" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "new-packer-vpc"
  }
}

resource "aws_internet_gateway" "new_igw" {
  vpc_id = aws_vpc.packer_vpc.id

  tags = {
    Name = "new-packer-igw"
  }
}

resource "aws_subnet" "new_public_subnet" {
  vpc_id                  = aws_vpc.packer_vpc.id
  cidr_block              = "10.1.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "new-packer-public-subnet"
  }
}

resource "aws_route_table" "new_public_rt" {
  vpc_id = aws_vpc.packer_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.new_igw.id
  }

  tags = {
    Name = "new-packer-public-rt"
  }
}

resource "aws_route_table_association" "new_public_rt_association" {
  subnet_id      = aws_subnet.new_public_subnet.id
  route_table_id = aws_route_table.new_public_rt.id
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow-ssh"
  description = "Allow SSH access"
  vpc_id      = aws_vpc.packer_vpc.id

  ingress {
    description = "Allow SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}
