terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  profile  = "kmflowdev"
  region   = "us-west-2"
}

terraform {
  backend "s3" {
    profile = "kmflowdev"
    bucket = "kmflow-infra-state"
    key    = "dev/terraform.tfstate"
    region = "us-west-2"
  }
}
