# Release Gates

Document normatif unique des gates de release pour `retaia-docs`.

Statut:

* normatif
* opposable pour toute release `v1.0.0`

## 1) Objectif

Definir ce qui bloque formellement une release de specification, distinctement :

* des runbooks ops
* des checklists de readiness
* des details d'implementation des repos consommateurs

## 2) Gate de release obligatoire

Une release est conforme seulement si tous les points suivants sont vrais :

1. le contrat OpenAPI executoire `api/openapi/v1.yaml` est valide
2. `bash scripts/check-contract-drift.sh` passe
3. les documents normatifs impactes ont ete mis a jour ensemble
4. le `TEST-PLAN` reste coherent avec les contrats normatifs modifies
5. les gates Secure SDLC versionnees dans ce repo sont vertes
6. aucun document normatif ne contredit un autre document normatif sur une surface partagee `Core` / `UI_WEB` / `AGENT`

## 3) Artefacts minimaux attendus

Avant tag/release, le repo DOIT contenir :

* `api/openapi/v1.yaml`
* `contracts/openapi-v1.sha256`
* `api/API-CONTRACTS.md`
* `tests/TEST-PLAN.md`
* les policies/workflows/definitions impactes par le changement

## 4) Preuves minimales

Les preuves minimales attendues pour une release sont :

* sortie verte de `bash scripts/check-contract-drift.sh`
* validation OpenAPI verte sur `api/openapi/v1.yaml`
* CI verte sur les workflows obligatoires du repo
* revue humaine conforme aux exigences Secure SDLC en vigueur

## 5) Distinction normative

Les documents suivants ne remplacent pas cette gate normative :

* `ops/READINESS-CHECKLIST.md`
* `ops/RELEASE-OPERATIONS.md`
* `ops/OBSERVABILITY-TRIAGE.md`
* `ops/AUTH-INCIDENT-RUNBOOK.md`

Ils restent utiles pour l'exploitation, mais ne definissent pas a eux seuls la conformite release.

## 6) Regle de conflit

En cas de conflit :

* `RELEASE-GATES.md` tranche ce qui bloque une release
* les runbooks ops decrivent comment operer
* les repos consommateurs ne peuvent pas redefinir localement une gate partagee implicite
