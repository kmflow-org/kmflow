module "vpc" {
  source = "../../modules/vpc"

  env                 = "dev"
  vpc_name            = var.vpc_name
  cidr_block          = var.cidr_block
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones  = var.availability_zones
}

#module "quizengine" {
#  source = "../../modules/quizengine"
#  prefix = "quizengine"
#  env = "dev"
#  vpc_id = module.vpc.vpc_id
#  public_subnet_ids = module.vpc.public_subnet_ids
#  private_subnet_ids = module.vpc.private_subnet_ids
#  release_version = "release-v1"
#}

module "iams3" {
  source = "../../modules/basic"
}

