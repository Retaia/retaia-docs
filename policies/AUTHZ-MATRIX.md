# Authz Matrix — Retaia Core + Retaia Agent

Ce document définit la matrice d'autorisation normative par endpoint, scope et état.

## 1) Principes

* deny by default
* aucune élévation implicite
* vérification scope + acteur + état asset
* séparation stricte acteurs interactifs vs techniques

Acteurs normatifs :

* `USER_INTERACTIVE` (client `UI_WEB` web app ou desktop `RUST_UI`, ou shell/CLI `AGENT` opéré par un humain pour bootstrap/administration)
* `AGENT_TECHNICAL` (daemon/service non-interactif de processing)
* `MCP_TECHNICAL` (client technique non-interactif d'orchestration MCP)
* `TECHNICAL_ACTORS` = `AGENT_TECHNICAL|MCP_TECHNICAL`
* `ADMIN_INTERACTIVE` (sous-ensemble `USER_INTERACTIVE` avec droits admin)
* `client_kind` interactif: `UI_WEB|AGENT`; `client_kind` technique: `AGENT|MCP`
* rollout projet global actif: `UI_WEB` (clients `UI_WEB_APP` + `RUST_UI`) et `MCP` (`MCP_CLIENT`) en v1.1
* gate applicatif: `app_feature_enabled.features.ai=false` => acteur `client_kind=MCP` refusé (`403 FORBIDDEN_SCOPE`) sur bootstrap UI, auth API key et runtime

## 2) Matrice v1 (résumé)

### Auth

`POST /auth/login`

* acteur: public (anonyme autorisé)
* scope: aucun

`POST /auth/2fa/setup|enable|disable`, `POST /auth/logout`, `GET /auth/me`

* acteur: `USER_INTERACTIVE`
* scope: session utilisateur valide (`UserBearerAuth`)

`GET /app/features`

* acteur: `ADMIN_INTERACTIVE`
* scope: policy admin (sinon `403 FORBIDDEN_ACTOR` / `FORBIDDEN_SCOPE`)
* portée: retourne les switches applicatifs effectifs (globaux application)

`PATCH /app/features`

* acteur: `ADMIN_INTERACTIVE`
* scope: policy admin (sinon `403 FORBIDDEN_ACTOR` / `FORBIDDEN_SCOPE`)
* portée: met à jour les switches applicatifs globaux

`GET /auth/me/features`, `PATCH /auth/me/features`

* acteur: `USER_INTERACTIVE`
* scope: session utilisateur valide (`UserBearerAuth`)
* portée: préférences feature de l'utilisateur courant
* contrainte: désactivation d'une feature `CORE_V1_GLOBAL` interdite (`403 FORBIDDEN_SCOPE`)

`GET /app/policy`

* acteur: `USER_INTERACTIVE|TECHNICAL_ACTORS`
* scope: `UserBearerAuth` ou `TechnicalBearerAuth`
* portée: retourne la policy runtime (`server_policy.feature_flags`)

`POST /app/policy`

* acteur: `ADMIN_INTERACTIVE`
* scope: policy admin
* portée: met à jour les `feature_flags` runtime quand ils sont DB-backed ou pilotés par un backend mutable équivalent

`POST /auth/verify-email/admin-confirm`

* acteur: `ADMIN_INTERACTIVE`
* scope: policy admin (sinon `403 FORBIDDEN_ACTOR` / `FORBIDDEN_SCOPE`)

`POST /auth/clients/{client_id}/revoke-token`, `POST /auth/clients/{client_id}/rotate-secret`

* acteur: `ADMIN_INTERACTIVE`
* scope: policy admin
* contrainte: `client_kind=UI_WEB` => révocation refusée (`403`)

`POST /auth/clients/token`

* acteur: `AGENT_TECHNICAL`
* scope: aucun (auth par `client_id + secret_key`)
* contrainte: `client_kind=AGENT` uniquement

`POST /auth/clients/device/start|poll|cancel`

* acteur: `AGENT_TECHNICAL`
* scope: aucun
* contrainte: `client_kind=AGENT` uniquement

Validation UI du device flow (`verification_uri*`)

* acteur: `USER_INTERACTIVE`
* scope: session utilisateur valide (`UserBearerAuth`)
* si 2FA est activée pour le compte utilisateur, validation OTP obligatoire avant approval

### Assets / Derived

* scopes: `assets:read`
* acteurs: `USER_INTERACTIVE`, `AGENT_TECHNICAL`, `MCP_TECHNICAL`

`PATCH /assets/{uuid}`

* scope: `assets:write` (metadata) ou `decisions:write` (transition `state`)
* acteur: `USER_INTERACTIVE`
* deny si `state == PURGED`

`POST /assets/{uuid}/reprocess`

* scope: `assets:write`
* acteur: `USER_INTERACTIVE`
* états: `PROCESSED|ARCHIVED|REJECTED`

`POST /jobs/*`

* scopes: `jobs:claim|jobs:heartbeat|jobs:submit`
* acteur: `AGENT_TECHNICAL`
* contrainte: `client_kind=MCP` interdit (`403 FORBIDDEN_ACTOR`)

`GET /ops/ingest/diagnostics|/ops/readiness|/ops/locks|/ops/jobs/queue|/ops/agents|/ops/ingest/unmatched`

* acteur: `ADMIN_INTERACTIVE`
* scope: policy admin (sinon `403 FORBIDDEN_ACTOR` / `FORBIDDEN_SCOPE`)

`POST /ops/locks/recover|/ops/ingest/requeue`

* acteur: `ADMIN_INTERACTIVE`
* scope: policy admin (sinon `403 FORBIDDEN_ACTOR` / `FORBIDDEN_SCOPE`)


`POST /assets/{uuid}/purge`

* scope: `purge:execute`
* acteur: `USER_INTERACTIVE`
* état: `REJECTED`

## 3) Codes d'erreur authz

* scope manquant -> `403 FORBIDDEN_SCOPE`
* acteur interdit -> `403 FORBIDDEN_ACTOR`
* état invalide -> `409 STATE_CONFLICT`

## 4) Audit minimum

Pour chaque refus authz :

* `actor_id`
* `actor_type`
* endpoint
* scope manquant/interdit
* état asset (si applicable)
* timestamp

## Références associées

* [API-CONTRACTS.md](../api/API-CONTRACTS.md)
* [ERROR-MODEL.md](../api/ERROR-MODEL.md)
