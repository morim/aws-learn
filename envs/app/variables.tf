variable "region" {
  description = "AWS リージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "project" {
  description = "リソース名の接頭辞"
  type        = string
  default     = "aws-learn"
}

variable "state_bucket" {
  description = "envs/base の state が入っている S3 バケット"
  type        = string
  default     = "aws-learn-tfstate-334744076111"
}

variable "instance_type" {
  description = "EC2 のインスタンスタイプ"
  type        = string
  default     = "t3.micro"
}

variable "nat_az" {
  description = "NAT Gateway を置く AZ のキー（1 台だけなので片方の AZ に置く）"
  type        = string
  default     = "a"
}
