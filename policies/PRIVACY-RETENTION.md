# Privacy And Retention Policy

Ce document definit les exigences minimales de protection des donnees personnelles et de retention.

## 1) Principes

* minimisation des donnees
* finalite explicite
* retention bornee
* purge verifiable

## 2) Retention par categorie (baseline)

* journaux applicatifs: 30-90 jours selon criticite
* audits securite: minimum 90 jours (ou obligation legale)
* donnees utilisateur actives: selon finalite metier documentee
* donnees supprimees: suppression logique immediate + purge physique planifiee

## 3) Droits utilisateur

* acces aux donnees personnelles
* correction des donnees incorrectes
* effacement selon contraintes legales applicables
* export sur format interoperable si requis

## 4) Contraintes techniques

* tags classification obligatoires pour donnees SENSITIVE/SECRET
* pseudonymisation/anonymisation pour environnements non prod
* pseudonymisation canonique des identifiants exportes hors frontiere de confiance :
  * `HMAC-SHA-256(secret_scope, actor_id)`
  * troncature aux `16` premiers octets hexadécimaux lowercase
  * prefixe obligatoire `psd_`
  * `secret_scope` distinct par environnement
* interdiction de copier des dumps prod sans redaction controlee

## 5) Tests obligatoires

* verification retention automatisee par categorie
* verification purge effective apres echeance
* verification workflow d'effacement utilisateur
* verification non-regression anonymisation non-prod

## References associees

* [DATA-CLASSIFICATION.md](DATA-CLASSIFICATION.md)
* [SECURITY-BASELINE.md](SECURITY-BASELINE.md)
* [INCIDENT-RESPONSE.md](INCIDENT-RESPONSE.md)
