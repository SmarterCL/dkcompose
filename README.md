# dkcompose

Stack de servicios para smarterbot:

- Postgres con pgvector y Redis para persistencia.
- Odoo 19, n8n, Botpress, Portainer y Chatwoot (web + worker + scheduler).
- Traefik gestiona el enrutamiento TLS usando la red externa `dokploy-network`.
 - Redpanda (Kafka-compatible) + Console para eventos.
 - Vault con storage Raft y UI para emisión de tokens efímeros.

## Requisitos previos

1. Docker y Docker Compose instalados.
2. Red externa creada (solo una vez):

```bash
docker network create dokploy-network
```

## Uso

```bash
docker compose up -d
```

La primera vez que inicies el stack, el contenedor `db-init-chatwoot` creará la base de datos y el usuario `chatwoot` en Postgres y luego se detendrá.

## Servicios expuestos

- Odoo: `https://odoo.smarterbot.cl`
- n8n: `https://n8n.smarterbot.cl`
- Botpress: `https://chat.smarterbot.cl`
- Portainer: `https://portainer.smarterbot.cl`
- Chatwoot: `https://chatwoot.smarterbot.cl`
- Redpanda Console: `https://kafka.smarterbot.cl`
- Vault UI: `https://vault.smarterbot.cl`

## Redpanda y Vault (Fase 5)

Puedes encender Redpanda + Console y Vault con el CLI `smos` (VPS-only):

```bash
# Configura el target (una sola vez)
scripts/smos target production root@smarterbot.cl

# Despliega servicios
scripts/smos deploy redpanda
scripts/smos deploy vault

# Ver estado y logs
scripts/smos status
scripts/smos logs redpanda
scripts/smos logs vault
```

Notas:
- La consola Redpanda queda accesible en `kafka.smarterbot.cl` (solo UI). El broker escucha en `smarter-redpanda:9092` dentro de la red Docker.
- Vault expone la UI en `vault.smarterbot.cl`. Inicializa y unseal siguiendo `VAULT-SETUP.md` en la raíz del monorepo.

## MCP Tools (opcional)

Incluimos un stack para exponer un servidor MCP que opera contra N8N (`n8n-mcp-server.yml`). Para iniciarlo:

```bash
scripts/smos deploy mcp
scripts/smos status
scripts/smos logs mcp
```

Por defecto el MCP Server escucha en `:3100` y no se publica por Traefik (uso interno/privado). Ajusta `n8n-mcp-server.yml` si deseas exponerlo bajo mTLS.
