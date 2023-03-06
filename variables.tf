#############################################
#                   EKS                     #
#############################################
variable "eks_version" {
  type    = string
  default = "1.25"
}

variable "repo_url" {
  type = string
}

variable "argo_password" {
  type = string
}
