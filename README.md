# 【社内環境AWS】GitHub Self-Hosted Runner構築用Terraformモジュール

## Clone元

[GitHub リポジトリ](https://github.com/philips-labs/terraform-aws-github-runner)

[OSS公式ドキュメント](https://philips-labs.github.io/terraform-aws-github-runner/)

- Github公式が推奨しているSelfhost Runner構築用のTerraformモジュール
- LambdaによってコントロールされたスポットEC2インスタンスによるSelf host Runnerを構築する。

## 構成図

[構成図](/docs/assets/terraform-aws-github-runner-architecuture.jpg)

## 初期構築

### 1. OSSリポジトリのClone
<https://github.com/philips-labs/terraform-aws-github-runner>

- forkだとプライベートリポジトリに変更できなかったためClone

### 2. Terraformのインストール

- WSL2の中にインストールする
- [公式ダウンロードページ](https://developer.hashicorp.com/terraform/install?product_intent=terraform)
 	- LinuxのUbuntuのコマンドを実行

### 3. セットアップガイドに従う
<https://philips-labs.github.io/terraform-aws-github-runner/getting-started/>

1. 組織用のGithub Appを作成
2. terraform モジュールのセットアップ
 1. <https://github.com/philips-labs/terraform-aws-github-runner/releases>
   上記からLambdaのZipファイルをダウンロード
   `modules/download-lambda`に保存する
 2. 変数を調整する
  1. lambda用のZipのパスとGithub Appsの部分
 3. terraform applyを実行
3. GitHub AppsでWebhook設定を有効化
 1. Permission & EventでWorkflow JobをSubscribe
4. VPCをカスタマイズ
   1. VPCの部分はOSSに含まれていないため自前で実装する必要がある
   2. vpc.tfに記載
   3. Natインスタンスを利用してコスト削減を狙っている。

## 参考記事

- [philips-labs/terraform-aws-github-runner でオートスケールするセルフホストランナーの構築・運用](https://blog.cybozu.io/entry/2022/12/01/102842)
- [philips-labs/terraform-aws-github-runner によるGitHub Actions セルフホストランナーの大規模運用](https://www.docswell.com/s/miyajan/ZW1XJX-large-scale-github-actions-self-hosted-runner-by-philips-terraform-module)
- [コスト安なCI環境を目指してオートスケールするCI環境を構築する](https://tech.dentsusoken.com/entry/2023/03/06/%E3%82%B3%E3%82%B9%E3%83%88%E5%AE%89%E3%81%AACI%E7%92%B0%E5%A2%83%E3%82%92%E7%9B%AE%E6%8C%87%E3%81%97%E3%81%A6%E3%82%AA%E3%83%BC%E3%83%88%E3%82%B9%E3%82%B1%E3%83%BC%E3%83%AB%E3%81%99%E3%82%8BCI%E7%92%B0)
- [TerraformでNATインスタンスを管理する](https://int128.hatenablog.com/entry/2019/10/10/171539)
- [terraform-aws-nat-instance](https://github.com/int128/terraform-aws-nat-instance)
