# Observability Contract — Shared Events

Ce document definit le contrat normatif des evenements d'observabilite partages.

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
* `actor_type` (`USER_INTERACTIVE|ADMIN_INTERACTIVE|AGENT_TECHNICAL|MCP_TECHNICAL|SYSTEM`)
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

## 4) Events operatoires cross-app obligatoires

Ces evenements sont partages entre `Core`, `UI_WEB`, `AGENT` et les outils ops.

* `asset.state.changed`
* `asset.reprocess.requested`
* `asset.reopen.requested`
* `asset.processing_profile.changed`
* `asset.purge.requested`
* `asset.purge.completed`
* `job.claim.succeeded`
* `job.claim.conflict`
* `job.heartbeat.succeeded`
* `job.heartbeat.conflict`
* `job.submit.succeeded`
* `job.submit.conflict`
* `job.fail.recorded`
* `hook.execution.succeeded`
* `hook.execution.failed`
* `feature.contract_version.unsupported`

Champs minimum additionnels selon l'evenement :

* events asset :
  * `asset_uuid`
  * `previous_state?`
  * `new_state?`
  * `processing_profile?`
* events job :
  * `job_id`
  * `job_type`
  * `asset_uuid`
  * `agent_id?`
* events hook :
  * `asset_uuid`
  * `hook_name`
  * `hook_point`
  * `blocking`
  * `event_id`
* events feature contract :
  * `client_kind`
  * `client_feature_flags_contract_version`
  * `accepted_feature_flags_contract_versions`

Severite minimale canonique :

* `asset.state.changed` -> `INFO`
* `asset.reprocess.requested` -> `INFO`
* `asset.reopen.requested` -> `INFO`
* `asset.processing_profile.changed` -> `INFO`
* `asset.purge.requested` -> `WARN`
* `asset.purge.completed` -> `WARN`
* `job.claim.succeeded` -> `INFO`
* `job.claim.conflict` -> `WARN`
* `job.heartbeat.succeeded` -> `INFO`
* `job.heartbeat.conflict` -> `WARN`
* `job.submit.succeeded` -> `INFO`
* `job.submit.conflict` -> `WARN`
* `job.fail.recorded` -> `ERROR`
* `hook.execution.succeeded` -> `INFO`
* `hook.execution.failed` -> `WARN`
* `feature.contract_version.unsupported` -> `WARN`

## 5) Redaction

* champs interdits en clair: `password`, `otp_code`, `secret_key`, `api_key`, `access_token`, `refresh_token`
* valeurs sensibles remplacees par `[REDACTED]`
* emails anonymises en sortie non admin (ex: hash/troncature)

## 6) Retention et acces

* logs securite immutables et horodates
* retention minimale: 90 jours (ou contrainte legale superieure)
* acces lecture limite aux roles autorises

## 7) Tests obligatoires

* validation schema evenement sur echantillon de chaque `event_name` obligatoire
* test redaction: zero secret en clair
* test correlation: `request_id`/`correlation_id` presents sur tous events critiques
* test mapping erreurs: `error_code` appartient au modele normatif
* test taxonomie: chaque event cross-app obligatoire est emissionable avec les champs minimaux attendus

## 8) Presentation UI/Ops

* la presentation visuelle des evenements dans une UI ops ou admin n'est pas normative en `v1`
* si une surface UI expose ces evenements, elle DOIT au minimum preserver sans reinterpretation locale :
  * `event_name`
  * `severity`
  * `timestamp_utc`
  * `outcome`
  * `error_code?`
* aucun ecran ne DOIT inventer une taxonomie alternative aux `event_name` canoniques

## References associees

* [ERROR-MODEL.md](ERROR-MODEL.md)
* [API-CONTRACTS.md](API-CONTRACTS.md)
* [SECURITY-BASELINE.md](../policies/SECURITY-BASELINE.md)
