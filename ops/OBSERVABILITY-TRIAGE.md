# Observability Triage

Runbook fonctionnel de diagnostic des incidents observabilite/jobs/auth.

Statut:

* non normatif
* complete le contrat d'observabilite

## 1) Objectif

Donner une procedure de triage rapide pour:

* incidents API
* conflits de jobs et verrous
* incidents auth
* verification de correlation et de redaction

## 2) Evenements cles

Jobs:

* `jobs.list_claimable`
* `jobs.claim.succeeded`
* `jobs.claim.conflict`
* `jobs.heartbeat.succeeded`
* `jobs.heartbeat.conflict`
* `jobs.submit.succeeded`
* `jobs.submit.conflict`
* `jobs.fail.succeeded`
* `jobs.fail.conflict`

Auth:

* `auth.login.failure`
* `auth.login.throttled`
* `auth.password_reset.*`
* `auth.email_verification.*`

## 3) Champs a verifier

* `request_id`
* `correlation_id`
* `job_id`
* `asset_uuid`
* `agent_id`
* `job_type`
* `error_code`
* `outcome`

## 4) Procedure de triage

1. verifier l'etat de disponibilite general (`health`, `readiness`)
2. corriger les erreurs API avec les evenements structures sur la meme fenetre
3. pour un conflit job:
   * regrouper par `job_id`
   * verifier `agent_id`, lease, heartbeat et evenement de claim precedent
4. pour un conflit lock:
   * verifier le type de lock, sa duree de vie et l'event de release attendu
5. pour un incident auth:
   * verifier les spikes de throttling et les refus `authz.denied`
6. verifier que les logs restent rediges et correlables

## 5) Escalade

Escalader si:

* perte de correlation (`request_id`/`correlation_id`) sur evenements critiques
* absence de redaction de secrets
* hausse anormale et persistante des conflits jobs/locks
* readiness degrade ou down sans retour dans la fenetre attendue

## References associees

* [../api/OBSERVABILITY-CONTRACT.md](../api/OBSERVABILITY-CONTRACT.md)
* [../api/API-CONTRACTS.md](../api/API-CONTRACTS.md)
* [../policies/FEATURE-GOVERNANCE-OBSERVABILITY.md](../policies/FEATURE-GOVERNANCE-OBSERVABILITY.md)
* [../policies/INCIDENT-RESPONSE.md](../policies/INCIDENT-RESPONSE.md)
