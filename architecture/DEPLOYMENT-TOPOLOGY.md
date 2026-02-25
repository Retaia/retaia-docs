# Deployment Topology (NAS + Workstations)

Reference deployment profile for self-hosted environments where:

- Core runs on a NAS/server
- UI is exposed on LAN
- processing agents run on user workstations (outside Docker network)

This profile is normative for interoperability expectations between `core`, `ui`, and `agent`.

## 1. Topology

- `core` service is private (not published directly on LAN).
- `core` image is PHP-FPM (`core:9000`), not an HTTP server.
- `ui` service serves static application on internal Docker network.
- front `caddy` service is published on LAN (example: `http://192.168.0.14:8080`).
- front `caddy` routes:
  - `/api/*` and `/device*` to `core:9000` via `php_fastcgi`
  - other paths to `ui:80`
- Workstation agents call Core through the same LAN gateway URL:
  - `http://192.168.0.14:8080/api/v1`

## 2. Client URL rules

- Browser-based UI clients MUST use a relative API base path (`/api/v1`).
- Browser-based UI clients MUST NOT use internal Docker hostnames such as `core:9000`.
- External workstation agents MUST use a routable LAN/edge URL (example above), never Docker-internal DNS names.

## 3. Security and exposure

- Core container SHOULD remain non-exposed on host ports in this profile.
- Only the Caddy reverse-proxy port is exposed to LAN users/agents.
- Access control (authN/authZ, network policy, optional VPN/allowlist) remains mandatory.

## 4. Example compose pattern

```yaml
services:
  core:
    image: ghcr.io/retaia/retaia-core:v1.0.0
    env_file: .env
    environment:
      APP_ENV: prod
      APP_DEBUG: "0"
      DATABASE_URL: postgresql://app:app@db:5432/app_prod?serverVersion=16&charset=utf8
      APP_INGEST_WATCH_PATH: /var/local/RETAIA/INBOX
      APP_STORAGE_ID: nas-main
    volumes:
      - retaia_var:/var/www/html/var
      - ${RETAIA_INGEST_HOST_DIR:-./docker/RETAIA}:/var/local/RETAIA
    depends_on:
      db:
        condition: service_healthy

  ui:
    image: ghcr.io/retaia/retaia-ui:v1.0.0

  caddy:
    image: caddy:2-alpine
    depends_on: [core, ui]
    ports: ["8080:80"]
    volumes:
      - ./docker/Caddyfile.prod.example:/etc/caddy/Caddyfile:ro
      - ./public:/var/www/html/public:ro

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: app_prod
      POSTGRES_USER: app
      POSTGRES_PASSWORD: app
    healthcheck:
      test: ["CMD", "pg_isready", "-d", "app_prod", "-U", "app"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  retaia_var:
```

Front Caddyfile pattern:

```caddyfile
{
  auto_https off
}

:80 {
  @api path /api/* /device*
  handle @api {
    root * /var/www/html/public
    php_fastcgi core:9000
    file_server
  }

  handle {
    reverse_proxy ui:80
  }
}
```

Agent workstation configuration example:

```text
CORE_API_URL=http://192.168.0.14:8080/api/v1
```

## 5. API request flow

1. Browser/UI and workstation agents call `http://<nas-ip>:8080/api/v1/...`.
2. Front Caddy matches `/api/*` and forwards to Core PHP-FPM (`core:9000`).
3. Core executes request and returns response through Caddy to callers.

This keeps Core private while exposing a single LAN gateway.
