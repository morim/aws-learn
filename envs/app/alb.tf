# =============================================================
# ALB（都度作成）とパスベースルーティング
#   /           → nginx（EC2 の 80 番。インスタンス ID と AZ を表示）
#   /whoami*    → traefik/whoami（EC2 の 8080 番。リクエストの中身を表示）
# =============================================================

resource "aws_lb" "main" {
  name               = "${var.project}-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [local.base.alb_security_group_id]
  subnets            = values(local.base.public_subnet_ids)

  drop_invalid_header_fields = true

  tags = { Name = "${var.project}-alb" }
}

resource "aws_lb_target_group" "nginx" {
  name     = "${var.project}-nginx"
  port     = 80
  protocol = "HTTP"
  vpc_id   = local.base.vpc_id

  # 毎回作って消すので、登録解除の待ち時間を既定の 300 秒から短くする
  deregistration_delay = 30

  health_check {
    path                = "/"
    matcher             = "200"
    interval            = 15
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group" "whoami" {
  name     = "${var.project}-whoami"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = local.base.vpc_id

  deregistration_delay = 30

  health_check {
    path                = "/health"
    matcher             = "200"
    interval            = 15
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx.arn
  }
}

resource "aws_lb_listener_rule" "whoami" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  condition {
    path_pattern {
      values = ["/whoami", "/whoami/*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.whoami.arn
  }
}

# 2 台の EC2 を両方のターゲットグループに登録する
resource "aws_lb_target_group_attachment" "nginx" {
  for_each = aws_instance.app

  target_group_arn = aws_lb_target_group.nginx.arn
  target_id        = each.value.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "whoami" {
  for_each = aws_instance.app

  target_group_arn = aws_lb_target_group.whoami.arn
  target_id        = each.value.id
  port             = 8080
}
