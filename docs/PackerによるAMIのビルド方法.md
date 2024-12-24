# PackerによるAMIのビルド方法

*terraformとPackerのインストールがすんでいる前提

```bash
# terraformモジュールのインストール等セットアップ
terraform init
# terraformをデプロイ
terraform apply 
# Terraformの出力結果を変数ファイルに書き出す（Packer用のサブネットIDなど）
./generate-packer-vars.sh
# PackerでAMIをビルド
packer build -var-file=packer-vars.json images/sample-app/github_agent.ubuntu.pkr.hcl

# AMI参照の更新のため再度デプロイ
terraform apply
```
