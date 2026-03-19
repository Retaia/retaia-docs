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

## 3) Mapping normatif

* `400` -> `INVALID_TOKEN`, `INVALID_2FA_CODE`, `INVALID_DEVICE_CODE`, `EXPIRED_DEVICE_CODE`, `VALIDATION_FAILED` (paramètres query/path/header invalides)
* `401` -> `UNAUTHORIZED`, `MFA_REQUIRED`
* `403` -> `FORBIDDEN_SCOPE`, `FORBIDDEN_ACTOR`
* `409` -> `STATE_CONFLICT`, `IDEMPOTENCY_CONFLICT`, `STALE_LOCK_TOKEN`, `NAME_COLLISION_EXHAUSTED`, `MFA_ALREADY_ENABLED`, `MFA_NOT_ENABLED`
* `410` -> `PURGED`
* `404` -> `USER_NOT_FOUND`
* `412` -> `PRECONDITION_FAILED`
* `422` -> `VALIDATION_FAILED` (body JSON valide mais payload métier invalide)
* `423` -> `LOCK_REQUIRED`, `LOCK_INVALID`
* `426` -> `UNSUPPORTED_FEATURE_FLAGS_CONTRACT_VERSION`
* `428` -> `PRECONDITION_REQUIRED`
* `429` -> `TOO_MANY_ATTEMPTS`, `SLOW_DOWN`
* `503` -> `TEMPORARY_UNAVAILABLE`

Codes auth complémentaires (selon endpoint/policy) :

* `EMAIL_NOT_VERIFIED`

## 4) Invariants

* pas de payload d'erreur ad-hoc par endpoint
* `correlation_id` présent sur toute réponse d'erreur
* `retryable` reflète la policy serveur, pas une supposition client
* `423` est réservé aux verrous requis mais absents ou invalides
* `409 STALE_LOCK_TOKEN` est réservé aux tokens de verrou/fencing devenus obsolètes
* `RATE_LIMITED` ne fait pas partie du contrat canonique `v1`; utiliser `TOO_MANY_ATTEMPTS` ou `SLOW_DOWN` selon le cas

## 5) Règle Validation (`400` vs `422`)

* `400 VALIDATION_FAILED` : paramètres URL/query/header invalides (enum invalide, date-heure invalide, format d'identifiant invalide)
* `422 VALIDATION_FAILED` : body JSON correctement parsé mais ne respectant pas le contrat métier attendu
* ce découpage est normatif pour les nouvelles routes; les écarts historiques doivent être alignés progressivement

## 6) Table canonique des codes `v1`

| Code | HTTP | Sens canonique |
| --- | --- | --- |
| `UNAUTHORIZED` | `401` | Auth absente, expirée, invalide ou refresh révoqué |
| `EMAIL_NOT_VERIFIED` | `403` | Compte authentifié mais email non vérifié |
| `FORBIDDEN_SCOPE` | `403` | Scope insuffisant pour l'opération |
| `FORBIDDEN_ACTOR` | `403` | Type d'acteur interdit pour l'opération |
| `USER_NOT_FOUND` | `404` | Utilisateur ciblé introuvable |
| `STATE_CONFLICT` | `409` | Transition métier ou action impossible dans l'état courant |
| `IDEMPOTENCY_CONFLICT` | `409` | Même clé d'idempotence réutilisée avec un body différent |
| `STALE_LOCK_TOKEN` | `409` | Couple `lock_token` + `fencing_token` obsolète |
| `NAME_COLLISION_EXHAUSTED` | `409` | Résolution de collision de nom épuisée |
| `PURGED` | `410` | Ressource purgée de manière terminale |
| `VALIDATION_FAILED` | `400` ou `422` | Paramètres invalides (`400`) ou body métier invalide (`422`) |
| `INVALID_TOKEN` | `400` | Token fonctionnel ou de vérification mal formé ou invalide pour l'endpoint |
| `LOCK_REQUIRED` | `423` | Lock requis absent |
| `LOCK_INVALID` | `423` | Lock présent mais invalide pour l'opération |
| `TOO_MANY_ATTEMPTS` | `429` | Anti-abus / quota de tentatives atteint |
| `SLOW_DOWN` | `429` | Polling trop fréquent; le client doit ralentir |
| `MFA_REQUIRED` | `401` | Second facteur requis avant de poursuivre |
| `INVALID_2FA_CODE` | `400` | Code OTP fourni mais invalide |
| `MFA_ALREADY_ENABLED` | `409` | Activation MFA redondante |
| `MFA_NOT_ENABLED` | `409` | Désactivation/régénération MFA impossible car MFA inactive |
| `INVALID_DEVICE_CODE` | `400` | Code device flow inconnu ou mal formé |
| `EXPIRED_DEVICE_CODE` | `400` | Code device flow expiré |
| `UNSUPPORTED_FEATURE_FLAGS_CONTRACT_VERSION` | `426` | Version de contrat de feature flags non supportée |
| `TEMPORARY_UNAVAILABLE` | `503` | Dépendance ou service temporairement indisponible |
| `PRECONDITION_REQUIRED` | `428` | Précondition HTTP obligatoire manquante (`If-Match`) |
| `PRECONDITION_FAILED` | `412` | Précondition HTTP fournie mais périmée ou non satisfaite |

## Références associées

* [API-CONTRACTS.md](API-CONTRACTS.md)
* [openapi/v1.yaml](openapi/v1.yaml)
