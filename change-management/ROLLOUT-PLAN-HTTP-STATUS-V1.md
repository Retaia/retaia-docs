# Rollout Plan — HTTP Status Uniformity (v1 runtime)

Objectif:

* deployer l'alignement HTTP sans casser les clients existants UI_RUST, AGENT, MCP

## 1) Politique pre-publication v1 (sans legacy)

Regles:

* aucun mode legacy n'est autorise avant publication v1
* aucun feature flag de compatibilite legacy ne DOIT etre introduit
* comportement cible status-driven applique directement

## 2) Observabilite obligatoire

Metriques minimales:

* volume de `POST /auth/clients/device/poll` par `status` (`PENDING`, `APPROVED`, `DENIED`, `EXPIRED`)
* taux `400 INVALID_DEVICE_CODE`
* taux `429 SLOW_DOWN|TOO_MANY_ATTEMPTS`
* volume de rejets `POST /auth/clients/token` avec `403 FORBIDDEN_ACTOR` pour `client_kind=UI_RUST`

Logs/audit:

* tracer les transitions de phase (pre-release -> cutover -> post-cutover)

## 3) Cutover

Prerequis:

* tickets core/ui_rust/agent_mcp livres
* gates de non-regression verts (OpenAPI, integration auth/device, compat client)

Execution:

1. activer instrumentation + dashboard rollout
2. deployer Core directement en mode cible status-driven
3. deployer UI_RUST, AGENT, MCP compatibles status-driven
4. verifier stabilite des metriques et absence d'incident auth/device

## 4) Stabilisation post-cutover

Conditions de sortie:

* aucun incident auth/device actif

Actions:

* conserver uniquement le comportement cible documente en v1
* verrouiller les tests de non-regression associes

## 5) Rollback

* rollback version Core/UI_RUST/AGENT/MCP possible si incident critique
* toute activation de rollback DOIT etre auditee et post-analysee
