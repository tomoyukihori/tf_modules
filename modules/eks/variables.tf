variable "aws_region" {
  type        = string
  description = "EKSを作成するリージョン名"
  default     = "ap-northeast-1"
}
variable "vpc-main" {
  type        = string
  description = "EKSをデプロイするVPCの名前"
  default     = "fargate-vpc"
}
