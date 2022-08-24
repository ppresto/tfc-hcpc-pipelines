#terraform {
##  required_version = ">= 0.12.26"
#
#  required_providers {
#    aws = ">= 2.24"
#  }
#}

terraform {
  required_version = ">= 1.1.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.74.1"
    }
  }
}