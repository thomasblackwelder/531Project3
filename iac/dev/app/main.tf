terraform {
  backend "s3" {
    bucket         = "terraform-state-is531-group"
    dynamodb_table = "terraform-state-locking"
    key            = "project1/dev/app.tfstate"
    region         = "us-west-2"
  }
}

provider "aws" {
  region     = "us-west-2"
  access_key = "Change Me" //Dont ever commit your credentials
  secret_key = "Change Me" //Dont ever commit your credentials
}

module "group_project_one" {
  source = "../../module/app"
  env    = "dev"
}

