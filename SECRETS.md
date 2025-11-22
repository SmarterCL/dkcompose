# SmarterOS Secrets & Environment Injection

This document explains how secrets are stored in Vault and injected into containers via environment variables for the SmarterOS stack defined in `docker-compose.yml`.

## 1. Strategy Overview
- **Source of Truth:** HashiCorp Vault (Raft storage) under path `secret/smarteros/<component>`.
- **Distribution:** CI/CD or provisioning script reads secrets from Vault, writes `.env` just in time (or passes them as platform env vars in Dokploy).
- **Principle:** No hardcoded passwords, API keys, or private tokens in compose; all replaced by `${VAR_NAME}` placeholders.
- **Rotation:** Update value in Vault, re-run deploy pipeline to regenerate `.env` and restart impacted services.

## 2. Vault Path Conventions
```
secret/smarteros/postgres        -> POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB
secret/smarteros/odoo            -> ODOO_DB_USER, ODOO_DB_PASSWORD
secret/smarteros/n8n             -> N8N_DB_USER, N8N_DB_PASSWORD
secret/smarteros/botpress        -> BOTPRESS_LICENSE_KEY, BOTPRESS_AUTH_SECRET
secret/smarteros/chatwoot        -> CHATWOOT_SECRET_KEY_BASE, CHATWOOT_DATABASE_URL
secret/smarteros/metabase        -> METABASE_DB_USER, METABASE_DB_PASSWORD
secret/smarteros/api             -> SUPABASE_SERVICE_ROLE, RESEND_API_KEY, CHATWOOT_TOKEN
secret/smarteros/supabase        -> (External project keys if mirrored)
secret/smarteros/vault           -> VAULT_ROOT_TOKEN (dev only)
```

## 3. Retrieval Examples
### CLI Manual Fetch
```bash
vault kv get -format=json secret/smarteros/chatwoot | jq -r '.data.data.SECRET_KEY_BASE'
```

### Export to .env (excerpt)
```bash
#!/usr/bin/env bash
set -euo pipefail

VAULT_ADDR="${VAULT_ADDR:-http://localhost:8200}"  # ensure logged in (vault login)

# Helper to append key from vault path
append_secret() {
  local path="$1" key="$2"; value=$(vault kv get -format=json "secret/smarteros/${path}" | jq -r ".data.data.${key}");
  echo "${key}=${value}" >> .env
}

rm -f .env && touch .env
append_secret postgres POSTGRES_USER
append_secret postgres POSTGRES_PASSWORD
append_secret postgres POSTGRES_DB
append_secret chatwoot SECRET_KEY_BASE
append_secret botpress BOTPRESS_LICENSE_KEY
append_secret botpress BOTPRESS_AUTH_SECRET
append_secret api SUPABASE_SERVICE_ROLE
append_secret api RESEND_API_KEY
# Add remaining keys as needed
```

### Inline for Docker Platform (Dokploy / CI)
Use platform secret engine to map Vault outputs to environment variables; e.g. CI step resolves JSON and injects masked env vars for deployment.

## 4. Variable Inventory (Compose)
| Variable | Component | Sensitive | Description |
|----------|-----------|-----------|-------------|
| POSTGRES_USER | postgres | Y | DB username |
| POSTGRES_PASSWORD | postgres | Y | DB password |
| POSTGRES_DB | postgres | N (name) | Default database |
| ODOO_DB_USER | odoo | Y | Odoo database user |
| ODOO_DB_PASSWORD | odoo | Y | Odoo database password |
| N8N_DB_USER | n8n | Y | n8n database user |
| N8N_DB_PASSWORD | n8n | Y | n8n database password |
| BOTPRESS_LICENSE_KEY | botpress | Y | Botpress license token |
| BOTPRESS_AUTH_SECRET | botpress | Y | Botpress auth secret |
| CHATWOOT_SECRET_KEY_BASE | chatwoot | Y | Rails secret key base |
| CHATWOOT_DATABASE_URL | chatwoot | Y | Connection URL (contains creds) |
| METABASE_DB_USER | metabase | Y | Metabase DB user |
| METABASE_DB_PASSWORD | metabase | Y | Metabase DB password |
| SUPABASE_SERVICE_ROLE | api | Y | Elevated Supabase key |
| RESEND_API_KEY | api | Y | Email provider key |
| CHATWOOT_TOKEN | api | Y | Chatwoot personal token |
| VAULT_ROOT_TOKEN | vault(dev) | Y | Dev-only bootstrap token |

Non-sensitive defaults (can remain in VCS): domains, ports, timezones, site URLs, `MCP_REGISTRY_TITLE`.

## 5. Rotation Procedure
1. Update value in Vault: `vault kv put secret/smarteros/botpress BOTPRESS_AUTH_SECRET=new_secret`.
2. Regenerate `.env`: run secrets sync script in CI or manually.
3. Trigger container restart (`docker compose up -d botpress` or platform redeploy).
4. Validate service healthcheck and app functionality.

## 6. Tenant Secret Extension (Future)
Tenant-level secrets will follow: `secret/smarteros/tenants/<tenant_rut>/<key>`.
Pattern examples:
```
secret/smarteros/tenants/76262345-3/chatwoot_access_token
secret/smarteros/tenants/76262345-3/odoo_api_key
```
Provisioning script enumerates tenant directory, exports per-tenant env into isolated runtime or injects at request time through Vault agent templates.

## 7. Hardening & Next Steps
- Replace dev Vault root token with initialized unseal keys + policies.
- Introduce Vault Agent auto-auth (Kubernetes / container sidecar) to avoid distributing tokens.
- Migrate chatwoot DB bootstrap password out of inline SQL (parametrize via env substitution).
- Add checksum verification for pulled images (optional).

## 8. Policy Quick Reference
Example read policy for API service:
```hcl
path "secret/data/smarteros/api" {
  capabilities = ["read"]
}
```
Tenant-scoped read:
```hcl
path "secret/data/smarteros/tenants/{{identity.entity.name}}/*" {
  capabilities = ["read"]
}
```

## 9. Incident Response
If a secret leak is suspected:
1. Revoke/rotate in provider (Resend, Supabase, etc.).
2. Update Vault with new value.
3. Redeploy stack.
4. Audit access logs (`vault audit` + platform logs).
5. Document rotation in CHANGELOG / incident report.

---
Maintain this file as authoritative reference; update whenever adding/removing environment variables or Vault paths.
