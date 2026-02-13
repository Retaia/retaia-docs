# Observability Contract — Security Events

Ce document definit le contrat normatif des evenements d'observabilite securite.

Objectif: garantir des logs/audits exploitables sans fuite de secrets.

## 1) Invariants

* format evenement stable et versionne
* horodatage UTC obligatoire
* aucun secret/token/PII sensible en clair
* correlation cross-system via `correlation_id`

## 2) Schema minimal d'evenement

Champs obligatoires:

* `event_name`
* `event_version`
* `timestamp_utc`
* `severity` (`INFO|WARN|ERROR|CRITICAL`)
* `actor_type` (`USER_INTERACTIVE|ADMIN_INTERACTIVE|AGENT_TECHNICAL|CLIENT_TECHNICAL|SYSTEM`)
* `actor_id` (ou `system`)
* `client_id` (si applicable)
* `request_id`
* `correlation_id`
* `outcome` (`SUCCESS|FAILURE|DENY`)
* `error_code` (si applicable, conforme `ErrorResponse.code`)

## 3) Events securite obligatoires

* `auth.login.success`
* `auth.login.failure`
* `auth.logout`
* `auth.2fa.setup`
* `auth.2fa.enable`
* `auth.2fa.disable`
* `auth.client.token.minted`
* `auth.client.token.revoked`
* `auth.client.secret.rotated`
* `auth.device.approved`
* `auth.device.denied`
* `authz.denied`

## 4) Redaction

* champs interdits en clair: `password`, `otp_code`, `secret_key`, `access_token`, `refresh_token`
* valeurs sensibles remplacees par `[REDACTED]`
* emails anonymises en sortie non admin (ex: hash/troncature)

## 5) Retention et acces

* logs securite immutables et horodates
* retention minimale: 90 jours (ou contrainte legale superieure)
* acces lecture limite aux roles autorises

## 6) Tests obligatoires

* validation schema evenement sur echantillon de chaque `event_name` obligatoire
* test redaction: zero secret en clair
* test correlation: `request_id`/`correlation_id` presents sur tous events critiques
* test mapping erreurs: `error_code` appartient au modele normatif

## References associees

* [ERROR-MODEL.md](ERROR-MODEL.md)
* [API-CONTRACTS.md](API-CONTRACTS.md)
* [SECURITY-BASELINE.md](../policies/SECURITY-BASELINE.md)
