# Rollout Plan — HTTP Status Uniformity (v1 runtime)

Objectif:

* deployer l'alignement HTTP sans casser les clients existants UI_RUST, AGENT, MCP

## 1) Compat temporaire Core (feature flag)

Flag runtime recommande:

* `features.auth.device_flow.compat_legacy_http`

Regles:

* `true` (phase compat): autorise une couche de compatibilite serveur strictement temporaire
* `false` (phase cible): comportement final status-driven uniquement
* ce flag DOIT etre retire apres cutover complet (pas de legacy permanent)

## 2) Observabilite obligatoire

Metriques minimales:

* volume de `POST /auth/clients/device/poll` par `status` (`PENDING`, `APPROVED`, `DENIED`, `EXPIRED`)
* taux `400 INVALID_DEVICE_CODE`
* taux `429 SLOW_DOWN|TOO_MANY_ATTEMPTS`
* nombre de clients encore dependants d'un comportement legacy (si detecte)
* volume de rejets `POST /auth/clients/token` avec `403 FORBIDDEN_ACTOR` pour `client_kind=UI_RUST`

Logs/audit:

* journaliser le mode de compat actif/inactif
* tracer les transitions de phase (compat -> cutover -> retrait)

## 3) Cutover

Prerequis:

* tickets core/ui_rust/agent_mcp livres
* gates de non-regression verts (OpenAPI, integration auth/device, compat client)

Execution:

1. activer instrumentation + dashboard rollout
2. deployer Core en mode compat (`compat_legacy_http=true`)
3. deployer UI_RUST, AGENT, MCP compatibles status-driven
4. verifier baisse a zero des signaux legacy
5. basculer `compat_legacy_http=false`

## 4) Retrait compat (obligatoire)

Conditions de sortie:

* aucune dependance legacy observee sur une fenetre stabilisee
* aucun incident auth/device actif

Actions:

* supprimer code de compat legacy cote Core
* supprimer le flag `features.auth.device_flow.compat_legacy_http`
* conserver uniquement le comportement cible documente en v1

## 5) Rollback

* rollback court-terme autorise en reactivate `compat_legacy_http=true`
* rollback version applicative possible UI_RUST/AGENT/MCP si incident critique
* toute activation de rollback DOIT etre auditee et post-analysee
