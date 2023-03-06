#############################################
#                   VPC                     #
#############################################
vpcs = [
  {
    name            = "vpc",
    cidr_block      = "172.16.0.0/16"
    azs             = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
    public_subnets  = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"],
    private_subnets = ["172.16.5.0/24", "172.16.6.0/24", "172.16.7.0/24"],
    eks_subnets     = ["172.16.9.0/24", "172.16.10.0/24", "172.16.11.0/24"],
  }
]

#############################################
#                   EKS                     #
#############################################
eks_version     = "1.25"
repo_url                    = "https://github.com/minhnnhat/case_study_1.git"
argo_password               = "$2a$12$6mV8p7OJDDQa7o.YfvEcauH/iLdIgm2ZRYJ8fkpXXAsYTfBEIIWBO" # https://bcrypt-generator.com/ : "newhacker"

