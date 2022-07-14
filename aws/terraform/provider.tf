provider "aws" {
  region                   = var.aws_region
  shared_credentials_files = [pathexpand("~/.aws/credentials")]
  profile                  = var.aws_profile
}