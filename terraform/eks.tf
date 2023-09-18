#------------------------------------------------------------------------------
# EKS
#------------------------------------------------------------------------------
module "eks" {
  #checkov:skip=CKV_TF_1: "Ensure Terraform module sources use a commit hash" | This is delibrate.

  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.0"

  cluster_name                    = "${local.name}-cluster"
  cluster_version                 = var.cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  cluster_addons = {
    kube-proxy = {}
    vpc-cni    = {}
    coredns = {
      configuration_values = jsonencode({
        computeType = "Fargate"
      })
    }
  }

  create_kms_key = false
  cluster_encryption_config = [{
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }]

  # Fargate profiles use the cluster primary security group so these are not utilized
  create_cluster_security_group = false
  create_node_security_group    = false

  fargate_profiles = merge(
    {
      default = {
        name = "default"
        selectors = [
          {
            namespace = "backend"
            labels = {
              Application = "backend"
            }
          },
          {
            namespace = "app-*"
            labels = {
              Application = "app-wildcard"
            }
          }
        ]

        # Use specific subnets instead of the subnets supplied for the cluster itself
        # subnet_ids = [module.vpc.private_subnets[1]]

        tags = merge(local.tags, {
          Owner = "secondary"
        })

        timeouts = {
          create = "20m"
          delete = "20m"
        }
      }
    },
    { for i in range(3) :
      "kube-system-${element(split("-", local.azs[i]), 2)}" => {
        selectors = [
          { namespace = "kube-system" }
        ]
        # Create a profile per AZ for high availability
        subnet_ids = [element(module.vpc.private_subnets, i)]
      }
    }
  )

  tags = local.tags
}

resource "aws_kms_key" "eks" {
  #checkov:skip=CKV2_AWS_64: "Ensure KMS key Policy is defined"

  description             = "${local.name} EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = local.tags
}
