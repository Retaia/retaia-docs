# HTTP Status Uniformity — Tickets d'implementation atomiques

Ce document fige les tickets d'implementation pour appliquer la normalisation HTTP v1 runtime.

## TICKET-CORE-HTTP-001

Objectif:

* aligner Core sur la matrice HTTP v1 (device flow + client token)

Scope:

* `POST /auth/clients/device/poll`:
  * etats metier portes par `200` + `status`
  * ne plus emettre `401 AUTHORIZATION_PENDING`
  * ne plus emettre `403 ACCESS_DENIED`
* `POST /auth/clients/token`:
  * `client_kind=UI_RUST` retourne `403 FORBIDDEN_ACTOR` uniquement

Definition of Done:

* handlers Core alignes sur les codes ci-dessus
* mapping `ErrorResponse.code` coherent avec le statut HTTP
* changelog runtime/migration core documente

Tests minimum:

* integration auth/device:
  * `poll` pending/denied/expired -> `200` + `status`
  * `poll` invalid device_code -> `400 INVALID_DEVICE_CODE`
* integration auth/client token:
  * `client_kind=UI_RUST` -> `403 FORBIDDEN_ACTOR`

## TICKET-UI-RUST-HTTP-002

Objectif:

* adapter UI_RUST au pilotage device flow par `status` en `200`

Scope:

* parser `POST /auth/clients/device/poll`:
  * `PENDING` => polling continue
  * `APPROVED` => finalisation bootstrap
  * `DENIED`/`EXPIRED` => UX terminale explicite
* supprimer toute logique qui depend de `401/403` sur `device/poll`

Definition of Done:

* UX device flow stable desktop (Rust/Tauri)
* aucun fallback vers interpretation legacy `401/403`
* erreurs HTTP restantes (`400`, `429`) gerees proprement

Tests minimum:

* tests UI/e2e device flow:
  * pending -> approved
  * pending -> denied
  * pending -> expired
  * invalid device_code (`400`) et slow_down (`429`)

## TICKET-AGENT-MCP-HTTP-003

Objectif:

* adapter agent/mcp au meme pilotage status-driven

Scope:

* boucle de poll agent/mcp:
  * pilotage par `status` en `200`
  * gestion retry/backoff sur `429`
  * arret immediat sur `DENIED`/`EXPIRED`
* suppression de la dependance aux anciens signaux `401/403`

Definition of Done:

* fonctionnement headless Linux (Raspberry Pi) + desktop macOS/Windows
* aucune interpretation legacy `401/403` pour `device/poll`
* logs telemetry avec statut final (`APPROVED|DENIED|EXPIRED`)

Tests minimum:

* tests compat client:
  * AGENT headless bootstrap device flow
  * MCP bootstrap + orchestration sans traitement
  * comportement retry deterministe sur `429`
