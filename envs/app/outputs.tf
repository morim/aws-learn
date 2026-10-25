output "nginx_url" {
  description = "nginx（再読み込みすると 2 台に振り分けられる）"
  value       = "http://${aws_lb.main.dns_name}/"
}

output "whoami_url" {
  description = "traefik/whoami（パスベースルーティング）"
  value       = "http://${aws_lb.main.dns_name}/whoami"
}

output "instance_ids" {
  description = "SSM Session Manager で接続するときに使う"
  value       = { for k, i in aws_instance.app : k => i.id }
}
