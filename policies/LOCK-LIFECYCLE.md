# Lock Lifecycle — Retaia multi-apps

Ce document définit le cycle de vie normatif des verrous.

## 1) Types

* `job_lease` : TTL + heartbeat
* `asset_move_lock` : lock exclusif d'opération filesystem move
* `asset_purge_lock` : lock exclusif d'opération purge

## 2) TTL et expiration

`job_lease` :

* TTL par défaut : 120s
* heartbeat recommandé : toutes les 30s
* expiration => job reclaimable

`asset_move_lock` :

* TTL par défaut : 300s
* pas de heartbeat
* expiration => lock récupérable par watchdog

`asset_purge_lock` :

* TTL par défaut : 300s
* pas de heartbeat
* expiration => lock récupérable par watchdog

## 3) Fencing token

Chaque lock porte un `fencing_token` monotone.

Règle :

* toute écriture d'état post-lock DOIT vérifier le `fencing_token`
* token obsolète => `409 STALE_LOCK_TOKEN`

## 4) Séquence move atomique

Ordre obligatoire :

1. acquire `asset_move_lock`
2. opérations filesystem
3. mise à jour path + audit
4. release `asset_move_lock`
5. transition vers `ARCHIVED|REJECTED`

## 5) Recovery crash

Si crash entre étapes :

* watchdog détecte lock expiré
* statut move/asset passe en `recovering`
* reprise idempotente depuis dernier point audité
* jamais de transition d'état sans validation FS réussie

Matrice normative minimale :

* FS non modifié, DB non modifiée :
  * release/expiration du lock
  * reprise simple de l'opération possible
* FS modifié, DB non modifiée :
  * l'asset reste dans l'état métier pré-opération
  * recovery DOIT prioriser la réconciliation filesystem puis rejouer la mise à jour DB/audit avant toute transition d'état
* FS modifié, DB partiellement modifiée mais transition finale absente :
  * recovery DOIT reprendre depuis le dernier audit persistant cohérent
  * aucune publication d'état final (`ARCHIVED`, `REJECTED`, `PURGED`) sans validation finale FS réussie
* DB marquée finale alors que FS invalide :
  * état non conforme
  * un événement ops `ERROR` DOIT être émis
  * l'asset DOIT être placé en recovery manuel/assisté, jamais silencieusement considéré comme terminé

Invariants de recovery :

* le lock expiré ne vaut jamais validation de l'opération
* l'audit persistant fait foi pour déterminer le dernier point de reprise
* aucune implémentation ne PEUT considérer `ARCHIVED`, `REJECTED` ou `PURGED` comme acquis tant que la validation FS n'est pas confirmée
* toute routine de recovery DOIT être idempotente

## 6) Purge

Ordre obligatoire :

1. acquire `asset_purge_lock`
2. suppression originaux + sidecars + dérivés
3. audit de purge
4. release lock
5. transition `REJECTED -> PURGED`

## Références associées

* [LOCKING-MATRIX.md](LOCKING-MATRIX.md)
* [WORKFLOWS.md](../workflows/WORKFLOWS.md)
* [API-CONTRACTS.md](../api/API-CONTRACTS.md)
