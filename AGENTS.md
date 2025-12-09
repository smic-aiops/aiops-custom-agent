 # Repository Guidelines

  ## Project Structure & Module Organization
  - Root Terraform: `main.tf`, `variables.tf`, `outputs.tf` wire providers and call `modules/stack`.
  - `modules/stack/` holds VPC/RDS/SSM/DNS+ACM+CloudFront control site/ECS/WAF. Extend infra here and add inputs in `variables.tf`.
  - `docker/` hosts service build contexts (Mattermost plugin); `scripts/` has pull/build/redeploy helpers; `images/` is an ignored cache for local
  tarballs.
  - State defaults to local `terraform.tfstate`; `terraform.tfvars` is for env-specific values—keep credentials out of git.

  ## Build, Test, and Development Commands
  - Login once: `aws sso login --profile Admin-AIOps`.
  - Format/validate/plan/apply: `terraform fmt -recursive`, `terraform validate`, `terraform plan -var-file=terraform.tfvars`, `terraform apply -var-
  file=terraform.tfvars`, then `terraform output`.
  - Image prep: `IMAGE_ARCH=linux/arm64 scripts/pull_n8n_image.sh` caches upstream images; `scripts/build_and_push_n8n.sh` (and `_zulip`, `_odoo`,
  `_pgadmin`, `_gitlab`) builds/tags/pushes to ECR.
  - Service restart: `scripts/redeploy_n8n.sh` etc. trigger ECS force-new-deploys using values from `terraform output`.

  ## Coding Style & Naming Conventions
  - Run `terraform fmt -recursive`; use 2-space indents and snake_case variables/locals.
  - Keep naming aligned to `name_prefix = ${environment}-${platform}`; tag `{environment, platform, app}` plus resource role (e.g.,
  `${name_prefix}-private-rt`).
  - Shell scripts: keep `set -euo pipefail`, quote vars, resolve AWS profile via `terraform output`.
  - Dockerfiles: prefer multi-stage builds; mirror module defaults with `ARG` values.

  ## Testing Guidelines
  - Use `terraform fmt -check -recursive` and `terraform validate` before pushing.
  - Attach a fresh `terraform plan -var-file=terraform.tfvars` to PRs; flag creates/destroys on shared infra.
  - For image changes, run the matching `build_and_push_*` script against a test account and note the resulting ECR URI/tag.

  ## Commit & Pull Request Guidelines
  - Commits: short imperative lead (e.g., `Add n8n ECR helper`); split infra vs script changes when reasonable.
  - PRs: include scope, plan summary, affected AWS services, manual steps (ECR pushes, SSO login). Add screenshots/logs for control-site/UI changes.
  - Do not commit `terraform.tfstate`, tfvars with secrets, or image tarballs (`images/` stays local).

  ## Security & Configuration Tips
  - Keep secrets in SSM/Secrets Manager via module params (`*_ssm_params`, SMTP creds); avoid plain text in tfvars.
  - Default profile/region: `Admin-AIOps`, `ap-northeast-1`; keep provider aliases consistent if overriding.
  - Review WAF geo rules and service auto-stop flags before apply to avoid exposure/cost.
