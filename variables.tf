
variable "region" {
  type        = string
  description = "aws region to deploy into"
}
variable "az_zones" {
  type    = list(string)
}

variable "private_subnets" {
  type    = list(string)
}


variable "public_subnets" {
  type    = list(string)
}

variable "environment" {
  type        = string
  description = "demo"
  default     = "demo"
}

variable "cidr" {
  type        = string
  description = "CIDR"
}

variable "cluster_name" {
  type        = string
  description = "name_of_cluster"
}


# variable "eks_user" {
#   type        = string
#   description = "eks_admin"
# }

