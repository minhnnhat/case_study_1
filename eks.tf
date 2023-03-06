locals {
  cluster_name = "case_study_1"
  tags = {
    Terraform   = "true"
    Project     = local.cluster_name
    Environment = local.cluster_name
    Cluster     = local.cluster_name
  }

  # Used to determine correct partition (i.e. - `aws`, `aws-gov`, `aws-cn`, etc.)
  partition = data.aws_partition.current.partition
}

#############################################
#                   EKS                     #
#############################################
module "eks" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.25.0"

  # EKS CLUSTER
  cluster_name    = local.cluster_name
  cluster_version = var.eks_version

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  enable_irsa = true

  ##EKS MANAGED NODE GROUPS
  managed_node_groups = {
    az1a = {
      node_group_name = "az1a"
      instance_types  = ["t3a.medium", "t3.medium"]
      min_size        = 1
      desired_size    = 1
      max_size        = 3
      capacity_type   = "SPOT"
      subnet_ids      = [module.vpc.private_subnets[0]]

      create_iam_role = false
      iam_role_arn    = aws_iam_role.managed_ng.arn

      create_launch_template = true
      remote_access          = false
      ec2_ssh_key            = ""
      ssh_security_group_id  = ""
      enable_monitoring      = false

      block_device_mappings = [
        {
          device_name           = "/dev/xvda"
          volume_type           = "gp3"
          volume_size           = 50
          delete_on_termination = true
        }
      ]
      k8s_labels = merge(
        local.tags,
        {
          Zone = "az1a"
        }
      )

      additional_tags = merge(
        local.tags,
        {
          Zone = "az1a"
        }
      )

      launch_template_tags = merge(
        local.tags,
        {
          Name = "eks-${local.cluster_name}"
          Zone = "az1a"
        }
      )
    }
    az1b = {
      node_group_name = "az1b"
      instance_types  = ["t3a.medium", "t3.medium"]
      min_size        = 1
      desired_size    = 1
      max_size        = 3
      capacity_type   = "SPOT"
      subnet_ids      = [module.vpc.private_subnets[1]]

      create_iam_role = false
      iam_role_arn    = aws_iam_role.managed_ng.arn

      create_launch_template = true
      remote_access          = false
      ec2_ssh_key            = ""
      ssh_security_group_id  = ""
      enable_monitoring      = false

      block_device_mappings = [
        {
          device_name           = "/dev/xvda"
          volume_type           = "gp3"
          volume_size           = 50
          delete_on_termination = true
        }
      ]
      k8s_labels = merge(
        local.tags,
        {
          Zone = "az1b"
        }
      )

      additional_tags = merge(
        local.tags,
        {
          Zone = "az1b"
        }
      )

      launch_template_tags = merge(
        local.tags,
        {
          Name = "eks-${local.cluster_name}"
          Zone = "az1b"
        }
      )
    }
    az1c = {
      node_group_name = "az1c"
      instance_types  = ["t3a.medium", "t3.medium"]
      min_size        = 1
      desired_size    = 1
      max_size        = 3
      capacity_type   = "SPOT"
      subnet_ids      = [module.vpc.private_subnets[2]]

      create_iam_role = false
      iam_role_arn    = aws_iam_role.managed_ng.arn

      create_launch_template = true
      remote_access          = false
      ec2_ssh_key            = ""
      ssh_security_group_id  = ""
      enable_monitoring      = false

      block_device_mappings = [
        {
          device_name           = "/dev/xvda"
          volume_type           = "gp3"
          volume_size           = 50
          delete_on_termination = true
        }
      ]
      k8s_labels = merge(
        local.tags,
        {
          Zone = "az1c"
        }
      )

      additional_tags = merge(
        local.tags,
        {
          Zone = "az1c"
        }
      )

      launch_template_tags = merge(
        local.tags,
        {
          Name = "eks-${local.cluster_name}"
          Zone = "az1c"
        }
      )
    }
  }
  node_security_group_additional_rules = {
    # Extend node-to-node security group rules. Recommended and required for the Add-ons
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    # Recommended outbound traffic for Node groups
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

    # Allows Control Plane Nodes to talk to Worker nodes on all ports. Added this to avoid issues with Add-ons communication with Control plane.
    # This can be restricted further to specific port based on the requirement for each Add-on e.g., metrics-server 4443, spark-operator 8080, karpenter 8443 etc.
    # Change this according to your security requirements if needed

    ingress_cluster_to_node_all_traffic = {
      description                   = "Cluster API to Nodegroup all traffic"
      protocol                      = "-1"
      from_port                     = 0
      to_port                       = 0
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }
}

#############################################
#     Custom IAM roles for Node Groups      #
#############################################
data "aws_iam_policy_document" "managed_ng_assume_role_policy" {
  statement {
    sid = "EKSWorkerAssumeRole"

    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "managed_ng" {
  name                  = "managed-node-role"
  description           = "EKS Managed Node group IAM Role"
  assume_role_policy    = data.aws_iam_policy_document.managed_ng_assume_role_policy.json
  path                  = "/"
  force_detach_policies = true
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]

  tags = local.tags
}

resource "aws_iam_instance_profile" "managed_ng" {
  name = "managed-node-instance-profile"
  role = aws_iam_role.managed_ng.name
  path = "/"

  lifecycle {
    create_before_destroy = true
  }

  tags = local.tags
}

#############################################
#             Kubernetes Add-ons            #
#############################################
module "eks_kubernetes_addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons?ref=v4.25.0"

  eks_cluster_id = module.eks.eks_cluster_id

  # EKS Addons
  enable_amazon_eks_vpc_cni            = true
  enable_amazon_eks_coredns            = true
  enable_amazon_eks_kube_proxy         = true
  enable_amazon_eks_aws_ebs_csi_driver = true

  # ArgoCD
  enable_argocd         = true
  argocd_manage_add_ons = true
  argocd_helm_config = {
    name             = "argo-cd"
    chart            = "argo-cd"
    repository       = "https://argoproj.github.io/argo-helm"
    version          = "5.24.1"
    namespace        = "platform"
    timeout          = "1200"
    create_namespace = true
    values = [templatefile("${path.module}/bootstrap/argo.tftpl", {
      GIT_URL = var.repo_url
    })]
    set_sensitive = [
      {
        name  = "configs.secret.argocdServerAdminPassword"
        value = var.argo_password
      }
    ]
  }

  argocd_applications = {
    addons = {
      path               = "add-ons/chart"
      repo_url           = "https://github.com/minhnnhat/case_study_1.git"
      project            = "default"
      add_on_application = true // This indicates the root add-on application.
    }
    # workloads = {
    #   path                = "dev"
    #   repo_url            = "git@github.com:minhnnhat/workloads.git"
    # }
  }
}