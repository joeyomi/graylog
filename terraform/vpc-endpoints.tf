module "tls_sg" {
  #checkov:skip=CKV_TF_1: "Ensure Terraform module sources use a commit hash" | This is delibrate.

  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "${local.name}-vpc-tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = [module.vpc.vpc_cidr_block, ]
  ingress_rules       = ["https-443-tcp", ]

  egress_rules = ["all-all"]

  tags = local.tags
}

module "vpc_endpoints" {
  #checkov:skip=CKV_TF_1: "Ensure Terraform module sources use a commit hash" | This is delibrate.

  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 5.0"

  vpc_id             = module.vpc.vpc_id
  security_group_ids = [module.tls_sg.security_group_id, ]

  endpoints = {
    ecr_dkr = {
      service             = "ecr.dkr"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags                = { Name = "ecr-dkr-vpc-endpoint" }
    },
    kms = {
      service             = "kms"
      create              = true
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags                = { Name = "kms-vpc-endpoint" }
    },
    secretsmanager = {
      service             = "secretsmanager"
      create              = true
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags                = { Name = "secretsmanager-vpc-endpoint" }
    },
  }

  tags = merge(local.tags, {
    Endpoint = "true"
  })
}
