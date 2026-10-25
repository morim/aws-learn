# =============================================================
# セキュリティグループ
# ルールは aws_vpc_security_group_*_rule で 1 本ずつ定義する（現在の推奨の書き方）。
# description は AWS に送られるので英語で書く（日本語は ValidationError になる）。
#
#   インターネット ─80→ ALB ─80/8080→ EC2 ─3306→ DB
# =============================================================

# ---------- ALB ----------
resource "aws_security_group" "alb" {
  name        = "${var.project}-alb"
  description = "ALB: HTTP from allowed CIDRs"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${var.project}-alb" }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  for_each = toset(var.allowed_ingress_cidrs)

  security_group_id = aws_security_group.alb.id
  description       = "HTTP from ${each.value}"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  for_each = toset(["80", "8080"])

  security_group_id            = aws_security_group.alb.id
  description                  = "To app port ${each.value}"
  ip_protocol                  = "tcp"
  from_port                    = tonumber(each.value)
  to_port                      = tonumber(each.value)
  referenced_security_group_id = aws_security_group.app.id
}

# ---------- EC2 (app) ----------
# 80: nginx（インスタンス ID・AZ 表示） / 8080: traefik/whoami（Docker）
resource "aws_security_group" "app" {
  name        = "${var.project}-app"
  description = "App EC2: HTTP from ALB only"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${var.project}-app" }
}

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  for_each = toset(["80", "8080"])

  security_group_id            = aws_security_group.app.id
  description                  = "From ALB port ${each.value}"
  ip_protocol                  = "tcp"
  from_port                    = tonumber(each.value)
  to_port                      = tonumber(each.value)
  referenced_security_group_id = aws_security_group.alb.id
}

# パッケージ取得、Docker イメージ取得、SSM 接続のため外向きは全許可（NAT 経由）
resource "aws_vpc_security_group_egress_rule" "app_all" {
  security_group_id = aws_security_group.app.id
  description       = "All outbound via NAT"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# ---------- DB（Aurora 用に先に用意） ----------
resource "aws_security_group" "db" {
  name        = "${var.project}-db"
  description = "Aurora MySQL: from app EC2 only"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${var.project}-db" }
}

resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id            = aws_security_group.db.id
  description                  = "MySQL from app"
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
  referenced_security_group_id = aws_security_group.app.id
}
