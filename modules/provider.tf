terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.45.0"
    }

  }
}


#source = "git::https://github.com/ischoi77/spcv2.git//modules/<리소스>"