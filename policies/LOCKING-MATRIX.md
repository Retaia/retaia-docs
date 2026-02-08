# Locking Matrix — Retaia Core + Retaia Agent

Ce document définit la matrice normative de concurrence entre actions.

## 1) Types de verrous

* `job_lease` (par job, TTL + heartbeat)
* `asset_move_lock` (par asset/fichier/rush, sans heartbeat)
* `asset_purge_lock` (par asset)

## 2) Règles globales

* un asset avec `asset_move_lock` est non claimable
* un asset avec `asset_purge_lock` est non claimable
* `MOVE_QUEUED` interdit toute mutation hors moteur de move
* `PURGED` interdit toute mutation

## 3) Matrice d'action (ALLOW/DENY)

`claim_job` vs état/lock :

* ALLOW si `state != MOVE_QUEUED` et `state != PURGED` et aucun `asset_move_lock`/`asset_purge_lock`
* DENY sinon (`409 STATE_CONFLICT`)

`reprocess` :

* ALLOW si `state in {PROCESSED, ARCHIVED, REJECTED}` et aucun lock actif
* DENY sinon (`409 STATE_CONFLICT`)

`reopen` :

* ALLOW si `state in {ARCHIVED, REJECTED}` et aucun lock actif
* DENY sinon (`409 STATE_CONFLICT`)

`decision_write` :

* ALLOW si `state in {DECISION_PENDING, DECIDED_KEEP, DECIDED_REJECT}` et aucun lock actif
* DENY sinon (`409 STATE_CONFLICT`)

`move_apply` :

* ALLOW si `state in {DECIDED_KEEP, DECIDED_REJECT}`
* moteur move DOIT poser `asset_move_lock` avant filesystem op
* moteur move DOIT release lock après filesystem op et avant transition finale

`purge_execute` :

* ALLOW si `state == REJECTED` et aucun `job_lease`/`asset_move_lock`
* moteur purge DOIT poser `asset_purge_lock` pendant l'opération
* DENY sinon (`409 STATE_CONFLICT`)

## 4) Ordonnancement recommandé

Priorité en conflit sur un même asset :

1. `purge_execute`
2. `move_apply`
3. `reprocess`
4. `claim_job`

Objectif : éviter les demi-états sur filesystem.

## 5) Observabilité minimale

Pour chaque lock acquire/release :

* `asset_uuid`
* type de lock
* acteur
* timestamp
* résultat (`acquired|released|failed`)

## Références associées

* [STATE-MACHINE.md](../state-machine/STATE-MACHINE.md)
* [WORKFLOWS.md](../workflows/WORKFLOWS.md)
* [API-CONTRACTS.md](../api/API-CONTRACTS.md)
