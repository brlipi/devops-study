terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

  required_version = ">= 1.10"
  backend "s3" {
    bucket = "devops-study-485218921308-us-east-1-an"
    key = "devops-study-485218921308-us-east-1-an/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
    use_lockfile = true
  }
}
