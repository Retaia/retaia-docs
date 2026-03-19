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
- the exposed shared entrypoint for `UI_WEB` and workstation agents MUST be `HTTPS`, including in development.
- TLS termination MAY be provided either:
  - directly by the exposed application component
  - or by an optional front reverse proxy (`Caddy`, `Traefik`, `NGINX`, equivalent)
- when a front reverse proxy is used, it routes:
  - `/api/*` and `/device*` to `core:9000` via `php_fastcgi` or equivalent upstream wiring
  - other paths to `ui:80`
- Workstation agents call Core through the same routable `HTTPS` gateway URL:
  - `https://retaia.local/api/v1`

## 2. Client URL rules

- Browser-based UI clients MUST use a relative API base path (`/api/v1`).
- Browser-based UI clients MUST NOT use internal Docker hostnames such as `core:9000`.
- External workstation agents MUST use a routable LAN/edge URL (example above), never Docker-internal DNS names.
- Cleartext `HTTP` is not a conforming shared runtime profile.

## 3. Security and exposure

- The exposed shared runtime endpoint MUST present TLS to clients.
- Certificates MAY be issued either by:
  - a public CA
  - or an operator-installed local CA trusted by the participating clients
- Core container SHOULD remain non-exposed on host ports in this profile.
- If a reverse proxy is present, only the reverse-proxy port is exposed to LAN users/agents.
- If no reverse proxy is present, the component exposed to LAN users/agents MUST itself terminate TLS.
- Access control (authN/authZ, network policy, optional VPN/allowlist) remains mandatory.

## 4. Core env loading order (normative)

Core configuration MUST be loaded with this precedence order (lowest -> highest), where each next layer overrides previous values:

1. `.env` (generic defaults)
2. `.env.<environment>` (environment-specific; typically `.env.dev`, `.env.test`, `.env.prod`)
3. `.env.local` (machine/operator local overrides, never versioned)
4. Runtime shell environment variables (process/container env)

Rules:

- `APP_ENV` selects the environment file (`dev|test|prod`), then Core loads `.env.<APP_ENV>`.
- Missing optional file (`.env.<APP_ENV>` or `.env.local`) MUST NOT fail boot by itself.
- Runtime shell env remains the final override layer and MUST take precedence over any `.env*` value.
- Core startup MUST validate `APP_STORAGE_ID` consistency against the mounted marker `/.retaia` and its JSON field `storage_id`.
- If `/.retaia` is missing, Core MUST create it during boot/update migration before startup validation.
- If marker creation fails, marker JSON is invalid, required marker schema update fails (based on the JSON field `version` in `/.retaia`), or `APP_STORAGE_ID` mismatches marker `storage_id`, Core MUST fail fast at boot with an explicit startup error.
- Marker migration/update failure (including required upgrade of the JSON field `version` in `/.retaia`, create/write/atomic rename) MUST fail fast at boot/update; degraded mode is forbidden for this control.
- In multi-mount setups, validation/migration MUST succeed for every configured `storage_id`; one failing mount MUST fail startup globally.

Startup error code mapping (normative):

- `CORE_STORAGE_MARKER_CREATE_FAILED`
- `CORE_STORAGE_MARKER_JSON_INVALID`
- `CORE_STORAGE_MARKER_STORAGE_ID_MISMATCH`
- `CORE_STORAGE_MARKER_SCHEMA_UPGRADE_FAILED`

## 5. Example compose pattern

```yaml
services:
  core:
    image: ghcr.io/retaia/retaia-core:v1.0.0
    env_file:
      - .env
      - .env.prod
      - .env.local
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
    ports: ["443:443"]
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
retaia.local {
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
CORE_API_URL=https://retaia.local/api/v1
```

Certificate note:

- `retaia.local` is illustrative.
- The shared runtime name MAY be a LAN DNS name, mDNS name, split-horizon name or equivalent routable host name.
- The certificate MAY be public or signed by a local CA installed on participating clients.

## 6. Derived upload sizing (normative)

Large derived files such as video previews MAY be several hundreds of MiB, but the shared runtime profile MUST handle them through chunked uploads only.

Rules:

- `POST /assets/{uuid}/derived/upload/part` MUST be dimensioned for one part, never for the whole derived file.
- Core MUST publish a `max_part_size_bytes` value low enough to fit under every effective request-body limit on the exposed path.
- The effective limit is the minimum of:
  - front proxy request-body limit
  - PHP `upload_max_filesize`
  - PHP `post_max_size`
  - any app/server middleware limit on multipart bodies
- `post_max_size` MUST be greater than or equal to `upload_max_filesize`.
- Core MUST process each uploaded part from the PHP temporary file and persist it immediately; rebuilding the whole derived file in RAM is forbidden.
- Temporary upload storage MUST be distinct from the published current derived file.
- Expired or incomplete multipart uploads MUST be garbage-collected.

Recommended baseline:

- `max_part_size_bytes`: `8 MiB` to `32 MiB`
- request timeout budget per part: `60s` to `120s`
- enough temporary disk space for several concurrent parts

Operational consequence:

- if one of these limits is lower than `max_part_size_bytes`, the deployment is non-conforming until the published limit or infra settings are adjusted

Example `php.ini` profile:

```ini
file_uploads = On
upload_max_filesize = 32M
post_max_size = 40M
max_file_uploads = 20
max_execution_time = 120
max_input_time = 120
memory_limit = 256M
; optional explicit temp dir if the default tmp volume is too small
; upload_tmp_dir = /var/www/html/var/tmp/uploads
```

Example NGINX front limit:

```nginx
server {
    listen 443 ssl http2;
    server_name retaia.local;

    client_max_body_size 40m;

    location /api/ {
        root /var/www/html/public;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME /var/www/html/public/index.php;
        fastcgi_pass core:9000;
        fastcgi_read_timeout 120s;
    }
}
```

Example Traefik static/dynamic intent:

```yaml
http:
  middlewares:
    retaia-upload-limit:
      buffering:
        maxRequestBodyBytes: 41943040

  routers:
    retaia-api:
      rule: Host(`retaia.local`) && PathPrefix(`/api/`)
      middlewares:
        - retaia-upload-limit
      service: retaia-core
```

Sizing rule for operators:

- choose the proxy/PHP limits first
- then publish a `max_part_size_bytes` that stays strictly below them with multipart overhead margin
- never increase `max_part_size_bytes` above the lowest effective limit in the chain

## 7. API request flow

1. Browser/UI and workstation agents call `https://<shared-host>/api/v1/...`.
2. The exposed TLS entrypoint terminates TLS directly or forwards through an optional front reverse proxy.
3. If a front reverse proxy is present, it matches `/api/*` and forwards to Core PHP-FPM (`core:9000`).
4. Core executes request and returns response through the exposed TLS entrypoint to callers.

This keeps Core private while exposing a single shared `HTTPS` gateway.
