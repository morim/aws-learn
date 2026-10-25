# aws-learn

Terraform + GitHub Actions の練習用 AWS 環境。

## 構成

```
aws-learn/
├── bootstrap/          # 最初に1回だけ CloudShell から apply する土台
│   ├── versions.tf     # Terraform / AWS プロバイダーのバージョン
│   ├── variables.tf
│   ├── main.tf         # state 用 S3、GitHub OIDC、GitHub Actions 用 IAM ロール
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   └── backend.tf.example  # state を S3 に移すときに backend.tf にリネーム
└── .gitignore
```

今後追加する予定のもの：

- `envs/base/` … 常設（VPC、サブネット、SG、S3 ゲートウェイエンドポイント、予算アラート）
- `envs/app/` … 都度作成（ALB、EC2×2、NAT Gateway）
- `.github/workflows/` … apply / destroy の手動実行と毎晩の自動 destroy

## bootstrap の設計メモ

- state 用 S3：バージョニング・暗号化・パブリックアクセスブロック・HTTPS 強制。`prevent_destroy` で誤削除を防止
- ロック：S3 ネイティブロック（`use_lockfile = true`）。DynamoDB テーブルは作らない
- GitHub Actions 用ロール
  - 信頼ポリシーで「このリポジトリの main ブランチ」からの実行だけを許可
  - 権限は `PowerUserAccess`（IAM 以外ほぼ全部）＋「`aws-learn-` で始まるロール・インスタンスプロファイルだけ」を作れるインラインポリシー
  - ロール自身の名前は `github-actions-aws-learn` とし、上の接頭辞に当てはまらないため自分の権限を書き換えられない

## 初回セットアップ（CloudShell）

```bash
cd ~/aws-learn/bootstrap
export TF_DATA_DIR=/tmp/tfdata-bootstrap   # プロバイダー（数百MB）をホーム外に置く
cp terraform.tfvars.example terraform.tfvars   # 値を書き換える
terraform init
terraform validate
terraform plan
terraform apply
```

その後 `backend.tf.example` を `backend.tf` にリネームしてバケット名を書き換え、`terraform init -migrate-state`。
