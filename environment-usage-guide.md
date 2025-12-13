# 環境のつかいかた（smic-aiops.jp）

## 1. まず最初に
1. Keycloak の招待メール「アカウントの更新」を開く
2. 「アカウントの更新」→ パスワード設定 → サインイン完了
3. あとは各サービスにアクセスすれば SSO で入れます（n8n だけ別手順）
- 下記、「サービス一覧（URL / 認証）」にURLに記載があります。

### ワークスペースへの参加
1. Zulip の招待メール「xxx has invited you to join aiops」を開く
2. 「登録を完了」→ 氏名・メールアドレス設定 → サインイン完了
3. サインアウト → サインイン画面「Keycloakでログイン」→ サインイン完了

### 起動/停止はここで
- コントロールサイト: `https://control.smic-aiops.jp/`
- ここで「起動」「停止」、スケジュール確認ができます。
- Keycloak / Zulip / n8n は平日 17:00–22:00、土日祝 08:00–23:00 に自動起動。それ以外は止まります。ほかのサービスは最初は止まっています。必要な時に、必要なサービスを立ち上げてください。
- 作業にあたって他のOSSが必要な場合、OSSの名前とバージョン、デプロイ希望日を管理者へ伝えます。

---

## 2. サインインの仕組み
- **Keycloak SSO**: Zulip, Sulu, Exastro ITA (Web/API), GitLab, phpMyAdmin (ALB OIDC), pgAdmin, GROWI, CMDBuild-r2u, Odoo, OrangeHRM などは、開くと Keycloak のサインイン画面に移動します。
- **例外（n8n）**: Keycloak を使わず、n8n から届く招待メールで自分のアカウントを作ります。

### ふつうのサービスの入り方
1. Keycloak の招待メールでパスワードを設定しサインイン
2. 各サービスのURLにアクセス → 自動で SSO されます
3. サインアウトしたら、また Keycloak のサインイン画面に戻ります
4. よく使うサービスはブックマークしておくと便利

### n8n の入り方（だけ違う）
1. n8n 招待メールのURLを開き、ユーザー作成＆パスワード設定（Keycloakとは別）
2. `https://n8n.smic-aiops.jp/` にアクセスし、n8n のアカウントでサインイン

---

## 3. 自動停止とスケジュール
- **自動起動するもの**: Keycloak / Zulip / n8n（平日 17:00–22:00、土日祝 08:00–23:00）
- **スケジュール期間中の挙動**: 指定時刻にサービスコントロールが desired count を 1 にして起動し、期間中に手動や自動で停止しても自動的に再起動します。アイドル自動停止は無効になり、スケジュール終了時に強制的な停止や再起動は行われません。
- **スケジュール期間外の挙動**: ふだんは止まっており、必要なときにコントロールサイトで手動起動してください。自動再起動は行われず、60分リクエストが無いとアイドル自動停止で止まります。次のスケジュール開始までは自動復帰しません。
- コントロールサイトでは、起動/停止、スケジュール設定、アイドル分の変更（対応サービスのみ）ができます。時刻は JST です。

---

## 4. サービス一覧（URL / 認証）

| 区分       | サービス         | URL                                                                 | 認証       |
| ---------- | ---------------- | ------------------------------------------------------------------- | ---------- |
| 認証基盤     | Keycloak         | `https://keycloak.smic-aiops.jp/`                                   | Keycloak   |
| 基盤管理     | コントロールサイト      | `https://control.smic-aiops.jp/`                                    | Keycloak(JWT Auth)   |
| メインサービス（ダミー） | Sulu             | `https://sulu.smic-aiops.jp/`                                       | Keycloak   |
| PoCコア    | n8n              | `https://n8n.smic-aiops.jp/`                                        | ローカル     |
| PoCコア    | Zulip            | `https://zulip.smic-aiops.jp/`                                      | Keycloak   |
| DB確認     | phpMyAdmin       | `https://phpmyadmin.smic-aiops.jp/`                                 | Keycloak(ALB OIDC)   |
| DB確認     | pgAdmin          | `https://pgadmin.smic-aiops.jp/`                                    | Keycloak   |

※ 準備中/追加予定

| 区分     | サービス         | URL                                                                 | 認証     |
| -------- | ---------------- | ------------------------------------------------------------------- | -------- |
| ナレッジ     | GROWI            | `https://growi.smic-aiops.jp/`                                      | Keycloak |
| 一般管理     | Odoo             | `https://odoo.smic-aiops.jp/`                                       | Keycloak |
| 人事       | OrangeHRM        | `https://orangehrm.smic-aiops.jp/`                                  | Keycloak |
| ITSM支援   | CMDBuild-r2u     | `https://cmdbuild.smic-aiops.jp/`                                   | Keycloak |
| 自動化      | Exastro ITA      | `https://ita-web.smic-aiops.jp/` / `https://ita-api.smic-aiops.jp/` | Keycloak |
| DevOps   | GitLab           | `https://gitlab.smic-aiops.jp/`                                     | Keycloak |

---

## 5. よくあるトラブル
- **503 で見れない**: コントロールサイトで起動しているか確認。自動停止の時間帯かも。
- **SSO から戻される**: ブラウザの Cookie/セッションをブロックしていないか確認。別ブラウザやプライベートウィンドウでも試してみて。

---

## 6. 運用メモ
- ブラウザを開きっぱなしにしない。利用したらブラウザを閉じましょう。（誰も使っていなければしばらくして自動でサービスは停止しますが、ブラウザを開いたままだと、自動サービス停止機能が作動しないこともあります。）
- サービスコントロールで利用前に起動したサービスは、作業がおわった時にサービスコントロール停止しないようにしましょう。他の人がつかっているかもしれません。

---

## 7. 連絡先・担当
- 利用者問い合わせ: `（基盤サポート）`
- 起動停止・認証・DNS: `（基盤担当）`
- 各アプリ運用: `（アプリ担当）`

---

## 出典
- [Keycloak Server Administration Guide](https://www.keycloak.org/docs/latest/server_admin/index.html?utm_source=chatgpt.com)
- [Application Load Balancer を使用してユーザーを認証する](https://docs.aws.amazon.com/ja_jp/elasticloadbalancing/latest/application/listener-authenticate-users.html?utm_source=chatgpt.com)
- [AWS Systems Manager Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html?utm_source=chatgpt.com)
- [Configure self-hosted n8n for user management](https://docs.n8n.io/hosting/configuration/user-management-self-hosted/?utm_source=chatgpt.com)
- [User management SMTP, and two-factor authentication](https://docs.n8n.io/hosting/configuration/environment-variables/user-management-smtp-2fa/?utm_source=chatgpt.com)
- [Securing applications and services with OpenID Connect](https://www.keycloak.org/securing-apps/oidc-layers?utm_source=chatgpt.com)
- [Authentication methods — Zulip 11.4 documentation](https://zulip.readthedocs.io/en/stable/production/authentication-methods.html?utm_source=chatgpt.com)
- [SecurityBundle — Sulu 2.6 documentation](https://docs.sulu.io/en/2.6/bundles/security/index.html?utm_source=chatgpt.com)
- [Exastro IT Automation Documentation](https://ita-docs.exastro.org/?utm_source=chatgpt.com)
- [Use OpenID Connect as an authentication provider (GitLab)](https://docs.gitlab.com/administration/auth/oidc/?utm_source=chatgpt.com)
- [Container Deployment — pgAdmin 4 documentation](https://www.pgadmin.org/docs/pgadmin4/latest/container_deployment.html?utm_source=chatgpt.com)
- [アプリ設定 | GROWI Docs](https://docs.growi.org/ja/admin-guide/management-cookbook/app-settings.html?utm_source=chatgpt.com)
- [Data Import / Export through files (CMDBuild)](https://www.cmdbuild.org/en/project/features/data-import-export-through-files?utm_source=chatgpt.com)
- [Send and receive emails in Odoo with an email server](https://www.odoo.com/documentation/16.0/applications/general/email_communication/email_servers.html?utm_source=chatgpt.com)
- [How to check the email configuration in OrangeHRM](https://help.orangehrm.com/hc/en-us/articles/23969730777753-How-to-check-the-email-configuration-in-the-system?utm_source=chatgpt.com)
- [UserResource (Keycloak API)](https://www.keycloak.org/docs-api/latest/javadocs/org/keycloak/admin/client/resource/UserResource.html?utm_source=chatgpt.com)
- [Outgoing email — Zulip documentation](https://zulip.readthedocs.io/en/11.1/production/email.html?utm_source=chatgpt.com)
- [Configuration options for Linux package installations (GitLab)](https://docs.gitlab.com/omnibus/settings/configuration/?utm_source=chatgpt.com)
- [SMTP settings (GitLab)](https://docs.gitlab.com/omnibus/settings/smtp/?utm_source=chatgpt.com)
- [Login Page — pgAdmin documentation](https://www.pgadmin.org/docs/pgadmin4/latest/login.html?utm_source=chatgpt.com)
- [Configuration — phpMyAdmin documentation](https://docs.phpmyadmin.net/en/latest/config.html?utm_source=chatgpt.com)
- [Use AWS Secrets Manager secrets in Parameter Store](https://docs.aws.amazon.com/secretsmanager/latest/userguide/integrating_parameterstore.html?utm_source=chatgpt.com)
