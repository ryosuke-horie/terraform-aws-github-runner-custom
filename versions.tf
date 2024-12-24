terraform {
  required_version = ">= 1.0.0"

  # tfstateを管理するリモートバックエンド
  backend "s3" {
    bucket = "s3-remote-backend" # 手動作成したS3バケット名
    key    = "remote-backend/terraform.tfstate"
    region = "ap-northeast-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.75.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}
