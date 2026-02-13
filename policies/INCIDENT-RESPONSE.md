# Incident Response — Security Events

Ce document definit le runbook normatif de reponse aux incidents securite.

## 1) Classes d'incident

* SEV-1: compromission active ou fuite confirmee de secrets/tokens/cles
* SEV-2: tentative plausible avec impact limite/partiel
* SEV-3: anomalie securite sans impact confirme

## 2) Objectifs temporels (SLO)

* detection -> triage initial: <= 15 minutes
* SEV-1 containment initial: <= 60 minutes
* decision rotation/revocation: <= 90 minutes
* communication interne initiale: <= 60 minutes

## 3) Procedure SEV-1 (MUST)

1. ouvrir incident et nommer Incident Commander
2. geler les actions non essentielles sur les systemes impactes
3. contenir: revoke tokens/secrets/cles suspectes
4. activer emergency rotation (cf. `KEY-MANAGEMENT.md`)
5. appliquer regles de blocage temporaires (rate-limit durci, deny-list)
6. conserver les preuves (logs, traces, audit) avec chaine de conservation
7. notifier parties prenantes internes
8. publier update de statut periodique jusqu'a stabilisation

## 4) Scenarios minimaux et actions

* fuite token utilisateur: revoke `jti` et invalider sessions associees
* fuite `secret_key` technique: rotate secret + invalidation tokens client
* fuite cle JWT: emergency rotation + invalidation par `kid`/`jti`
* fuite DB: enclencher plan d'investigation, rotation secrets dependants, verification integrite

## 5) Communication

* canal incident dedie obligatoire
* un seul message officiel de statut par cycle (source unique)
* postmortem obligatoire <= 5 jours ouvres apres cloture

## 6) Post-incident (MUST)

* analyse racine (root cause) documentee
* liste d'actions correctives avec owner et date cible
* mise a jour des specs impactees (`SECURITY-BASELINE`, `THREAT-MODEL`, tests)
* verification d'efficacite des correctifs par tests de non-regression

## 7) Audit et retention

* chaque action critique incident DOIT etre journalisee
* horodatage UTC obligatoire
* retention des artefacts incident selon politique legale/interne

## References associees

* [SECURITY-BASELINE.md](SECURITY-BASELINE.md)
* [KEY-MANAGEMENT.md](KEY-MANAGEMENT.md)
* [THREAT-MODEL.md](THREAT-MODEL.md)
