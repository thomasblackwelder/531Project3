provider "aws" {
  region     = "us-west-2"
  access_key = "Change Me"
  secret_key = "Change Me"
}

module "group_project_one" {
  source = "../../module/setup"
}