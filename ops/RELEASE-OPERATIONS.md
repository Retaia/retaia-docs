# Release Operations

Runbook fonctionnel de preparation, verification post-deploiement et rollback.

Statut:

* non normatif
* cross-project

## 1) Objectif

Donner une procedure globale pour:

* preparer une release
* verifier la disponibilite post-deploiement
* operer les controles de base
* rollbacker proprement si necessaire

## 2) Prerequis release

Avant release:

* contrats et gates verts
* verifications securite et dependances passees
* plan de rollback et artefacts precedents identifies

## 3) Verification post-deploiement

Verifier:

1. disponibilite API
2. readiness operationnelle
3. remontes d'observabilite critiques
4. activite ingest/runtime attendue

## 4) Exploitation quotidienne

Surveiller regulierement:

* conflits jobs/locks
* sante runtime
* canaux d'erreur et alerting
* readiness degrade/down

## 5) Rollback minimal

Rollback si:

* indisponibilite prolongee
* erreurs metier critiques non recuperables
* corruption fonctionnelle constatee

Procedure:

1. redeployer les artefacts precedents stables
2. verifier l'impact des migrations avant rollback DB
3. restaurer la base uniquement si necessaire et valide
4. rejouer la verification post-deploiement

## References associees

* [README.md](README.md)
* [READINESS-CHECKLIST.md](READINESS-CHECKLIST.md)
* [OBSERVABILITY-TRIAGE.md](OBSERVABILITY-TRIAGE.md)
* [../policies/RELEASE-SIGNING.md](../policies/RELEASE-SIGNING.md)
