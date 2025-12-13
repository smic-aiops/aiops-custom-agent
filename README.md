# aiops-custom-agent

このリポジトリは、AIOpsの可能性を検証するために、プロトタイプ制作のための情報を収める。

目指しているプロトタイプの特徴と機能イメージ 
カスタマイズ性: 誰でもすぐにはじめられるAIOpsを目指す。
特定のタスク実行: 異常検知、イベントの相関付け、根本原因の特定、自動修復アクションの実行など、特定の運用タスクに特化して機能。 
自律性のレベル: 推論、計画、記憶などの能力を備え、ある程度の自律性を持ってユーザーの代わりに目標達成やタスク完了を目指す。
データ統合: プラットフォームメトリック、カスタムメトリック、ログ、イベントデータなど、複数のデータソースから情報を収集・分析。 

## 1. プロジェクト概要

目的: ITIL4 に準拠して運用するサービスの中で AI Ops をカスタムAIエージェントにフォーカスしてどのように活用できるかの概念実証を行う。

- 技術的な実現可能性の確認: 机上の空論ではなく、実際にその技術が機能するかを検証します。
- 課題の早期発見: 実際の運用に近い環境で試すことで、潜在的な技術的・運用上の問題を洗い出します。
- 関係者の合意形成: 検証結果を基に、プロジェクトに関わる多様な関係者の理解や合意を得やすくなります。
- 投資判断の根拠: プロジェクトを続行するか、中止するか、方向転換するかの判断材料とします。

## 2. 方法

- sulu（メインサービスのダミー）を ITIL4 に準拠して運用する基盤を実運用に近い環境で整備します。基盤のOSS は原則無料・コミュニティ版を採用し、原則 SSO での認証が可能なものとします。
- AI の設置はエンジニアではなく、サービス管理者が主に設定するものとします。
- 実用性・精度・コストなどを含めたサービス品質を検証し人が判断した場合の比較を行います。この比較をもって、AI Ops をどのように活用できるかの実証とします。

## 3. リポジトリ構成

- `main.tf` / `variables.tf` / `outputs.tf`: ルートのプロバイダ、変数、出力。`modules/stack` を呼び出す。
- `modules/stack/`: ネットワーク、RDS、SSM、DNS+ACM+CloudFront 制御サイト、ECS、WAF など基盤をまとめたモジュール。`templates/control-index.html.tftpl` はコントロールサイトの HTML テンプレート。
- `docker/`: サービス用 Docker ビルドコンテキスト（例: n8n、sulu）。`docker/sulu` は GitHub リリースの Sulu 3.0.0 を PHP 8.2 ベースのマルチステージビルドで取り込み、コントロールサイト SSO 設定とマイグレーション用フック（`hooks/onready/10-sulu-migrations.sh`）を加えた専用コンテキストです。
- `scripts/`: イメージの pull/build/push、および ECS 再デプロイを行う補助スクリプト。
- `images/`: ローカルに展開したイメージのキャッシュ置き場（git 管理外）。
- `service-operations-platform.md`: サービス運用プラットフォームの補足資料。
- `terraform.tfvars`: 環境固有の設定を記載（秘匿情報は含めない）。state はローカル `terraform.tfstate` を使用。

## 4. 検証基盤

### 運用対象 IT サービス

- sulu（ダミー本番サービス）を ECS 上で稼働。

### サービス運用基盤

- ITIL4 サービス運用ツール（選定中）
参考: [サービス運用プラットフォームへ記載](service-operations-platform.md)

- ITIL4 サービス運用ツール間連携（編集中）
参考: [サービス運用プラットフォームへ記載](general-messaging-spec.md)

## 5. 検証基盤の構築

### 前提条件（AWS アカウント/組織/SSO、ツール類、ネットワーク）

- AWS Organizations 有効化、IAM Identity Center の権限セットを対象アカウントに付与。
- `aws configure sso` で `Admin-AIOps（仮）` プロファイルを作成し、実行前に `aws sso login --profile Admin-AIOps（仮）`。
- ツール: Terraform >= 1.5.x、AWS CLI v2、Docker、jq、GNU tar。ネットワークは AWS SSO/STS/ECR に到達できること。
- 状態管理はローカル `terraform.tfstate` 前提。機密情報があるため、取り扱いに注意。

### アーキテクチャ概要・サービス別リソース

- リージョン: ap-northeast-1。命名は `name_prefix = ${environment}-${platform}`。
- ネットワーク: VPCを新規作成する。更新時は既存 VPC 利用。
- データストア: RDS(posgresql, mysql), DocDB を新規作成して利用
- 公開系: Route53 公開ゾーン、ACM(us-east-1) 証明書、S3 + CloudFront(OAC) で制御サイトを配信。
- コンテナ: ECR に イメージを格納し、必要に応じて ECS クラスタと実行
- ネットワーク: ルートはパブリック 0.0.0.0/0→IGW、プライベート 0.0.0.0/0→NAT。VPCE は S3 を必須作成、Secrets Manager/Logs/ECR DKR/SSM は `enable_*` で制御。
- RDS/SSM: PostgreSQL 15.15、VPC 内 5432 のみ許可。パスワード未指定時は自動生成し、SSM SecureString に保存。
- DNS/ACM/CloudFront/S3: 既存 Public Hosted Zone（例: `smic-aiops.jp`）を参照 or 作成。`control.<zone>` を OAC 付き CloudFront で配信。
- ECS/ECR: 名前空間 `ecr_namespace/repo` でイメージを管理。`create_ecs` が true の場合にクラスタ/ロールを作成。
- タグ/命名: 基本タグ `{environment, platform, app=name_prefix}`、Name タグは `${name_prefix}-<resource>`。

### デプロイ手順（Terraform 設定と変数、Terraform の実行）

1. 認証: `aws sso login --profile Admin-AIOps`
2. 初期化: `terraform init`
3. 環境用設定 : 主な変数 `environment`、`platform`、`name_prefix`、
4. フォーマット/検証: `terraform fmt -recursive`, `terraform validate`
5. プラン: `terraform plan -var-file=terraform.tfvars`
6. 適用: `terraform apply -var-file=terraform.tfvars`
7. ビルド/プッシュ `./scripts/pull_*` `./scripts/build_*`
8. デプロイ `./scripts/redeploy_*` 
9. SSOクライアント登録: `scripts/create_keycloak_client_for_service.sh` を実行し、必要なサービス分の OIDC クライアントと SSM パラメータを作成
10. 出力: `terraform output`（データベース接続情報 などを確認）
11. 起動 https://control.smic-aiops.jp/
12. 破棄が必要な場合: `terraform destroy -var-file=terraform.tfvars`

### 監視設定のポイント

- CloudWatch で, 異常時は通知ルールを拡張。

### ツール利用初期設定（認証、各アプリの初期設定）

- `terraform.tfvars` に 一次的なパラメータ記載。

### ツール利用手順

- ユーザー登録は、Keycloakで行う。
- n8n については SSO へ対応してないため、個別にユーザーアカウントを設定
- terraform output でDB接続情報を取得

### トラブルシューティング

- SSO/CLI 認証失敗: `aws sso login --profile Admin-AIOps` を再実行し、`~/.aws/config` の Start URL/リージョンを確認。
- 意図しない VPC 作成: `existing_vpc_id` または Name タグ `${name_prefix}` の既存 VPC 有無を確認し、plan を必ずレビュー。
- ECR pull/push 失敗: `aws ecr get-login-password` の再実行、NAT/VPCE 到達性、Docker デーモン状態を確認。
- ACM 検証失敗: Route53 レコードが正しいか、CloudFront ディストリビューションに紐付いているか確認。
- ロック/ドリフト: ローカル state のため並列実行を避け、ドリフト時は慎重に `terraform refresh` または state 編集を検討。

## 6. AI 設定と検証

- データの「つなぎ」に着目し、n8n などのワークフロー内で人が判断していたポイントに AI を配置する。設定はサービス管理者が行い、プロンプトや入力データの責任範囲を明確化する。
- 期待するアウトプットと評価指標（精度、応答時間、コスト、誤検知/漏れ率）を定義し、AI なしの手順と並行で実行して比較する。
- コスト試算: モデル利用料 + 実行頻度 + データ転送料を算出し、閾値を超えた場合のフォールバック（人手オペレーション）を決める。
- 設定変更の監査ログを残し、手順/想定外入力/失敗時のエスカレーション先を Runbook 化する。

## 7. 参考情報・外部リンク

- AWS CLI SSO: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html
- Terraform AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- VPC エンドポイント: https://docs.aws.amazon.com/vpc/latest/privatelink/
- ECR: https://docs.aws.amazon.com/AmazonECR/latest/userguide/what-is-ecr.html
- CloudFront OAC: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html
- Route53/ACM: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-configuring.html , https://docs.aws.amazon.com/acm/latest/userguide/acm-overview.html

## 8. 付録
