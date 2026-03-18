# Authz Matrix — Retaia

Ce document définit la matrice d'autorisation normative par endpoint, scope et état.

## 1) Principes

* deny by default
* aucune élévation implicite
* vérification scope + acteur + état asset
* séparation stricte acteurs interactifs vs techniques

Acteurs normatifs :

* `USER_INTERACTIVE` (client `UI_WEB` application web, ou `AGENT_UI` pour l'agent en CLI ou GUI)
* `AGENT_TECHNICAL` (daemon/service non-interactif de processing)
* `MCP_TECHNICAL` (client technique non-interactif d'orchestration MCP)
* `TECHNICAL_ACTORS` = `AGENT_TECHNICAL|MCP_TECHNICAL`
* `ADMIN_INTERACTIVE` (sous-ensemble `USER_INTERACTIVE` avec droits admin)
* `client_kind` interactif: `UI_WEB|AGENT`; `client_kind` technique: `AGENT|MCP`
* rollout projet global actif: `UI_WEB` en v1; `AGENT_UI` et `MCP` en v1.1
* gate applicatif: `app_feature_enabled.features.ai=false` => seules les fonctionnalités MCP dépendantes de l’AI sont refusées (`403 FORBIDDEN_SCOPE`), sans désactiver le client MCP dans son ensemble
* `AGENT_UI` PEUT converger fonctionnellement avec `UI_WEB` pour les actions humaines, sans fusionner son identité avec le daemon `AGENT_TECHNICAL`
* aucune action user-scoped ou admin-scoped ne DOIT être implicitement transférée de `AGENT_UI` vers `AGENT_TECHNICAL`

## 2) Matrice v1 (résumé)

### Auth

`POST /auth/login`

* acteur: public (anonyme autorisé)
* scope: aucun

`POST /auth/refresh`, `POST /auth/webauthn/authenticate/options`, `POST /auth/webauthn/authenticate/verify`

* acteur: public (anonyme autorisé)
* scope: aucun

`POST /auth/webauthn/register/options`, `POST /auth/webauthn/register/verify`

* acteur: `USER_INTERACTIVE`
* scope: session utilisateur valide (`UserBearerAuth`)

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
* contrainte: tentative d'écriture sur un flag encore `code-backed` => `409 STATE_CONFLICT`

`POST /auth/verify-email/admin-confirm`

* acteur: `ADMIN_INTERACTIVE`
* scope: policy admin (sinon `403 FORBIDDEN_ACTOR` / `FORBIDDEN_SCOPE`)

`POST /auth/clients/{client_id}/revoke-token`, `POST /auth/clients/{client_id}/rotate-secret`, `POST /auth/mcp/{client_id}/rotate-key`

* acteur: `ADMIN_INTERACTIVE`
* scope: policy admin
* contrainte: `client_kind=UI_WEB` => révocation refusée (`403`)

`POST /auth/mcp/register`

* acteur: `USER_INTERACTIVE`
* scope: session utilisateur valide (`UserBearerAuth`) + droit d'enrôlement technique

`POST /auth/mcp/challenge`, `POST /auth/mcp/token`

* acteur: `MCP_TECHNICAL`
* scope: aucun (challenge/réponse asymétrique)

`POST /auth/clients/token`

* acteur: `AGENT_TECHNICAL`
* scope: aucun (auth par `client_id + secret_key`)
* contrainte: `client_kind=AGENT` uniquement
* règle forte: `client_id + secret_key` autorise le client technique et permet de mint un bearer technique; la preuve forte d'instance pour les écritures reste `agent_id + OpenPGP + signature`

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
* acteur `MCP_TECHNICAL`: explicitement interdit (`403 FORBIDDEN_ACTOR`)
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


Règle destructive MCP (opposable) :

* `MCP_TECHNICAL` NE DOIT JAMAIS pouvoir exécuter un endpoint destructif ou de suppression
* cela inclut `DELETE`, `purge`, et toute future opération destructive équivalente

Règle d'identité technique forte (opposable) :

* `AGENT_TECHNICAL` : `client_id + secret_key` = bootstrap et autorisation technique
* `AGENT_TECHNICAL` : `agent_id + clé OpenPGP + signature` = preuve forte d'instance
* une écriture agent mutatrice ne DOIT JAMAIS être acceptée sur la seule base du bearer technique
