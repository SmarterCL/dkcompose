# 💬 Chatwoot - Plataforma de Mensajería Unificada

**Documentación completa para backend Docker + frontend customizado**

---

## 📋 Tabla de Contenidos

1. [Overview](#overview)
2. [Arquitectura](#arquitectura)
3. [Backend Docker Setup](#backend-docker-setup)
4. [Frontend Next.js Setup](#frontend-nextjs-setup)
5. [Configuración](#configuración)
6. [Integración WhatsApp](#integración-whatsapp)
7. [Integración Shopify](#integración-shopify)
8. [N8N Automation](#n8n-automation)
9. [Troubleshooting](#troubleshooting)
10. [API Reference](#api-reference)

---

## 🎯 Overview

Chatwoot es la plataforma de **mensajería unificada** de SmarterOS que centraliza:

- 📱 **WhatsApp Business API** - Conversaciones con clientes
- 📧 **Email Support** - Tickets vía correo electrónico
- 💬 **Web Chat** - Widget embebido en sitios web
- 🤖 **AI Responses** - Respuestas automáticas vía Gemini (próximamente)

### ¿Por qué Chatwoot?

| Característica | Beneficio |
|----------------|-----------|
| **Open Source** | Self-hosted en VPS, control total de datos |
| **Multi-canal** | Un inbox para WhatsApp, Email, Web |
| **API-first** | Integración con Shopify, N8N, MCP agents |
| **Escalable** | PostgreSQL + Redis + Sidekiq para alto tráfico |
| **Customizable** | Frontend propio en Next.js con branding SmarterOS |

---

## 🏗 Arquitectura

### Componentes del Sistema

```
┌──────────────────────────────────────────────────────────────┐
│                        USUARIOS                              │
│   Clientes (WhatsApp/Email/Web) + Agentes (Dashboard)       │
└──────────────────────────────────────────────────────────────┘
                           ↓
┌──────────────────────────────────────────────────────────────┐
│              FRONTEND: chatwoot.smarterbot.cl                │
│                    (Vercel - Next.js 15)                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  Dashboard  │  │  Inbox UI   │  │  Contacts   │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└──────────────────────────────────────────────────────────────┘
                           ↓ HTTPS REST API + WebSocket
┌──────────────────────────────────────────────────────────────┐
│        BACKEND: api.chatwoot.smarterbot.cl (VPS Docker)     │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Chatwoot App (ghcr.io/chatwoot/chatwoot:v2.10.1)  │   │
│  │  - Rails API (port 3000)                            │   │
│  │  - ActionCable (WebSocket real-time)                │   │
│  │  - Traefik labels (SSL + routing)                   │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌──────────────────────┐  ┌──────────────────────┐        │
│  │  Chatwoot Worker     │  │  Chatwoot Scheduler  │        │
│  │  (Sidekiq)           │  │  (Cron jobs)         │        │
│  └──────────────────────┘  └──────────────────────┘        │
│                                                              │
└──────────────────────────────────────────────────────────────┘
             ↓                            ↓
┌──────────────────────┐      ┌──────────────────────┐
│  PostgreSQL 15       │      │  Redis 7             │
│  (smarter-postgres)  │      │  (smarter-redis)     │
│  - Conversations     │      │  - Real-time cache   │
│  - Messages          │      │  - Sidekiq jobs      │
│  - Contacts          │      │  - ActionCable pub   │
│  - Inboxes           │      │                      │
└──────────────────────┘      └──────────────────────┘
```

### Flujo de Mensajes

#### 1. Cliente envía WhatsApp
```
Cliente WhatsApp
  → WhatsApp Business API (Meta Cloud API)
  → Webhook → Chatwoot Inbox (channel: whatsapp)
  → PostgreSQL (new message)
  → Redis pub (ActionCable broadcast)
  → WebSocket → Frontend (real-time update)
  → Agente ve mensaje en Dashboard
```

#### 2. Agente responde
```
Agente escribe en Dashboard
  → POST /api/v1/accounts/1/conversations/123/messages
  → Chatwoot Backend (Rails)
  → Sidekiq Worker (async send)
  → WhatsApp Business API (send message)
  → Cliente recibe WhatsApp
```

#### 3. Automatización N8N
```
Shopify: Order Created
  → Webhook → N8N
  → N8N Workflow:
      - Get customer phone
      - POST Chatwoot API (create conversation)
      - POST Chatwoot API (send message: "Tu pedido #123 está confirmado")
  → WhatsApp Business API
  → Cliente recibe confirmación automática
```

---

## 🐳 Backend Docker Setup

### Servicios en docker-compose.yml

```yaml
# /Users/mac/dev/2025/dkcompose/docker-compose.yml

services:
  # Chatwoot Main App
  chatwoot:
    image: ghcr.io/chatwoot/chatwoot:v2.10.1
    container_name: smarter-chatwoot
    restart: unless-stopped
    networks:
      - dokploy-network
    depends_on:
      - postgres
      - redis
    environment:
      # Core
      NODE_ENV: production
      RAILS_ENV: production
      INSTALLATION_ENV: docker
      
      # Database
      POSTGRES_HOST: smarter-postgres
      POSTGRES_PORT: 5432
      POSTGRES_DATABASE: chatwoot_production
      POSTGRES_USERNAME: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      
      # Redis
      REDIS_URL: redis://smarter-redis:6379
      
      # App
      SECRET_KEY_BASE: ${CHATWOOT_SECRET_KEY_BASE}
      FRONTEND_URL: https://chatwoot.smarterbot.cl
      FORCE_SSL: true
      
      # Email (opcional - para notificaciones)
      MAILER_SENDER_EMAIL: noreply@smarterbot.cl
      SMTP_ADDRESS: smtp.gmail.com
      SMTP_PORT: 587
      SMTP_USERNAME: ${SMTP_USERNAME}
      SMTP_PASSWORD: ${SMTP_PASSWORD}
      SMTP_AUTHENTICATION: plain
      SMTP_ENABLE_STARTTLS_AUTO: true
      
      # Storage (S3 para attachments - opcional)
      ACTIVE_STORAGE_SERVICE: local
      # Para producción usar S3:
      # ACTIVE_STORAGE_SERVICE: amazon
      # AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID}
      # AWS_SECRET_ACCESS_KEY: ${AWS_SECRET_ACCESS_KEY}
      # AWS_REGION: us-east-1
      # AWS_BUCKET_NAME: smarteros-chatwoot-uploads
      
      # Channels
      # WhatsApp Cloud API (Meta)
      # FB_VERIFY_TOKEN: ${FB_VERIFY_TOKEN}
      # FB_APP_SECRET: ${FB_APP_SECRET}
      
      # Advanced
      RAILS_LOG_TO_STDOUT: true
      RAILS_MAX_THREADS: 5
      
    volumes:
      - chatwoot-storage:/app/storage
      - chatwoot-public:/app/public
    
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.chatwoot.rule=Host(`api.chatwoot.smarterbot.cl`)"
      - "traefik.http.routers.chatwoot.entrypoints=websecure"
      - "traefik.http.routers.chatwoot.tls=true"
      - "traefik.http.routers.chatwoot.tls.certresolver=letsencrypt"
      - "traefik.http.services.chatwoot.loadbalancer.server.port=3000"

  # Chatwoot Worker (Sidekiq)
  chatwoot-worker:
    image: ghcr.io/chatwoot/chatwoot:v2.10.1
    container_name: smarter-chatwoot-worker
    restart: unless-stopped
    command: bundle exec sidekiq -C config/sidekiq.yml
    networks:
      - dokploy-network
    depends_on:
      - postgres
      - redis
    environment:
      # Same as chatwoot service (copy entire env block)
      NODE_ENV: production
      RAILS_ENV: production
      POSTGRES_HOST: smarter-postgres
      POSTGRES_PORT: 5432
      POSTGRES_DATABASE: chatwoot_production
      POSTGRES_USERNAME: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      REDIS_URL: redis://smarter-redis:6379
      SECRET_KEY_BASE: ${CHATWOOT_SECRET_KEY_BASE}
      FRONTEND_URL: https://chatwoot.smarterbot.cl
    volumes:
      - chatwoot-storage:/app/storage

  # Chatwoot Scheduler (Cron)
  chatwoot-scheduler:
    image: ghcr.io/chatwoot/chatwoot:v2.10.1
    container_name: smarter-chatwoot-scheduler
    restart: unless-stopped
    command: bundle exec rake jobs:work
    networks:
      - dokploy-network
    depends_on:
      - postgres
      - redis
    environment:
      # Same as chatwoot service (copy entire env block)
      NODE_ENV: production
      RAILS_ENV: production
      POSTGRES_HOST: smarter-postgres
      POSTGRES_PORT: 5432
      POSTGRES_DATABASE: chatwoot_production
      POSTGRES_USERNAME: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      REDIS_URL: redis://smarter-redis:6379
      SECRET_KEY_BASE: ${CHATWOOT_SECRET_KEY_BASE}
    volumes:
      - chatwoot-storage:/app/storage

volumes:
  chatwoot-storage:
  chatwoot-public:

networks:
  dokploy-network:
    external: true
```

### Variables de Entorno (.env)

```bash
# PostgreSQL (ya existente en tu setup)
POSTGRES_USER=smarteros
POSTGRES_PASSWORD=your_secure_password

# Chatwoot Secret (generar con: openssl rand -hex 64)
CHATWOOT_SECRET_KEY_BASE=generate_with_openssl_rand_hex_64

# SMTP (opcional - para notificaciones email)
SMTP_USERNAME=noreply@smarterbot.cl
SMTP_PASSWORD=your_gmail_app_password

# WhatsApp Cloud API (Meta)
FB_VERIFY_TOKEN=your_custom_verify_token_123
FB_APP_SECRET=your_facebook_app_secret

# S3 (opcional - para attachments en producción)
AWS_ACCESS_KEY_ID=your_aws_key
AWS_SECRET_ACCESS_KEY=your_aws_secret
```

### Deployment en VPS

```bash
# SSH a VPS
ssh root@smarterbot.cl

# Navegar a docker compose
cd /opt/dokploy/dkcompose

# Generar secret key
openssl rand -hex 64
# → Copiar output a .env como CHATWOOT_SECRET_KEY_BASE

# Editar .env con variables Chatwoot
nano .env

# Deploy servicios
docker-compose up -d chatwoot chatwoot-worker chatwoot-scheduler

# Verificar logs
docker-compose logs -f chatwoot

# Crear database (primera vez)
docker-compose exec chatwoot bundle exec rails db:chatwoot_prepare

# Crear super admin (primera vez)
docker-compose exec chatwoot bundle exec rails runner "User.create!(name: 'Admin', email: 'admin@smarterbot.cl', password: 'SecurePass123!', account_id: 1, role: :administrator)"

# Health check
curl https://api.chatwoot.smarterbot.cl/api
# → {"version":"v2.10.1"}
```

---

## 🌐 Frontend Next.js Setup

### Repositorio

```bash
# Clonar frontend
git clone https://github.com/SmarterCL/chatwoot.smarterbot.cl.git
cd chatwoot.smarterbot.cl

# Instalar dependencias
pnpm install

# Configurar env
cp .env.example .env.local
nano .env.local
```

### .env.local

```bash
# Backend API
CHATWOOT_API_URL=https://api.chatwoot.smarterbot.cl
CHATWOOT_ACCOUNT_ID=1
CHATWOOT_ACCESS_TOKEN=get_from_chatwoot_admin_panel

# WebSocket (real-time)
NEXT_PUBLIC_CHATWOOT_WS_URL=wss://api.chatwoot.smarterbot.cl/cable

# Clerk (si usas auth en frontend)
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_live_...
CLERK_SECRET_KEY=sk_live_...

# App
NEXT_PUBLIC_APP_URL=https://chatwoot.smarterbot.cl
NODE_ENV=production
```

### Desarrollo Local

```bash
# Run dev server
pnpm dev
# → http://localhost:3000

# Build para producción
pnpm build

# Start production server
pnpm start
```

### Deploy a Vercel

```bash
# Install Vercel CLI
npm i -g vercel

# Login
vercel login

# Link project
vercel link

# Add env vars (en dashboard Vercel o CLI)
vercel env add CHATWOOT_API_URL
vercel env add CHATWOOT_ACCOUNT_ID
vercel env add CHATWOOT_ACCESS_TOKEN

# Deploy
vercel --prod
```

### Configurar DNS

En Cloudflare (o tu DNS provider):

```
Type: CNAME
Name: chatwoot
Value: cname.vercel-dns.com
Proxy: ✅ Proxied (naranja)
```

En Vercel dashboard → Domains → Add `chatwoot.smarterbot.cl`

---

## ⚙️ Configuración

### 1. Primer Login (Admin)

1. Acceder: `https://api.chatwoot.smarterbot.cl`
2. Login con credenciales creadas: `admin@smarterbot.cl` / `SecurePass123!`
3. Dashboard aparece → Configuración inicial

### 2. Crear Account (Multi-tenant)

```bash
# Settings → Accounts → Add New Account
Name: SmarterBot CL
Domain: smarterbot.cl
Support Email: soporte@smarterbot.cl
```

### 3. Obtener Access Token

```bash
# Settings → Profile Settings → Access Token
# Click "Generate Token"
# Copiar token → Agregar a .env.local del frontend
```

### 4. Crear Inbox (WhatsApp)

```bash
# Settings → Inboxes → Add Inbox
Type: WhatsApp Cloud
Name: WhatsApp Soporte
Phone Number ID: (from Meta Business)
Business Account ID: (from Meta Business)
Access Token: (from Meta Business)
Webhook Verify Token: (tu custom token en .env FB_VERIFY_TOKEN)
```

**Meta Setup (WhatsApp Business API)**:

1. Ir a [developers.facebook.com](https://developers.facebook.com)
2. Crear App → Business → WhatsApp
3. Configurar:
   - **Phone Number**: Agregar número empresarial
   - **Access Token**: Generar token permanente
   - **Webhook URL**: `https://api.chatwoot.smarterbot.cl/webhooks/whatsapp`
   - **Verify Token**: Mismo que `FB_VERIFY_TOKEN` en .env
   - **Webhook Fields**: `messages`, `message_status`

### 5. Crear Agentes

```bash
# Settings → Agents → Add Agent
Name: Juan Soporte
Email: juan@smarterbot.cl
Role: Agent (puede ser Administrator para full access)
Inboxes: [✓] WhatsApp Soporte
```

### 6. Configurar Canned Responses (Respuestas Rápidas)

```bash
# Settings → Canned Responses → Add Response
Short Code: /bienvenida
Content: 
"¡Hola! 👋 Gracias por contactarnos. 
Soy [nombre] del equipo de soporte de SmarterBot. 
¿En qué puedo ayudarte hoy?"
```

---

## 📱 Integración WhatsApp

### Flujo de Mensajes

#### Cliente → Chatwoot

```
1. Cliente envía WhatsApp: "Hola, necesito ayuda"
   ↓
2. WhatsApp Business API (Meta Cloud) recibe mensaje
   ↓
3. Meta envía webhook POST a Chatwoot:
   POST https://api.chatwoot.smarterbot.cl/webhooks/whatsapp
   {
     "entry": [{
       "changes": [{
         "value": {
           "messages": [{
             "from": "56912345678",
             "text": { "body": "Hola, necesito ayuda" },
             "timestamp": "1234567890"
           }]
         }
       }]
     }]
   }
   ↓
4. Chatwoot crea/actualiza conversación en PostgreSQL
   ↓
5. Redis pub → ActionCable broadcast
   ↓
6. WebSocket → Frontend agente ve mensaje en tiempo real
```

#### Chatwoot → Cliente

```
1. Agente escribe respuesta: "¡Hola! ¿En qué puedo ayudarte?"
   ↓
2. POST /api/v1/accounts/1/conversations/123/messages
   { "content": "¡Hola! ¿En qué puedo ayudarte?" }
   ↓
3. Sidekiq Worker (async) procesa envío
   ↓
4. POST a WhatsApp Business API:
   POST https://graph.facebook.com/v18.0/{phone_number_id}/messages
   {
     "messaging_product": "whatsapp",
     "to": "56912345678",
     "text": { "body": "¡Hola! ¿En qué puedo ayudarte?" }
   }
   ↓
5. Cliente recibe WhatsApp
```

### Webhooks Chatwoot → N8N (Automation)

Configurar en Chatwoot:

```bash
# Settings → Integrations → Webhooks → Add Webhook
Event: message_created
URL: https://n8n.smarterbot.cl/webhook/chatwoot-message-created
```

Payload ejemplo:

```json
{
  "event": "message_created",
  "id": 12345,
  "content": "Hola, necesito ayuda",
  "inbox_id": 1,
  "conversation_id": 67890,
  "message_type": "incoming",
  "created_at": 1234567890,
  "sender": {
    "id": 123,
    "name": "Juan Cliente",
    "phone_number": "+56912345678",
    "email": null
  }
}
```

N8N Workflow ejemplo (Auto-respuesta fuera de horario):

```javascript
// N8N: Webhook → Function → Chatwoot API

// Function Node
const now = new Date();
const hour = now.getHours();
const isBusinessHours = hour >= 9 && hour < 18;

if (!isBusinessHours) {
  return [{
    json: {
      conversationId: $json.conversation_id,
      message: "🌙 Gracias por contactarnos. Nuestro horario de atención es Lun-Vie 9-18hrs. Te responderemos mañana."
    }
  }];
}

return [];

// HTTP Request Node (POST Chatwoot API)
// URL: https://api.chatwoot.smarterbot.cl/api/v1/accounts/1/conversations/{{$json.conversationId}}/messages
// Headers: { "api_access_token": "your_token" }
// Body: { "content": "{{$json.message}}" }
```

---

## 🛒 Integración Shopify

### Caso de Uso: Notificar cliente vía WhatsApp cuando hace pedido

#### N8N Workflow

```
Shopify Webhook (order/create)
  ↓
Extract Data (order number, customer phone, total)
  ↓
Create Contact in Chatwoot (if not exists)
  ↓
Create Conversation in Chatwoot
  ↓
Send Message via Chatwoot
  ↓
WhatsApp Client receives notification
```

#### Implementación

**1. Shopify Webhook Setup**

```bash
# Shopify Admin → Settings → Notifications → Webhooks
Event: Order creation
Format: JSON
URL: https://n8n.smarterbot.cl/webhook/shopify-order-created
```

**2. N8N Workflow**

```javascript
// Node 1: Webhook (receives Shopify order)
// Input: $json contains order data

// Node 2: Function (prepare data)
const order = $json;
const customer = order.customer;
const phone = customer.phone.replace(/\D/g, ''); // remove non-digits

return [{
  json: {
    orderNumber: order.order_number,
    customerName: `${customer.first_name} ${customer.last_name}`,
    customerPhone: phone,
    customerEmail: customer.email,
    totalPrice: order.total_price,
    lineItems: order.line_items.map(item => `${item.quantity}x ${item.title}`).join(', ')
  }
}];

// Node 3: HTTP Request (check if contact exists)
// GET https://api.chatwoot.smarterbot.cl/api/v1/accounts/1/contacts/search?q={{$json.customerPhone}}
// Headers: { "api_access_token": "your_token" }

// Node 4: Function (if not exists, prepare create contact)
const searchResults = $json.payload;
if (searchResults.length === 0) {
  return [{
    json: {
      name: $('Function').item.json.customerName,
      phone_number: `+56${$('Function').item.json.customerPhone}`,
      email: $('Function').item.json.customerEmail
    }
  }];
}
return [];

// Node 5: HTTP Request (create contact)
// POST https://api.chatwoot.smarterbot.cl/api/v1/accounts/1/contacts
// Body: { "name": "{{$json.name}}", "phone_number": "{{$json.phone_number}}", "email": "{{$json.email}}" }

// Node 6: HTTP Request (create conversation)
// POST https://api.chatwoot.smarterbot.cl/api/v1/accounts/1/conversations
// Body: { 
//   "source_id": "shopify_order_{{$('Function').item.json.orderNumber}}",
//   "inbox_id": 1,
//   "contact_id": "{{$json.id}}",
//   "status": "open"
// }

// Node 7: HTTP Request (send message)
// POST https://api.chatwoot.smarterbot.cl/api/v1/accounts/1/conversations/{{$json.id}}/messages
// Body: {
//   "content": `🎉 ¡Pedido confirmado!\n\n📦 Orden #${$('Function').item.json.orderNumber}\n💰 Total: $${$('Function').item.json.totalPrice}\n\n📋 Productos:\n${$('Function').item.json.lineItems}\n\n✅ Te notificaremos cuando esté listo para despacho.`,
//   "message_type": "outgoing"
// }
```

---

## 🤖 N8N Automation

### Workflows Comunes

#### 1. Auto-respuesta con Gemini AI

```javascript
// Trigger: Chatwoot Webhook (message_created)
// ↓
// Filter: Only incoming messages
if ($json.message_type !== 'incoming') {
  return [];
}

// ↓
// HTTP Request: Call Gemini API
// POST https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent
// Body: {
//   "contents": [{
//     "parts": [{ "text": `Cliente pregunta: "${$json.content}"\n\nResponde como agente de soporte de SmarterBot (empresa de IA chilena).` }]
//   }]
// }

// ↓
// Function: Extract AI response
const aiResponse = $json.candidates[0].content.parts[0].text;
return [{ json: { conversationId: $('Webhook').item.json.conversation_id, message: aiResponse } }];

// ↓
// HTTP Request: Send via Chatwoot
// POST https://api.chatwoot.smarterbot.cl/api/v1/accounts/1/conversations/{{$json.conversationId}}/messages
// Body: { "content": "{{$json.message}}", "message_type": "outgoing", "private": false }
```

#### 2. Lead Scoring (cliente pregunta por pricing)

```javascript
// Trigger: Chatwoot Webhook (message_created)
// ↓
// Filter: Messages containing "precio" or "plan" or "costo"
const keywords = ['precio', 'plan', 'costo', 'cuánto', 'pago'];
const containsKeyword = keywords.some(kw => $json.content.toLowerCase().includes(kw));

if (containsKeyword) {
  return [{ json: { contactId: $json.sender.id, score: 80, reason: 'Asked about pricing' } }];
}
return [];

// ↓
// HTTP Request: Update contact in Supabase
// POST https://smarteros.supabase.co/rest/v1/leads
// Body: { "contact_id": "{{$json.contactId}}", "score": {{$json.score}}, "stage": "interested" }

// ↓
// HTTP Request: Notify sales team (send email/Slack)
```

#### 3. Ticket Escalation (conversación > 10 minutos sin respuesta)

```javascript
// Trigger: Cron (cada 5 minutos)
// ↓
// HTTP Request: Get open conversations
// GET https://api.chatwoot.smarterbot.cl/api/v1/accounts/1/conversations?status=open

// ↓
// Function: Find stale conversations (no agent reply > 10 min)
const now = Date.now() / 1000;
const staleConversations = $json.payload.filter(conv => {
  const lastMessage = conv.messages[conv.messages.length - 1];
  const isFromCustomer = lastMessage.message_type === 'incoming';
  const timeSinceLastMessage = now - lastMessage.created_at;
  return isFromCustomer && timeSinceLastMessage > 600; // 10 min
});

return staleConversations.map(conv => ({ json: conv }));

// ↓
// HTTP Request: Assign to supervisor
// POST https://api.chatwoot.smarterbot.cl/api/v1/accounts/1/conversations/{{$json.id}}/assignments
// Body: { "assignee_id": 2 } // ID del supervisor

// ↓
// HTTP Request: Send Slack notification
// POST https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
// Body: { "text": "⚠️ Conversación #{{$json.display_id}} sin respuesta por 10+ minutos. Asignada a supervisor." }
```

---

## 🔧 Troubleshooting

### Backend (Docker)

#### Error: "PG::ConnectionBad: could not connect to server"

```bash
# Check si PostgreSQL está corriendo
docker-compose ps postgres

# Si no está, iniciar
docker-compose up -d postgres

# Ver logs
docker-compose logs postgres

# Verificar env vars
docker-compose exec chatwoot env | grep POSTGRES
```

#### Error: "Redis::CannotConnectError"

```bash
# Check Redis
docker-compose ps redis
docker-compose up -d redis

# Test conexión
docker-compose exec redis redis-cli ping
# → Debe responder: PONG

# Ver logs
docker-compose logs redis
```

#### Error: "ActionCable WebSocket failed"

```bash
# Verificar que Traefik esté routeando WebSocket
curl -I https://api.chatwoot.smarterbot.cl/cable
# → HTTP/1.1 101 Switching Protocols

# Check nginx/traefik config para WebSocket upgrade headers
# Traefik debe tener:
# - "traefik.http.middlewares.chatwoot-headers.headers.customrequestheaders.Upgrade=$$http_upgrade"
# - "traefik.http.middlewares.chatwoot-headers.headers.customrequestheaders.Connection=upgrade"
```

### Frontend (Next.js)

#### Error: "CORS policy: No 'Access-Control-Allow-Origin' header"

Agregar en Chatwoot backend `.env`:

```bash
# /opt/dokploy/dkcompose/.env
CORS_ORIGINS=https://chatwoot.smarterbot.cl,https://app.smarterbot.cl
```

Restart:

```bash
docker-compose restart chatwoot
```

#### Error: "401 Unauthorized" en API calls

Verificar token en `.env.local`:

```bash
# Obtener nuevo token
# Login a https://api.chatwoot.smarterbot.cl
# → Settings → Profile → Access Token → Regenerate

# Actualizar .env.local
CHATWOOT_ACCESS_TOKEN=nuevo_token_aqui

# Restart dev server
pnpm dev
```

#### Error: "Cannot read property 'map' of undefined" (conversations)

```bash
# Check API response format
curl -H "api_access_token: YOUR_TOKEN" \
  https://api.chatwoot.smarterbot.cl/api/v1/accounts/1/conversations

# Si response es { "data": {...} }, actualizar client:
# lib/chatwoot-client.ts
const response = await fetch(`${this.baseUrl}/conversations`);
const data = await response.json();
return data.data.payload; // ← Agregar .data si falta
```

### WhatsApp Integration

#### No recibo mensajes de clientes

```bash
# 1. Verificar webhook en Meta
# → developers.facebook.com → WhatsApp → Configuration → Webhook
# URL debe ser: https://api.chatwoot.smarterbot.cl/webhooks/whatsapp
# Verify Token debe coincidir con FB_VERIFY_TOKEN en .env

# 2. Test webhook manualmente
curl -X POST https://api.chatwoot.smarterbot.cl/webhooks/whatsapp \
  -H "Content-Type: application/json" \
  -d '{
    "entry": [{
      "changes": [{
        "value": {
          "messages": [{
            "from": "56912345678",
            "text": { "body": "test" }
          }]
        }
      }]
    }]
  }'

# 3. Ver logs Chatwoot
docker-compose logs -f chatwoot | grep -i whatsapp
```

#### No puedo enviar mensajes a clientes

```bash
# 1. Verificar Meta Access Token
curl -X GET "https://graph.facebook.com/v18.0/{phone_number_id}/messages" \
  -H "Authorization: Bearer YOUR_META_ACCESS_TOKEN"
# → Debe responder sin error 401

# 2. Check Sidekiq logs (worker que envía mensajes)
docker-compose logs -f chatwoot-worker

# 3. Verificar que inbox esté configurado correctamente
# Settings → Inboxes → WhatsApp Soporte → Edit
# - Phone Number ID: correcto
# - Access Token: no expirado
```

---

## 📚 API Reference

### Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/accounts/{account_id}/inboxes` | GET | List all inboxes |
| `/api/v1/accounts/{account_id}/conversations` | GET | List conversations |
| `/api/v1/accounts/{account_id}/conversations` | POST | Create conversation |
| `/api/v1/accounts/{account_id}/conversations/{id}` | GET | Get conversation |
| `/api/v1/accounts/{account_id}/conversations/{id}/messages` | GET | Get messages |
| `/api/v1/accounts/{account_id}/conversations/{id}/messages` | POST | Send message |
| `/api/v1/accounts/{account_id}/conversations/{id}/toggle_status` | POST | Open/resolve conversation |
| `/api/v1/accounts/{account_id}/contacts` | GET | List contacts |
| `/api/v1/accounts/{account_id}/contacts/search` | GET | Search contacts |
| `/api/v1/accounts/{account_id}/contacts` | POST | Create contact |
| `/api/v1/accounts/{account_id}/contacts/{id}` | GET | Get contact |
| `/api/v1/accounts/{account_id}/conversations/{id}/assignments` | POST | Assign agent |

### Authentication

Todos los endpoints requieren header:

```bash
api_access_token: YOUR_ACCESS_TOKEN
```

### Ejemplo: Enviar Mensaje

```bash
curl -X POST https://api.chatwoot.smarterbot.cl/api/v1/accounts/1/conversations/123/messages \
  -H "api_access_token: YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Hola, ¿en qué puedo ayudarte?",
    "message_type": "outgoing",
    "private": false
  }'
```

### Ejemplo: Crear Contacto

```bash
curl -X POST https://api.chatwoot.smarterbot.cl/api/v1/accounts/1/contacts \
  -H "api_access_token: YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Juan Pérez",
    "phone_number": "+56912345678",
    "email": "juan@example.com",
    "custom_attributes": {
      "company": "ACME Corp",
      "industry": "Retail"
    }
  }'
```

### Webhooks Payload (message_created)

```json
{
  "event": "message_created",
  "id": 12345,
  "content": "Hola, necesito ayuda con mi pedido",
  "created_at": 1234567890,
  "message_type": "incoming",
  "private": false,
  "inbox_id": 1,
  "conversation_id": 67890,
  "account_id": 1,
  "sender": {
    "id": 123,
    "name": "Juan Cliente",
    "phone_number": "+56912345678",
    "email": null,
    "type": "contact"
  },
  "conversation": {
    "id": 67890,
    "status": "open",
    "assignee_id": 5,
    "inbox_id": 1
  }
}
```

---

## 🎯 Next Steps

### Fase 4: Shopify Integration (Próximo)

- [x] Documentar Chatwoot backend + frontend
- [ ] Configurar Shopify webhooks (order.created, order.fulfilled)
- [ ] Crear N8N workflow: Shopify → Chatwoot → WhatsApp
- [ ] Test end-to-end: Cliente compra → Recibe confirmación WhatsApp

### Fase 5: Google Workspace + Gemini (Futuro)

- [ ] Upgrade a Google Workspace Business Standard
- [ ] Crear Service Account con permisos Gmail/Calendar
- [ ] Deploy MCP server con Google tools
- [ ] Integrar Gemini AI responses en Chatwoot

### Fase 6: Observability (Futuro)

- [ ] Configurar Grafana dashboard (Chatwoot metrics)
- [ ] Metabase dashboard (conversations, response times, CSAT)
- [ ] Alertas Slack/Email para SLA violations

---

## 📞 Soporte

- **Documentación**: `/docs/CONVERGENCE-PLAN.md`
- **GitHub Issues**: [SmarterOS/issues](https://github.com/SmarterCL/SmarterOS/issues)
- **Email**: dev@smarterbot.cl

---

**Última actualización**: 2025-01-20  
**Versión**: 1.0.0  
**Autor**: SmarterCL DevOps Team
