# Authz Matrix — Retaia Core + Retaia Agent

Ce document définit la matrice d'autorisation normative par endpoint, scope et état.

## 1) Principes

* deny by default
* aucune élévation implicite
* vérification scope + état asset

## 2) Matrice v1 (résumé)

`GET /assets`, `GET /assets/{uuid}`

* scopes: `assets:read`
* acteurs: humain, agent, client intégré

`PATCH /assets/{uuid}`

* scope: `assets:write`
* acteur: humain uniquement
* deny si `state == PURGED`

`POST /assets/{uuid}/decision`

* scope: `decisions:write`
* acteur: humain uniquement
* états: `DECISION_PENDING|DECIDED_KEEP|DECIDED_REJECT`

`POST /assets/{uuid}/reprocess`

* scope: `assets:write`
* acteur: humain uniquement
* états: `PROCESSED|ARCHIVED|REJECTED`

`POST /jobs/*`

* scopes: `jobs:claim|jobs:heartbeat|jobs:submit`
* acteur: agent uniquement

`POST /decisions/preview`, `POST /decisions/apply` (**v1.1+**)

* scope: `decisions:write`
* acteur: humain uniquement

`POST /batches/moves`

* scope: `batches:execute`
* acteur: humain uniquement

`POST /assets/{uuid}/purge`

* scope: `purge:execute`
* acteur: humain uniquement
* état: `REJECTED`

## 3) Codes d'erreur authz

* scope manquant -> `403 FORBIDDEN_SCOPE`
* acteur interdit -> `403 FORBIDDEN_ACTOR`
* état invalide -> `409 STATE_CONFLICT`

## 4) Audit minimum

Pour chaque refus authz :

* `actor_id`
* endpoint
* scope manquant/interdit
* état asset (si applicable)
* timestamp

## Références associées

* [API-CONTRACTS.md](../api/API-CONTRACTS.md)
* [ERROR-MODEL.md](../api/ERROR-MODEL.md)
