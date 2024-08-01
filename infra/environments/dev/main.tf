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
  acm_certificate_arn = "Paste your own cert arn here"
  release_version = "release-v1"
}
