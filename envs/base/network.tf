# =============================================================
# VPC とサブネット（常設。どれも料金はかからない）
#
#   10.10.0.0/16
#   ├─ public  10.10.0.0/24 (a)  10.10.1.0/24 (c)   ALB、NAT Gateway
#   ├─ app     10.10.10.0/24 (a) 10.10.11.0/24 (c)  EC2（インターネットへは NAT 経由）
#   └─ db      10.10.20.0/24 (a) 10.10.21.0/24 (c)  Aurora 用に予約（外へ出る経路なし）
# =============================================================

locals {
  # a => 0, c => 1 のように、AZ ごとの連番を作る
  az_index = { for i, k in sort(keys(var.azs)) : k => i }

  # サブネットの 3 つ目のオクテットの開始位置
  tier_offset = {
    public = 0
    app    = 10
    db     = 20
  }
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = var.project }
}

# 既定のセキュリティグループは誤って使わないよう、ルールをすべて外しておく
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "${var.project}-default-unused" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = { Name = var.project }
}

resource "aws_subnet" "public" {
  for_each = var.azs

  vpc_id            = aws_vpc.main.id
  availability_zone = each.value
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, local.tier_offset.public + local.az_index[each.key])

  tags = {
    Name = "${var.project}-public-${each.key}"
    Tier = "public"
  }
}

resource "aws_subnet" "app" {
  for_each = var.azs

  vpc_id            = aws_vpc.main.id
  availability_zone = each.value
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, local.tier_offset.app + local.az_index[each.key])

  tags = {
    Name = "${var.project}-app-${each.key}"
    Tier = "app"
  }
}

resource "aws_subnet" "db" {
  for_each = var.azs

  vpc_id            = aws_vpc.main.id
  availability_zone = each.value
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, local.tier_offset.db + local.az_index[each.key])

  tags = {
    Name = "${var.project}-db-${each.key}"
    Tier = "db"
  }
}

# =============================================================
# ルートテーブル
# 経路（route）はルートテーブルの中に書かず、aws_route で別に定義する。
# app 用の 0.0.0.0/0 → NAT Gateway は、NAT を作る都度作成スタック（envs/app）側で追加・削除するため。
# =============================================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "${var.project}-public" }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# NAT Gateway は 1 台だけなので、app サブネット 2 つで 1 つのルートテーブルを共有する
resource "aws_route_table" "app" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "${var.project}-app" }
}

resource "aws_route_table_association" "app" {
  for_each = aws_subnet.app

  subnet_id      = each.value.id
  route_table_id = aws_route_table.app.id
}

resource "aws_route_table" "db" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "${var.project}-db" }
}

resource "aws_route_table_association" "db" {
  for_each = aws_subnet.db

  subnet_id      = each.value.id
  route_table_id = aws_route_table.db.id
}

# =============================================================
# S3 用ゲートウェイエンドポイント（無料）
# app / db サブネットから S3 への通信を NAT を通さずに流し、NAT のデータ処理料金を減らす
# =============================================================

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [
    aws_route_table.app.id,
    aws_route_table.db.id,
  ]

  tags = { Name = "${var.project}-s3" }
}
