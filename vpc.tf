module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "vpc-terraform-aws-github-runner"
  cidr = "10.0.0.0/16"

  azs             = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_dns_hostnames    = true
  enable_nat_gateway      = true
  map_public_ip_on_launch = false
  single_nat_gateway      = true

  tags = {
    Environment = local.environment
  }
}

# VPCエンドポイント用セキュリティグループの作成
resource "aws_security_group" "vpc_endpoint_sg" {
  name        = "vpc-endpoint-sg"
  description = "Security group for VPC endpoints for SSM"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    # cidr_blocks = ["10.0.0.0/16"] # VPCのCIDRブロックに合わせて調整
    cidr_blocks = [module.vpc.vpc_cidr_block]
    description = "Allow HTTPS traffic from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "vpc-endpoint-sg"
    Environment = local.environment
  }
}

# VPCエンドポイントの追加
resource "aws_vpc_endpoint" "ssm" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.ap-northeast-1.ssm"
  vpc_endpoint_type = "Interface"

  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]

  private_dns_enabled = true

  tags = {
    Name        = "ssm-endpoint"
    Environment = local.environment
  }
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.ap-northeast-1.ec2messages"
  vpc_endpoint_type = "Interface"

  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]

  private_dns_enabled = true

  tags = {
    Name        = "ec2messages-endpoint"
    Environment = local.environment
  }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.ap-northeast-1.ssmmessages"
  vpc_endpoint_type = "Interface"

  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]

  private_dns_enabled = true

  tags = {
    Name        = "ssmmessages-endpoint"
    Environment = local.environment
  }
}
