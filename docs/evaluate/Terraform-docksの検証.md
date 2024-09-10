# Terraform-docsの検証

## リンク

<https://terraform-docs.io/user-guide/installation/>

## 方針

Dockerで利用できるらしいため、
tfファイルをコンテナにマウントして実行する。

```bash
docker run --rm --volume "$(pwd):/terraform-docs" -u $(id -u) quay.io/terraform-docs/terraform-docs:0.18.0 markdown /terraform-docs > terraform-docs.md
```

## 結果

以下のような出力を得ることができた。

[terraform-docs.md](https://github.com/ryosuke-horie/terraform-aws-github-runner-custom/docs/evaluate/terraform-docs.md)
