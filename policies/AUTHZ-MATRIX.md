# Authz Matrix — Retaia Core + Retaia Agent

Ce document définit la matrice d'autorisation normative par endpoint, scope et état.

## 1) Principes

* deny by default
* aucune élévation implicite
* vérification scope + acteur + état asset
* séparation stricte acteurs interactifs vs techniques

Acteurs normatifs :

* `USER_INTERACTIVE` (client `UI_WEB` web app ou desktop `RUST_UI`, `UI_MOBILE` Android/iOS, ou client `AGENT` opéré par un humain)
* `AGENT_TECHNICAL` (daemon/service non-interactif)
* `CLIENT_TECHNICAL` (client technique non-interactif, incluant MCP)
* `ADMIN_INTERACTIVE` (sous-ensemble `USER_INTERACTIVE` avec droits admin)
* `client_kind` interactif: `UI_WEB|UI_MOBILE|AGENT`; `client_kind` technique: `AGENT|MCP`
* rollout projet global: `UI_WEB` (clients `UI_WEB_APP` + `RUST_UI`) et `MCP` (`MCP_CLIENT`) en v1.1, `UI_MOBILE` en v1.2
* gate applicatif: `app_feature_enabled.features.ai=false` => acteur `client_kind=MCP` refusé (`403 FORBIDDEN_SCOPE`) sur bootstrap/token/runtime

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

* acteur: `USER_INTERACTIVE` ou `CLIENT_TECHNICAL`
* scope: `UserBearerAuth` ou `OAuth2ClientCredentials`
* portée: retourne la policy runtime (`server_policy.feature_flags`)

`POST /auth/verify-email/admin-confirm`

* acteur: `ADMIN_INTERACTIVE`
* scope: policy admin (sinon `403 FORBIDDEN_ACTOR` / `FORBIDDEN_SCOPE`)

`POST /auth/clients/{client_id}/revoke-token`, `POST /auth/clients/{client_id}/rotate-secret`

* acteur: `ADMIN_INTERACTIVE`
* scope: policy admin
* contrainte: `client_kind=UI_WEB` => révocation refusée (`403`)

`POST /auth/clients/token`

* acteur: `CLIENT_TECHNICAL|AGENT_TECHNICAL`
* scope: aucun (auth par `client_id + secret_key`)
* contrainte: `client_kind in {AGENT, MCP}` uniquement

`POST /auth/clients/device/start|poll|cancel`

* acteur: `CLIENT_TECHNICAL|AGENT_TECHNICAL`
* scope: aucun
* contrainte: `client_kind in {AGENT, MCP}` uniquement

Validation UI du device flow (`verification_uri*`)

* acteur: `USER_INTERACTIVE`
* scope: session utilisateur valide (`UserBearerAuth`)
* si 2FA est activée pour le compte utilisateur, validation OTP obligatoire avant approval

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
* contrainte: `client_kind=MCP` interdit (`403 FORBIDDEN_ACTOR`)

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
