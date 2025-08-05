#Deploy the EBS CSI Driver Addon In your EKS module’s addons map:
cluster_addons = {
  aws-ebs-csi-driver = {
   most_recent                 = true
   service_account_role_arn    = aws_iam_role.ebs_csi.arn
   resolve_conflicts_on_create = "OVERWRITE"
   resolve_conflicts_on_update = "OVERWRITE"
 }
# … other addons …
}

# Role for EBS CSI driver
resource "aws_iam_role" "ebs_csi" {
  name               = "${local.prefix}-ebs-csi"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          }
        }
      }
    ]
  })

  tags = local.default_tags
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}
