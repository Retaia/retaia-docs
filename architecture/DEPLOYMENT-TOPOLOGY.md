# Deployment Topology (NAS + Workstations)

Reference deployment profile for self-hosted environments where:

- Core runs on a NAS/server
- UI is exposed on LAN
- processing agents run on user workstations (outside Docker network)

This profile is normative for interoperability expectations between `core`, `ui`, and `agent`.

## 1. Topology

- `core` service is private (not published directly on LAN).
- `ui` service is published on LAN (example: `http://192.168.0.14:8080`).
- `ui` reverse-proxies `/api/*` to private Core (`core:8000` inside Docker network).
- Workstation agents call Core through the same LAN gateway URL:
  - `http://192.168.0.14:8080/api/v1`

## 2. Client URL rules

- Browser-based UI clients MUST use a relative API base path (`/api/v1`).
- Browser-based UI clients MUST NOT use internal Docker hostnames such as `core:8000`.
- External workstation agents MUST use a routable LAN/edge URL (example above), never Docker-internal DNS names.

## 3. Security and exposure

- Core container SHOULD remain non-exposed on host ports in this profile.
- Only the UI reverse-proxy port is exposed to LAN users/agents.
- Access control (authN/authZ, network policy, optional VPN/allowlist) remains mandatory.

## 4. Example compose pattern

```yaml
services:
  core:
    image: ghcr.io/retaia/retaia-core:v1.0.0
    env_file: .env

  ui:
    image: ghcr.io/retaia/retaia-ui:v1.0.0
    environment:
      API_BASE_URL: /api/v1
      API_UPSTREAM: core:8000
    depends_on: [core]
    ports: ["8080:80"]
```

Agent workstation configuration example:

```text
CORE_API_URL=http://192.168.0.14:8080/api/v1
```
