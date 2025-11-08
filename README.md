# dkcompose

Stack de servicios para smarterbot:

- Postgres con pgvector y Redis para persistencia.
- Odoo 19, n8n, Botpress, Portainer y Chatwoot (web + worker + scheduler).
- Traefik gestiona el enrutamiento TLS usando la red externa `dokploy-network`.

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
