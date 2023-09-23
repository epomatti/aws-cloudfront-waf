terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.17.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  project_name = "saturn5"
}

# Resources

module "bucket" {
  source       = "./modules/s3/bucket"
  project_name = local.project_name
}

module "vpc" {
  source       = "./modules/vpc"
  project_name = local.project_name
}

module "elb" {
  source  = "./modules/elb"
  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.subnets
}

module "waf" {
  source        = "./modules/waf"
  country_codes = var.waf_country_codes
  rate_limit    = var.waf_rate_limit
}

module "cloudfront" {
  source                      = "./modules/cloudfront"
  project_name                = local.project_name
  bucket_regional_domain_name = module.bucket.bucket_regional_domain_name
  elb_dns_name                = module.elb.dns_name
  elb_auth_header             = module.elb.auth_header
  waf_arn                     = module.waf.arn
  country_codes               = var.waf_country_codes
}

module "oai" {
  source                 = "./modules/s3/oai"
  cloudfront_oai_iam_arn = module.cloudfront.oai_iam_arn
  bucket_arn             = module.bucket.bucket_arn
  bucket_id              = module.bucket.bucket_id
}
