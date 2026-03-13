# Readiness Checklist

Checklist fonctionnelle de disponibilite avant mise en service et apres changement infra.

Statut:

* non normatif
* alignee sur `GET /ops/readiness`

## 1) Objectif

Verifier que l'instance Retaia est operable avant:

* une release
* une migration infra
* une reprise apres incident

## 2) Verifications minimales

1. base de donnees disponible
2. stockage ingest disponible et inscriptible
3. migrations appliquees
4. observabilite et alerting actifs
5. prerequis securite runtime actifs

## 3) Checklist

### Base de donnees

* connectivite validee
* plan backup/rollback valide

### Ingest / stockage

* watch path disponible
* stockage writable sur les repertoires critiques
* pipeline ingest actif

### Observabilite

* remontes d'erreurs actives
* alerting conflits/locks branche
* mecanisme de recovery stale locks planifie

### Securite

* headers de securite actifs
* contraintes de transport/sessions conformes a l'environnement

### Validation finale

* readiness `ok` ou `degraded` sous auto-reparation bornee acceptable
* aucun check critique en echec hors fenetre de self-healing autorisee

## References associees

* [../api/API-CONTRACTS.md](../api/API-CONTRACTS.md)
* [../api/OBSERVABILITY-CONTRACT.md](../api/OBSERVABILITY-CONTRACT.md)
* [../policies/SECURITY-BASELINE.md](../policies/SECURITY-BASELINE.md)
