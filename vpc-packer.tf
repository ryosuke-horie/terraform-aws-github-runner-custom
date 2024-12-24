module "packer_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "vpc-terraform-packer"
  cidr = "10.1.0.0/16"

  azs            = ["ap-northeast-1a", "ap-northeast-1c"]
  public_subnets = ["10.1.101.0/24", "10.1.102.0/24"]

  enable_dns_hostnames    = true
  enable_nat_gateway      = false
  map_public_ip_on_launch = true
  single_nat_gateway      = false

  tags = {
    Environment = local.environment
  }
}

# SSHアクセス用のセキュリティグループを作成
resource "aws_security_group" "vpc_packer_sg" {
  name        = "vpc-packer-sg"
  description = "Security group for Packer"
  vpc_id      = module.packer_vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH access from anywhere (temporary)"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "vpc-packer-sg"
    Environment = local.environment
  }
}

# 出力変数を定義
output "packer_security_group_id" {
  description = "Security Group ID for Packer"
  value       = aws_security_group.vpc_packer_sg.id
}

output "packer_subnet_id" {
  description = "Public Subnet ID for Packer"
  value       = module.packer_vpc.public_subnets[0]
}
