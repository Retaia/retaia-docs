# Threat Model — Core/UI/Agent/MCP

Ce document formalise le threat model normatif minimal de Retaia.

Objectif: prioriser les risques qui peuvent provoquer une fuite ou une prise de controle et imposer les contremesures obligatoires.

## 1) Actifs critiques

* identites utilisateur et comptes admin
* bearer tokens utilisateur et techniques
* `secret_key` clients `AGENT`/`MCP`
* donnees assets, metadonnees et contenus derives
* traces d'audit et journaux securite
* cles de signature/chiffrement (JWT, KMS)

## 2) Frontieres de confiance

* client `UI_RUST` (interactif humain)
* client `AGENT` (interactif et technique)
* client `MCP` (technique)
* API Core et services internes
* stockage (DB, objet, backups)
* systemes tiers (SMTP, telemetry, CI)

Toute traversee de frontiere DOIT etre authentifiee, autorisee et auditee.

## 3) Menaces prioritaires (P0/P1)

* P0: exfiltration de token/secret via logs, UI, crash reports
* P0: vol de base de donnees (comptes, tokens, secrets)
* P0: elevation de privilege par scope/acteur mal controles
* P0: usurpation client technique (replay secret, token reuse)
* P1: abus brute force sur login, reset password, device flow
* P1: compromission partielle d'une cle de signature/chiffrement

## 4) Controles obligatoires par menace

* exfiltration token/secret -> redaction logs + stockage secret OS + rotation/revocation immediate
* vol DB -> hash Argon2id mots de passe + `secret_key` hashee + chiffrement au repos
* elevation privilege -> deny-by-default + matrice authz endpoint/scope/acteur + tests de non-regression
* usurpation technique -> cardinalite 1 token actif/client + `jti` unique + `exp` court + rotation secrets
* brute force -> rate limit + backoff + codes d'erreur normatifs
* compromission cle -> key rotation procedure + invalidation token compatible `kid`

## 5) Hypotheses et exclusions

* la 2FA est optionnelle au niveau compte utilisateur
* `UI_RUST` applique la 2FA quand active
* `AGENT`/`MCP` technique n'utilisent pas 2FA runtime
* la creation/rotation de secret technique exige validation UI utilisateur (2FA si active)

## 6) Exigences de verification

* chaque menace P0 DOIT etre couverte par au moins un test de `TEST-PLAN.md` ou `SECURITY-CHAOS-PLAN.md`
* toute nouvelle surface (endpoint, client_kind, capability) DOIT ajouter son mapping menace -> controle
* aucune PR securite ne passe sans impact explicite sur ce mapping

## References associees

* [SECURITY-BASELINE.md](SECURITY-BASELINE.md)
* [AUTHZ-MATRIX.md](AUTHZ-MATRIX.md)
* [API-CONTRACTS.md](../api/API-CONTRACTS.md)
* [TEST-PLAN.md](../tests/TEST-PLAN.md)
