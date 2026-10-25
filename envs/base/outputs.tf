# envs/app からは terraform_remote_state でこれらの値を読む

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "ALB と NAT Gateway を置くサブネット（AZ キー => ID）"
  value       = { for k, s in aws_subnet.public : k => s.id }
}

output "app_subnet_ids" {
  description = "EC2 を置くサブネット（AZ キー => ID）"
  value       = { for k, s in aws_subnet.app : k => s.id }
}

output "db_subnet_ids" {
  description = "Aurora 用に予約したサブネット（AZ キー => ID）"
  value       = { for k, s in aws_subnet.db : k => s.id }
}

output "app_route_table_id" {
  description = "envs/app が 0.0.0.0/0 → NAT Gateway の経路を追加するルートテーブル"
  value       = aws_route_table.app.id
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "app_security_group_id" {
  value = aws_security_group.app.id
}

output "db_security_group_id" {
  value = aws_security_group.db.id
}

output "ec2_instance_profile_name" {
  value = aws_iam_instance_profile.ec2.name
}
