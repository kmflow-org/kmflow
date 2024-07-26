module "vpc" {
  source = "../../modules/vpc"

  env                 = "dev"
  vpc_name            = var.vpc_name
  cidr_block          = var.cidr_block
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones  = var.availability_zones
}

module "quizengine" {
  source = "../../modules/quizengine"
  prefix = "quizengine"
  env = "dev"
  vpc_id = module.vpc.vpc_id
  acm_certificate_arn = "arn:aws:acm:us-west-2:533675705859:certificate/859d7444-67cc-4bfb-b6ac-00397e0c3556"
  release_version = "release-v1"
}
