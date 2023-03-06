#############################################
#                   IRSA                    #
#############################################
module "cluster_autoscaler_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.2.0"

  role_name                        = "cluster-autoscaler-${local.cluster_name}"
  attach_cluster_autoscaler_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.eks_oidc_provider_arn
      namespace_service_accounts = ["platform:cluster-autoscaler-aws-cluster-autoscaler"]
    }
  }
}

