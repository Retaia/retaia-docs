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

* `400` -> `INVALID_TOKEN`, `INVALID_2FA_CODE`, `INVALID_DEVICE_CODE`, `EXPIRED_DEVICE_CODE`
* `401` -> `UNAUTHORIZED`, `MFA_REQUIRED`
* `403` -> `FORBIDDEN_SCOPE`, `FORBIDDEN_ACTOR`
* `409` -> `STATE_CONFLICT`, `IDEMPOTENCY_CONFLICT`, `STALE_LOCK_TOKEN`, `NAME_COLLISION_EXHAUSTED`, `MFA_ALREADY_ENABLED`, `MFA_NOT_ENABLED`
* `410` -> `PURGED`
* `404` -> `USER_NOT_FOUND`
* `422` -> `VALIDATION_FAILED`
* `423` -> `LOCK_REQUIRED`, `LOCK_INVALID`
* `426` -> `UNSUPPORTED_FEATURE_FLAGS_CONTRACT_VERSION`
* `429` -> `RATE_LIMITED`, `TOO_MANY_ATTEMPTS`, `SLOW_DOWN`
* `503` -> `TEMPORARY_UNAVAILABLE`

Codes auth complémentaires (selon endpoint/policy) :

* `EMAIL_NOT_VERIFIED`

## 4) Invariants

* pas de payload d'erreur ad-hoc par endpoint
* `correlation_id` présent sur toute réponse d'erreur
* `retryable` reflète la policy serveur, pas une supposition client

## Références associées

* [API-CONTRACTS.md](API-CONTRACTS.md)
* [openapi/v1.yaml](openapi/v1.yaml)
