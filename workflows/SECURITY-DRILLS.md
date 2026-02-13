# Security Drills Workflow

Ce document definit les exercices securite periodiques obligatoires.

## 1) Frequence

* exercice P0: mensuel
* exercice complet multi-scenario: trimestriel
* post-incident: drill de verification sous 30 jours

## 2) Scenarios minimaux

* fuite token utilisateur
* compromission `secret_key` AGENT/MCP
* compromission cle de signature JWT/release
* exfiltration backup
* tentative brute force auth massive

## 3) Execution

* simulation en environnement dedie
* journal de timeline complet (detection, containment, recovery)
* roles assignes: IC, SecOps, Core owner, Client owner

## 4) Mesures obligatoires

* MTTD
* MTTR containment
* temps de rotation secret/cle
* taux d'echecs de redaction logs

## 5) Criteres de reussite

* containment dans SLO defini
* aucun secret en clair dans artefacts d'exercice
* actions runbook executees sans etape manquante
* postmortem et actions correctives publies

## 6) Livrables

* rapport drill standardise
* liste d'actions correctives priorisees
* mise a jour des politiques/specs si gap detecte

## References associees

* [INCIDENT-RESPONSE.md](../policies/INCIDENT-RESPONSE.md)
* [SECURITY-CHAOS-PLAN.md](../tests/SECURITY-CHAOS-PLAN.md)
* [SECURITY-BASELINE.md](../policies/SECURITY-BASELINE.md)
