# Security Chaos Plan — Leak Resilience

Ce document definit les tests chaos securite pour verifier qu'une fuite reste de faible valeur pour un attaquant.

## 1) Objectif

Valider les invariants "assume breach":

* token vole inutilisable ou de courte fenetre
* secret compromis rotatable rapidement
* fuite logs/backups sans secret exploitable

## 2) Scenarios obligatoires (P0)

* token utilisateur vole:
  * tentative reuse apres revoke -> refus
  * tentative reuse apres expiration -> refus
* token technique vole:
  * rotation secret client -> token invalide immediatement
* `secret_key` technique compromise:
  * rotate-secret + mint ancien secret -> `401 UNAUTHORIZED`
* brute force login/device flow:
  * rate-limit et backoff effectifs (`429` normatif)
* tentative elevation scope:
  * scope hors matrice -> `403 FORBIDDEN_SCOPE`

## 3) Scenarios recommends (P1)

* compromission cle JWT simulee -> emergency rotation sans indisponibilite majeure
* replay de requetes mutatrices avec vieille idempotency key -> resultat conforme
* fuite partielle DB anonymisee -> absence de secret clair exploitable

## 4) Metriques de succes

* MTTD incident securite (objectif cible)
* MTTR containment token/secret (objectif cible)
* taux de redaction logs (objectif: 100% secrets rediges)
* temps de rotation secret/cle jusqu'a effet global

## 5) Preconditions

* environnement de test dedie
* jeux de donnees non production
* hooks d'audit actifs
* scenarios rejouables automatises (CI ou nightly)

## 6) Gates de release

Release bloquee si un scenario P0 echoue.

## References associees

* [TEST-PLAN.md](TEST-PLAN.md)
* [SECURITY-BASELINE.md](../policies/SECURITY-BASELINE.md)
* [THREAT-MODEL.md](../policies/THREAT-MODEL.md)
* [INCIDENT-RESPONSE.md](../policies/INCIDENT-RESPONSE.md)
