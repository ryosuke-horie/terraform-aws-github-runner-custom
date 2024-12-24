#!/bin/bash

# AMIをpackerでビルドするときに必要な変数をterraformから取得してpacker-vars.jsonを生成するスクリプト
# 生成したファイルはgit保管しない

# エラーハンドリング
set -e

# Terraformの出力を取得
SECURITY_GROUP_ID=$(terraform output -raw packer_security_group_id)
SUBNET_ID=$(terraform output -raw packer_subnet_id)

# Packer用の変数ファイルを生成
cat > packer-vars.json <<EOF
{
  "security_group_id": "${SECURITY_GROUP_ID}",
  "subnet_id": "${SUBNET_ID}"
}
EOF

echo "packer-vars.json has been generated successfully."
