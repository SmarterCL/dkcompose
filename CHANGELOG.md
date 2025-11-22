# SmarterOS Infrastructure Changelog

All notable changes to the SmarterOS infrastructure stack will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.8.0] - 2025-11-22

### Major Infrastructure Modernization

This release represents a complete transformation of the SmarterOS infrastructure from legacy e-commerce integrations to a modern, multi-tenant operating system ready for production deployment.

### Added

#### Commit 1: Core Services & Healthchecks
- **Metabase** analytics platform (kpi.smarterbot.cl)
  - PostgreSQL backend integration
  - Traefik routing with Let's Encrypt TLS
  - Healthcheck endpoint monitoring
- **MCP Registry** static marketplace (mcp.smarterbot.cl)
  - nginx-based static file serving
  - Agent/template catalog hosting
- **Healthchecks** for API service
  - Python-based HTTP health probe
  - 30s interval, 5s timeout, 20s startup grace period

#### Commit 1.1: Comprehensive Healthchecks
- Healthcheck for Odoo ERP (wget-based HTTP probe)
- Healthcheck for n8n workflows (wget-based HTTP probe)
- Healthcheck for Botpress conversation engine (wget-based HTTP probe)
- Healthcheck for Chatwoot web/worker/scheduler (HTTP + process-based probes)
- Healthcheck for Vault secrets manager (simplified HTTP reachability check)
- Healthcheck for Redpanda broker (metrics endpoint probe)

#### Commit 2: Domain Normalization & Network Segmentation
- **Domain Changes**:
  - `odoo.smarterbot.cl` → `erp.smarterbot.cl` (semantic clarity)
  - `chatwoot.smarterbot.cl` → `crm.smarterbot.cl` (role-based naming)
  - `botpress.smarterbot.cl` → `bot.smarterbot.cl` (consistency)
- **Network Architecture**:
  - `tenants-net` bridge network for multi-tenant isolation
  - `api-smarterbot` attached to both `smarter-net` and `tenants-net`
  - Prepared infrastructure for tenant-specific network policies

#### Commit 3: Secret Externalization & Vault Integration
- **Environment Variable Placeholders**:
  - All hardcoded credentials replaced with `${VAR_NAME}` syntax
  - PostgreSQL, Odoo, n8n, Botpress, Chatwoot, Metabase, API credentials externalized
- **Documentation**:
  - `.env.example` with comprehensive variable inventory and Vault path annotations
  - `SECRETS.md` with retrieval patterns, rotation procedures, and multi-tenant secret strategy
- **Security Posture**:
  - Zero secrets in version control
  - Vault as single source of truth for credentials
  - Prepared for HashiCorp Vault Agent auto-auth integration

#### Commit 4: Legacy Cleanup & Versioning
- **Topic Removal**:
  - Eliminated `shopify.webhooks`, `shopify.orders`, `shopify.products`, `shopify.inventory` from Redpanda
  - Eliminated `whatsapp.inbound`, `whatsapp.outbound`, `whatsapp.delivery` from Redpanda
  - Focused event architecture on SmarterOS core topics (events, agent actions, business events, tenant operations)
- **Legacy Archive**:
  - Moved `README-CHATWOOT.md` (with Shopify/WhatsApp references) to `legacy/docs/`
  - Moved demo compose files to `legacy/compose-templates/`
  - Preserved historical artifacts for reference without polluting active codebase
- **Versioning**:
  - `VERSION` file introduced (v0.8.0)
  - `CHANGELOG.md` baseline with structured commit history

### Changed

#### Infrastructure Services
- Updated Vault healthcheck to simplified HTTP probe (resolved YAML quoting issues)
- Normalized Traefik routing labels for semantic domain consistency
- Standardized healthcheck intervals across all services (30s interval, 5s timeout pattern)

#### Compose Structure
- Removed inline hardcoded secrets (PostgreSQL passwords, Rails secret keys, API tokens)
- Added environment variable defaults for non-sensitive configuration
- Improved service dependency health conditions

### Removed

#### Deprecated Integrations
- Shopify e-commerce platform integration (topics, webhooks, sync logic)
- WhatsApp direct integration (replaced by Chatwoot unified messaging)
- Legacy compose templates and demo configurations from root directory

#### Obsolete Documentation
- Shopify → Odoo synchronization guides
- WhatsApp Bot standalone implementation docs
- E-commerce specific workflow configurations

### Technical Debt Eliminated
- ✅ Hardcoded credentials in compose files
- ✅ Mixed domain naming conventions
- ✅ Missing healthchecks for critical services
- ✅ Single-network architecture limiting multi-tenancy
- ✅ Legacy integration remnants from pivot period

---

## Infrastructure State Summary

### Core Stack (Production-Ready)
- **API Gateway**: FastAPI (api.smarterbot.cl) - contact ingestion, event routing
- **CRM**: Chatwoot (crm.smarterbot.cl) - unified messaging, customer conversations
- **BOT**: Botpress (bot.smarterbot.cl) - conversational AI, intent recognition
- **ERP**: Odoo (erp.smarterbot.cl) - business operations, invoicing, inventory
- **Workflows**: n8n (n8n.smarterbot.cl) - automation, integrations, scheduled jobs
- **Analytics**: Metabase (kpi.smarterbot.cl) - business intelligence, dashboards
- **Secrets**: Vault (vault.smarterbot.cl) - credential management, tenant secrets
- **Events**: Redpanda (kafka.smarterbot.cl) - event streaming, async messaging
- **Registry**: MCP Registry (mcp.smarterbot.cl) - agent/template marketplace

### Data Layer
- PostgreSQL 15 with pgvector extension (AI embeddings support)
- Redis 7 for caching, pub/sub, Sidekiq job queue
- Supabase (external) for user data, RLS-enabled multi-tenancy

### Observability
- Healthchecks across all services (Dokploy-compatible restart logic)
- Traefik routing with Let's Encrypt TLS automation
- Redpanda Console for event stream inspection

### Multi-Tenant Architecture
- Vault tenant path convention: `secret/smarteros/tenants/<tenant_rut>/<key>`
- Network segmentation: `smarter-net` (core), `tenants-net` (isolation)
- Prepared for tenant bootstrap script automation (30-second provisioning target)

---

## Deployment Status

**Environment**: VPS (Dokploy-managed Docker Compose)  
**Version**: v0.8.0  
**Stability**: Production-Ready  
**Multi-Tenant**: Infrastructure Complete (RLS & workflows pending)

---

## Next Milestones

### Phase 3: Application Layer
- [ ] `app.smarterbot.cl` tenant onboarding UI
- [ ] Clerk authentication integration
- [ ] Tenant dashboard (services, billing, analytics)

### Phase 4: Data Security
- [ ] Supabase RLS policies per `tenant_rut`
- [ ] SQL migrations: `tenants.sql`, `contacts.sql`, `events.sql`
- [ ] Tenant-scoped API authentication

### Phase 5: Workflow Automation
- [ ] n8n baseline workflows export (contact_sync, intent_dispatch, product_refresh, tenant_bootstrap)
- [ ] Chatwoot → Botpress → Odoo integration flows
- [ ] Automated tenant provisioning pipeline

### Phase 6: Security Hardening
- [ ] Webhook HMAC signature verification
- [ ] Rate limiting per tenant (Redis-backed)
- [ ] API key rotation procedures
- [ ] Vault Agent auto-auth (eliminate token distribution)

---

## Breaking Changes

None - this is the baseline release establishing the infrastructure foundation.

---

## Migration Notes

For systems transitioning from legacy Shopify/WhatsApp integrations:

1. **Redpanda Topics**: Legacy topics removed; consumers must migrate to new event schema
2. **Chatwoot**: WhatsApp integration now managed through Chatwoot unified inbox
3. **Secrets**: All credentials must be migrated to Vault and `.env` file regenerated

---

## Contributors

SmarterCL DevOps Team

---

## References

- [SECRETS.md](./SECRETS.md) - Secret management strategy
- [.env.example](./.env.example) - Environment variable reference
- [docker-compose.yml](./docker-compose.yml) - Infrastructure definition
- [legacy/](./legacy/) - Archived historical configurations

---

**Note**: This changelog documents infrastructure changes. Application-level changes tracked in respective repository changelogs (api.smarterbot.cl, app.smarterbot.cl, etc.).
