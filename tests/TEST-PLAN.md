# Test Plan — Normative Minimum (v1)

Ce document définit le minimum de tests opposables pour valider une implémentation Retaia.

## 1) State machine

Tests obligatoires :

* toutes transitions autorisées passent
* transitions interdites renvoient `409 STATE_CONFLICT`
* `PURGED` est terminal

## 2) Jobs & leases

Tests obligatoires :

* claim atomique concurrent (un gagnant)
* lease expiry rend le job reclaimable
* heartbeat prolonge `locked_until`
* job `pending` sans agent compatible reste `pending` sans erreur

## 3) Processing profiles

Tests obligatoires :

* `PROCESSED` atteint uniquement quand jobs `required` du profil sont complets
* `audio_music` n'exige pas `transcribe_audio`
* `audio_voice` exige `transcribe_audio`
* changement de profil après claim exige reprocess

## 4) Merge patch par domaine

Tests obligatoires :

* `transcribe_audio` n'efface jamais `facts/derived`
* `extract_facts` n'efface jamais `transcript`
* clés hors domaine autorisé renvoient `422 VALIDATION_FAILED`

## 5) Batch move

Tests obligatoires :

* éligibilité limitée à `DECIDED_KEEP|DECIDED_REJECT`
* lock par asset posé pendant filesystem op
* release lock avant transition finale
* collision nom => suffixe `__{short_nonce}`
* un échec asset ne bloque pas tout le batch

## 6) Purge

Tests obligatoires :

* purge seulement depuis `REJECTED`
* purge supprime originaux + sidecars + dérivés
* purge idempotente avec `Idempotency-Key`

## 7) Idempotence API

Tests obligatoires :

* même clé + même body => même réponse
* même clé + body différent => `409 IDEMPOTENCY_CONFLICT`
* endpoints critiques refusent l'absence de clé

## 8) Contrats API

Tests obligatoires :

* conformité des réponses à `api/openapi/v1.yaml`
* détection de drift `API-CONTRACTS.md` vs OpenAPI en CI

## 9) Couverture minimale

Minimum :

* scénarios P0 ci-dessus à 100%
* chemins critiques move/purge/lock couverts avant merge

## Références associées

* [STATE-MACHINE.md](../state-machine/STATE-MACHINE.md)
* [JOB-TYPES.md](../definitions/JOB-TYPES.md)
* [API-CONTRACTS.md](../api/API-CONTRACTS.md)
* [CODE-QUALITY.md](../change-management/CODE-QUALITY.md)
