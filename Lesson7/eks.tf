#Deploy the EBS CSI Driver Addon In your EKS module’s addons map:
cluster_addons = {
  # aws-ebs-csi-driver = {
  #   most_recent                 = true
  #   service_account_role_arn    = aws_iam_role.ebs_csi.arn
  #   resolve_conflicts_on_create = "OVERWRITE"
  #   resolve_conflicts_on_update = "OVERWRITE"
  # }
# … other addons …
}
