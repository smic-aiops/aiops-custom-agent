# Defaults moved into variable definitions; override values here if needed.

sulu_oidc_idps_yaml = <<YAML
keycloak: {oidc_url: https://keycloak.smic-aiops.jp/realms/master, display_name: Keycloak, client_id: sulu, secret: 90mQgY9FfhiMGWc4PvfiwZvcEPpdc8Dg, api_url: https://keycloak.smic-aiops.jp/realms/master/protocol/openid-connect/userinfo, extra_params: {scope: "openid email profile"}}
YAML

exastro_web_oidc_idps_yaml = <<YAML
keycloak: {oidc_url: https://keycloak.smic-aiops.jp/realms/master, display_name: Keycloak, client_id: exastro-web, secret: 50OsUbeaDi1JJqhYA5IPs8LVBpXHylQH, api_url: https://keycloak.smic-aiops.jp/realms/master/protocol/openid-connect/userinfo, extra_params: {scope: "openid email profile"}}
YAML

exastro_api_oidc_idps_yaml = <<YAML
keycloak: {oidc_url: https://keycloak.smic-aiops.jp/realms/master, display_name: Keycloak, client_id: exastro-api, secret: ZJRr04ltCNigEmuWZvdLxsDAetwuXAJ3, api_url: https://keycloak.smic-aiops.jp/realms/master/protocol/openid-connect/userinfo, extra_params: {scope: "openid email profile"}}
YAML

keycloak_oidc_idps_yaml = <<YAML
keycloak: {oidc_url: https://keycloak.smic-aiops.jp/realms/master, display_name: Keycloak, client_id: keycloak, secret: Dq7dvYHGk1ekvBAVWciKNVvy0otLr3fN, api_url: https://keycloak.smic-aiops.jp/realms/master/protocol/openid-connect/userinfo, extra_params: {scope: "openid email profile"}}
YAML

odoo_oidc_idps_yaml = <<YAML
keycloak: {oidc_url: https://keycloak.smic-aiops.jp/realms/master, display_name: Keycloak, client_id: odoo, secret: c614BsrH1z0MiyMWwyOWDmQz43WqDWsU, api_url: https://keycloak.smic-aiops.jp/realms/master/protocol/openid-connect/userinfo, extra_params: {scope: "openid email profile"}}
YAML

pgadmin_oidc_idps_yaml = <<YAML
keycloak: {oidc_url: https://keycloak.smic-aiops.jp/realms/master, display_name: Keycloak, client_id: pgadmin, secret: eQjFt8oA2rQhvRtziIkFWcToaEybc0sq, api_url: https://keycloak.smic-aiops.jp/realms/master/protocol/openid-connect/userinfo, extra_params: {scope: "openid email profile"}}
YAML

gitlab_oidc_idps_yaml = <<YAML
keycloak: {oidc_url: https://keycloak.smic-aiops.jp/realms/master, display_name: Keycloak, client_id: gitlab, secret: 8oyIhn5TPfHbVxPDh3PvrBo2fy9K3v49, api_url: https://keycloak.smic-aiops.jp/realms/master/protocol/openid-connect/userinfo, extra_params: {scope: "openid email profile"}}
YAML

growi_oidc_idps_yaml = <<YAML
keycloak: {oidc_url: https://keycloak.smic-aiops.jp/realms/master, display_name: Keycloak, client_id: growi, secret: GfpwvM1cHH9FCm83CyVkQDkRT4BZKxz2, api_url: https://keycloak.smic-aiops.jp/realms/master/protocol/openid-connect/userinfo, extra_params: {scope: "openid email profile"}}
YAML

cmdbuild_r2u_oidc_idps_yaml = <<YAML
keycloak: {oidc_url: https://keycloak.smic-aiops.jp/realms/master, display_name: Keycloak, client_id: cmdbuild-r2u, secret: NRU6Ly6YFuo4dCx2WuAR13xJFZyKnI4w, api_url: https://keycloak.smic-aiops.jp/realms/master/protocol/openid-connect/userinfo, extra_params: {scope: "openid email profile"}}
YAML

orangehrm_oidc_idps_yaml = <<YAML
keycloak: {oidc_url: https://keycloak.smic-aiops.jp/realms/master, display_name: Keycloak, client_id: orangehrm, secret: J2bjSbgMriQFTf1oVgcrCWmpzsh5DscU, api_url: https://keycloak.smic-aiops.jp/realms/master/protocol/openid-connect/userinfo, extra_params: {scope: "openid email profile"}}
YAML

zulip_oidc_idps_yaml = <<YAML
keycloak: {oidc_url: https://keycloak.smic-aiops.jp/realms/master, display_name: Keycloak, client_id: zulip, secret: G3AswZnXpKImHYL7mSaOj2DrB89vUCJ4, api_url: https://keycloak.smic-aiops.jp/realms/master/protocol/openid-connect/userinfo, extra_params: {scope: "openid email profile"}}
YAML
zulip_oidc_full_name_validated = true

zulip_oidc_client_secret = "G3AswZnXpKImHYL7mSaOj2DrB89vUCJ4"

phpmyadmin_oidc_client_id = "phpmyadmin"

phpmyadmin_oidc_client_secret = "17TlofN9bgByTUqJodArgdEFgUgRIqy3"
