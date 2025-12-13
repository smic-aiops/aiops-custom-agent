# 環境利用ガイド（プロジェクト基盤 / `smic-aiops.jp`）

環境（デフォルトドメイン: `smic-aiops.jp`）へのアクセス方法、認証方式、稼働時間（自動停止）、利用可能なサービスの初回設定をまとめます。

> コスト削減のため、サービスは「停止状態がデフォルト」または「時間帯で自動停止」します。アクセスできない場合は、まず **コントロールサイト**で稼働状態を確認してください。

---

## 1. はじめに

### 1.1 利用開始の流れ（最短）

1. **Keycloak の招待メール**を受け取る
2. メール内リンクから **メールアドレス確認 → パスワード設定**
3. 以後、各サービスにアクセスすると **Keycloak へリダイレクトされて SSO** できます（n8n は例外）

### 1.2 サービス起動/停止（超重要）

* **コントロールサイト**: `https://control.smic-aiops.jp/`
  Keycloak でサインインし、サービスの利用可能なクライアントとサービスへのリンクを確認します。

---

## 2. 用語（このガイド内の表記）

* **SSO**: Single Sign-On。Keycloak で 1 回認証すると、対応サービスへのサインインが引き継がれます（通常は OIDC）。
* **OIDC**: OpenID Connect。ALB（ロードバランサ）や各アプリが Keycloak を IdP として認証します。
* **ALB OIDC**: 一部サービスはアプリ自体でなく **ALB 側**で OIDC 認証します（例: phpMyAdmin）。ALB の `authenticate-oidc` は **HTTPS リスナーでのみサポート**され、セッション維持に Cookie を使います。 ([AWS ドキュメント][2])

---

## 3. 認証モデル

### 3.1 基本認証

以下は **Keycloak 認証**を使います（アクセス時に Keycloak のサインイン画面へ遷移、またはボタンで遷移します）：

* Sulu
* Exastro IT Automation（Web / API）
* GitLab
* pgAdmin
* GROWI
* CMDBuild-r2u
* Odoo
* OrangeHRM
* （その他、Keycloak 連携しているサービス）

### 3.2 基本認証の例外（n8n）

* **n8n** は Keycloak SSO を介さず、n8n の **ユーザー招待（Invite）**で参加します。セルフホスト n8n のユーザー管理は、オーナーが Users 画面から招待し、招待メールのリンクで参加する流れです。 ([n8n Docs][4])

### 3.3 ALB OIDC で保護されるサービス

* **phpMyAdmin** は ALB の `authenticate-oidc` で保護される想定です。ALB は認証状態を Cookie で維持します。 ([AWS ドキュメント][2])

---

## 4. アクセス方法（利用者向け）

### 4.1 ユーザー招待（Keycloak）

**フロー**: 招待メール受信 → メールアドレス確認 → パスワード設定 → サインイン完了

Keycloak では、ユーザーに「VERIFY_EMAIL / UPDATE_PASSWORD」などの Required Action（必須アクション）を要求する運用が一般的です。Required action は「認証完了前に必ず実施させる手続き」です。 ([Keycloak][1])

#### Keycloak から各サービスへ（一般ユーザー）

1. 招待メールのリンクから **メールアドレス確認**を完了
2. **パスワードを設定**して Keycloak にサインイン
3. 以後、各サービスへアクセスすると通常は SSO で入れます（サインアウト後は Keycloak サインイン画面へ遷移）
4. よく使うサービスは **ブックマーク**推奨

> **サインアウトについて**
> Keycloak/OIDC にはサインアウト用エンドポイント（`/realms/{realm}/protocol/openid-connect/logout`）があります。アプリ側のサインアウトと Keycloak セッションのサインアウトが別の場合があるため、「サインアウトしたのに再サインイン不要」などが起きたら Keycloak 側セッションも終了しているか確認してください。 ([Keycloak][6])

### 4.2 n8n（例外）

1. **n8n の招待メール**の URL を開く
2. n8n 内でユーザー作成・パスワード設定（Keycloak とは別管理）
3. 以後 `https://n8n.smic-aiops.jp/` にアクセスし、n8n ローカルアカウントでサインイン ([n8n Docs][4])

---

## 5. 稼働時間と自動停止（オートストップ）

### 5.1 デフォルト稼働パターン

* **Keycloak / Zulip / n8n**: コントロールサイト上で **自動起動・停止（スケジュール）有効**
  * 平日: 17:00–22:00（JST）
  * 土日祝: 08:00–23:00（JST）
* **その他サービス**（Sulu, Exastro, GitLab, pgAdmin, phpMyAdmin, GROWI, CMDBuild-r2u, Odoo, OrangeHRM など）
  * 自動起動・停止は **既定で無効**
  * 初期状態は **停止**。必要に応じて起動

### 5.2 アイドル自動停止（統合ルール）

* アイドル監視をサポートするサービスは、アクセスが続く限り稼働するが、**アイドル閾値（既定 60 分）**を超えてリクエストが無い場合に自動で停止
* 自動起動停止が ON の時間帯は **スケジュール優先**
* スケジュール外はアイドル監視
* 手動起動したサービスも、アイドルタイマー到達で停止する前提

### 5.3 コントロールサイトでできること

* 起動/停止（即時反映）
* 自動起動・停止スケジュールの設定（※Keycloak / Zulip / n8n は固定で編集不可）
* アイドル分の変更（対応サービスのみ）
* 表示・設定時刻は **JST**

---

## 6. サービス一覧（URL / 認証）

| 区分       | サービス         | URL                                                                 | 認証               |
| -------- | ------------ | ------------------------------------------------------------------- | ---------------- |
| 認証基盤     | Keycloak     | `https://keycloak.smic-aiops.jp/`                                   | Keycloak         |
| PoCコア    | n8n          | `https://n8n.smic-aiops.jp/`                                        | **ローカル**         |
| PoCコア    | Zulip        | `https://zulip.smic-aiops.jp/`                                      | Keycloak |
| CMS(ダミー) | Sulu         | `https://sulu.smic-aiops.jp/`                                       | Keycloak         |
| DB確認     | phpMyAdmin   | `https://phpmyadmin.smic-aiops.jp/`                                 | **ALB OIDC**     |
| DB確認     | pgAdmin      | `https://pgadmin.smic-aiops.jp/`                                    | Keycloak         |
| 基盤管理     | コントロールサイト    | `https://control.smic-aiops.jp/`                                    | Keycloak         |

※ 以下は、構築を検討中

| 区分       | サービス         | URL                                                                 | 認証               |
| -------- | ------------ | ------------------------------------------------------------------- | ---------------- |
| 自動化      | Exastro ITA  | `https://ita-web.smic-aiops.jp/` / `https://ita-api.smic-aiops.jp/` | Keycloak         |
| DevOps   | GitLab       | `https://gitlab.smic-aiops.jp/`                                     | Keycloak   |
| ナレッジ     | GROWI        | `https://growi.smic-aiops.jp/`                                      | Keycloak         |
| ITSM支援   | CMDBuild-r2u | `https://cmdbuild.smic-aiops.jp/`                                   | Keycloak         |
| 一般管理     | Odoo         | `https://odoo.smic-aiops.jp/`                                       | Keycloak         |
| 人事       | OrangeHRM    | `https://orangehrm.smic-aiops.jp/`                                  | Keycloak         |


---

## 7. よくあるつまずき（利用者向けトラブルシュート）

### 7.1 「サイトが落ちている / 503」っぽい

* まずコントロールサイトで **停止していないか**確認（必要なら起動）
* 自動停止時間帯外であれば、スケジュールにより停止している可能性

### 7.2 「何度も Keycloak に戻される」

* ブラウザで **Cookie/セッションがブロック**されると SSO が成立しないことがあります
* 対応: 別ブラウザ、プライベートウィンドウ、当該ドメインの Cookie 削除を試す
* ALB OIDC はセッション Cookie を利用します ([AWS ドキュメント][2])

### 7.3 「招待メールが来ない」

* Keycloak / n8n / GitLab / Zulip / pgAdmin 等、招待や回復メールは SMTP 設定が前提です ([Keycloak][1])

---

## 8. 運用上の注意（最低限）


---

## 付録A. 連絡先・責任分界（テンプレ）

* 利用者問い合わせ窓口: `（基盤サポート）`
* 起動停止・認証・DNS の担当: `（基盤担当）`
* 各アプリの運用担当: `（アプリ担当）`

---

# 出典

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
