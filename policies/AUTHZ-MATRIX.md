# Authz Matrix — Retaia Core + Retaia Agent

Ce document définit la matrice d'autorisation normative par endpoint, scope et état.

## 1) Principes

* deny by default
* aucune élévation implicite
* vérification scope + acteur + état asset
* séparation stricte acteurs interactifs vs techniques

Acteurs normatifs :

* `USER_INTERACTIVE` (UI web/desktop, agent CLI/GUI opéré par un humain)
* `AGENT_TECHNICAL` (daemon/service non-interactif)
* `CLIENT_TECHNICAL` (intégration non-interactive)
* `ADMIN_INTERACTIVE` (sous-ensemble `USER_INTERACTIVE` avec droits admin)
* `AGENT_CLI`/`AGENT_GUI` peuvent exister dans les deux modes selon le flux d’auth (login utilisateur vs secret-key/OAuth2)

## 2) Matrice v1 (résumé)

### Auth

`POST /auth/login`

* acteur: public (anonyme autorisé)
* scope: aucun

`POST /auth/2fa/setup|enable|disable`, `POST /auth/logout`, `GET /auth/me`

* acteur: `USER_INTERACTIVE`
* scope: session utilisateur valide (`UserBearerAuth`)

`POST /auth/verify-email/admin-confirm`

* acteur: `ADMIN_INTERACTIVE`
* scope: policy admin (sinon `403 FORBIDDEN_ACTOR` / `FORBIDDEN_SCOPE`)

`POST /auth/clients/{client_id}/revoke-token`, `POST /auth/clients/{client_id}/rotate-secret`

* acteur: `ADMIN_INTERACTIVE`
* scope: policy admin
* contrainte: `client_kind in {UI_WEB, UI_ELECTRON, UI_TAURI}` (aliases legacy `UI|ELECTRON|TAURI`) => révocation refusée (`403`)

`POST /auth/clients/token`

* acteur: `CLIENT_TECHNICAL|AGENT_TECHNICAL`
* scope: aucun (auth par `client_id + secret_key`)
* contrainte: `client_kind in {AGENT_CLI, AGENT_GUI, MCP}` uniquement (aliases legacy `ELECTRON|TAURI` acceptés en compatibilité)

### Assets / Derived

* scopes: `assets:read`
* acteurs: `USER_INTERACTIVE`, `AGENT_TECHNICAL`, `CLIENT_TECHNICAL`

`PATCH /assets/{uuid}`

* scope: `assets:write`
* acteur: `USER_INTERACTIVE`
* deny si `state == PURGED`

`POST /assets/{uuid}/decision`

* scope: `decisions:write`
* acteur: `USER_INTERACTIVE`
* états: `DECISION_PENDING|DECIDED_KEEP|DECIDED_REJECT`

`POST /assets/{uuid}/reprocess`

* scope: `assets:write`
* acteur: `USER_INTERACTIVE`
* états: `PROCESSED|ARCHIVED|REJECTED`

`POST /jobs/*`

* scopes: `jobs:claim|jobs:heartbeat|jobs:submit`
* acteur: `AGENT_TECHNICAL`

`POST /decisions/preview`, `POST /decisions/apply` (**v1.1+**)

* scope: `decisions:write`
* acteur: `USER_INTERACTIVE`

`POST /batches/moves`

* scope: `batches:execute`
* acteur: `USER_INTERACTIVE`

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
