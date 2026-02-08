# Error Model — API v1

Ce document définit le payload d'erreur normatif commun.

## 1) Structure

Toutes les erreurs JSON DOIVENT suivre :

```json
{
  "code": "STATE_CONFLICT",
  "message": "Human-readable summary",
  "details": {},
  "retryable": false,
  "correlation_id": "req_..."
}
```

## 2) Champs

* `code` (string, obligatoire)
* `message` (string, obligatoire)
* `details` (object, optionnel)
* `retryable` (boolean, obligatoire)
* `correlation_id` (string, obligatoire)

## 3) Mapping recommandé

* `403` -> `FORBIDDEN_SCOPE`, `FORBIDDEN_ACTOR`
* `409` -> `STATE_CONFLICT`, `IDEMPOTENCY_CONFLICT`, `STALE_LOCK_TOKEN`, `NAME_COLLISION_EXHAUSTED`
* `410` -> `PURGED`
* `422` -> `VALIDATION_FAILED`
* `423` -> `LOCK_REQUIRED`, `LOCK_INVALID`
* `429` -> `RATE_LIMITED`
* `503` -> `TEMPORARY_UNAVAILABLE`

## 4) Invariants

* pas de payload d'erreur ad-hoc par endpoint
* `correlation_id` présent sur toute réponse d'erreur
* `retryable` reflète la policy serveur, pas une supposition client

## Références associées

* [API-CONTRACTS.md](API-CONTRACTS.md)
* [openapi/v1.yaml](openapi/v1.yaml)
