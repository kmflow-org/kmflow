provider "aws" {
  profile  = "kmflowdev"
  region   = "us-west-2"
}

resource "aws_s3_bucket" "state" {
  bucket = "kmflow-infra-state"
}
