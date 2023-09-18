#------------------------------------------------------------------------------
# EKS
#------------------------------------------------------------------------------

# EKS Role
resource "aws_iam_role" "eks_fargate_execution" {
  name               = "${local.name}-eks-fargate-execution"
  assume_role_policy = data.aws_iam_policy_document.eks_fargate_execution.json
  tags               = local.tags
}

# EKS Role: AssumeRole Principals
data "aws_iam_policy_document" "eks_fargate_execution" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "eks-fargate-pods.amazonaws.com",
      ]
    }
  }
}

# EKS Role: Policy Attachments
resource "aws_iam_policy_attachment" "eks_fargate_execution" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess",
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite",
    #aws_iam_policy.eks_ec2_describe.arn
  ])

  name       = "${local.name}-eks-fargate-execution"
  roles      = [aws_iam_role.eks_fargate_execution.name]
  policy_arn = each.value
}

# EKS Role: EC2 Describe Policy
data "aws_iam_policy_document" "eks_ec2_describe" {
  #checkov:skip=CKV_AWS_356: "Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions"

  statement {
    actions = [
      "ec2:Describe*",
    ]
    effect    = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_policy" "eks_ec2_describe" {
  name   = "${local.name}-eks-ec2-describe"
  policy = data.aws_iam_policy_document.eks_ec2_describe.json
}
