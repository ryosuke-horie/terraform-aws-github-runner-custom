module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "vpc-terraform-aws-github-runner"
  cidr = "10.0.0.0/16"

  azs             = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_dns_hostnames = true
  # 以下を有効化すればNAT Gatewayが利用可能
  # 有効化したらnat, eipの設定は利用しない。
  #   enable_nat_gateway      = true
  #   map_public_ip_on_launch = false
  #   single_nat_gateway      = true

  tags = {
    Environment = local.environment
  }
}

module "nat" {
  source = "int128/nat-instance/aws"

  name                        = "main"
  vpc_id                      = module.vpc.vpc_id
  public_subnet               = module.vpc.public_subnets[0]
  private_subnets_cidr_blocks = module.vpc.private_subnets_cidr_blocks
  private_route_table_ids     = module.vpc.private_route_table_ids
}

resource "aws_eip" "nat" {
  network_interface = module.nat.eni_id
  tags = {
    "Name" = "nat-instance-main"
  }
}
