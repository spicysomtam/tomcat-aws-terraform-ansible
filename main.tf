provider "aws" {
  region = "eu-west-1"
}
# Allowing different workspaces/envs is a good idea
locals {
  sk = "tomcat-${terraform.workspace}"
}
