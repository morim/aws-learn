# =============================================================
# NAT Gateway（都度作成。1 時間あたりの料金がかかる）
# app サブネットの EC2 が、パッケージや Docker イメージを取りに行くために使う
# =============================================================

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = { Name = "${var.project}-nat" }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = local.base.public_subnet_ids[var.nat_az]

  tags = { Name = "${var.project}-nat" }
}

# envs/base の app ルートテーブルに、インターネット向けの経路を追加する
# destroy すると、この経路だけが消え、ルートテーブル自体は残る
resource "aws_route" "app_to_nat" {
  route_table_id         = local.base.app_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}
