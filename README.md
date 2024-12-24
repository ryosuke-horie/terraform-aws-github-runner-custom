# GitHub Self-Hosted Runner構築用Terraformモジュール

## 概要

GitHub ActionsのセルフホストランナーをAWS上に構築するためのTerraformモジュールです。
GitHubホストのランナーを利用する場合に比べて、カスタムAMIの利用やオートスケールによるCI/CDの高速化とコスト削減が目的です。
*コスト削減効果はGitHub Actionsの実行時間がある程度長い場合に発揮されます。将来的に複数のプロジェクトにおいてCICDが実行されることを見越して構築しています。

## 構成図

![構成図](/docs/assets/セルフホストランナー構成図.jpg)

## 参考記事

- [philips-labs/terraform-aws-github-runner でオートスケールするセルフホストランナーの構築・運用](https://blog.cybozu.io/entry/2022/12/01/102842)
- [philips-labs/terraform-aws-github-runner によるGitHub Actions セルフホストランナーの大規模運用](https://www.docswell.com/s/miyajan/ZW1XJX-large-scale-github-actions-self-hosted-runner-by-philips-terraform-module)
- [コスト安なCI環境を目指してオートスケールするCI環境を構築する](https://tech.dentsusoken.com/entry/2023/03/06/%E3%82%B3%E3%82%B9%E3%83%88%E5%AE%89%E3%81%AACI%E7%92%B0%E5%A2%83%E3%82%92%E7%9B%AE%E6%8C%87%E3%81%97%E3%81%A6%E3%82%AA%E3%83%BC%E3%83%88%E3%82%B9%E3%82%B1%E3%83%BC%E3%83%AB%E3%81%99%E3%82%8BCI%E7%92%B0)
- [TerraformでNATインスタンスを管理する](https://int128.hatenablog.com/entry/2019/10/10/171539)
- [terraform-aws-nat-instance](https://github.com/int128/terraform-aws-nat-instance)
