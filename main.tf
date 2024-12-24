# AWS設定
locals {
  environment = "gha-runner"
}

module "multi_runner" {
  source = "philips-labs/github-runner/aws//modules/multi-runner"

  aws_region = "ap-northeast-1"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  prefix = "mits-gh-ci"

  # GitHub Appの設定
  # base64でエンコードされた秘密鍵とGitHub AppのID、Webhookのシークレットを設定（GitHub Organizationの管理者権限が必要）
  github_app = {
    key_base64     = var.github_app_key_base64
    id             = var.github_app_id
    webhook_secret = var.github_app_webhook_secret
  }

  # Lambdaバイナリのパス
  # 現状はZipファイルをGitHubから直接ダウンロードし手動でディレクトリ内に配置している
  webhook_lambda_zip                = "lambdas-download/webhook.zip"
  runner_binaries_syncer_lambda_zip = "lambdas-download/runner-binaries-syncer.zip"
  runners_lambda_zip                = "lambdas-download/runners.zip"

  # マルチランナーの設定
  # 公式：https://philips-labs.github.io/terraform-aws-github-runner/modules/public/multi-runner/
  # 参考：https://tech.mobilefactory.jp/entry/2023/09/01/110000
  multi_runner_config = {
    "sample-app" = {
      matcherConfig = {
        # このRunnerを呼び出すのに使う runs-on の値
        labelMatchers = [["self-hosted", "sample-app"]]
        exactMatch    = true
      }

      runner_config = {
        # ランナーの名前のプレフィックス
        runner_name_prefix = "sample-app"

        # organizaionのランナーとして有効化
        enable_organization_runners = true

        # インスタンスタイプの指定
        instance_types = ["c5a.large"]

        # ランナーのOSとアーキテクチャ
        runner_os           = "linux"
        runner_architecture = "amd64"

        # SSMでのEC2へのアクセス許可（デバッグ用）
        enable_ssm_on_runners = var.enable_ssm_on_runners

        # amiフィルターを指定
        ami_owners = ["463470951542"]
        ami_filter = {
          state = ["available"]
          name  = ["sample-app-github-runner-ubuntu-jammy-amd64-*"]
        }

        # 1回で使い捨てのランナーにする
        enable_ephemeral_runners = true

        # スケールアップ ラムダ関数用に予約された同時実行の量。
        # 値 0 はラムダのトリガーを無効にし、
        # -1 は同時実行制限を削除
        scale_up_reserved_concurrent_executions = -1

        # runnerの同時実行数制限を30に指定。
        runners_maximum_count = 30

        # ubuntuユーザーで実行
        runner_run_as = "ubuntu"

        # ユーザーデータの有効化設定
        # カスタムAMIを利用するため、ユーザーデータは無効化
        enable_userdata = false

        # webhookの遅延をなしに
        delay_webhook_event = 0

        # 起動速度を考えて事前ビルドしたAMIから上げることにしたので、Syncerでactions/runnerのバイナリをSyncする機能はOFFにした
        enable_runner_binaries_syncer = false
      }
    },
  }
}
