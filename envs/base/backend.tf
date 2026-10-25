terraform {
  backend "s3" {
    bucket       = "aws-learn-tfstate-334744076111"
    key          = "envs/base/terraform.tfstate"
    region       = "ap-northeast-1"
    encrypt      = true
    use_lockfile = true
  }
}
