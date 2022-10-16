provider "aws" {
  region     = "us-west-2"
  access_key = "Change Me" // Dont ever commit your credentials
  secret_key = "Change Me" // Dont ever commit your credentials
}

module "group_project_one" {
  source = "../../module/setup"
}