# Data Classification — Handling And Retention

Ce document definit la classification des donnees et les controles minimums associes.

## 1) Classes de donnees

* PUBLIC: donnees publiables sans impact securite
* INTERNAL: donnees internes non sensibles
* SENSITIVE: donnees metier ou personnelles a impact modere
* SECRET: credentials, tokens, cles, secrets de service

## 2) Regles de stockage

* PUBLIC/INTERNAL: stockage standard avec controle d'acces applicatif
* SENSITIVE: chiffrement au repos obligatoire + acces restreint par role
* SECRET: chiffrement fort + acces minimal + jamais en clair dans logs

## 3) Regles de transport

* toutes classes: TLS obligatoire
* SECRET: transport limite aux endpoints strictement necessaires
* SECRET: interdiction de propagation dans URL/query string

## 4) Logging et observabilite

* PUBLIC/INTERNAL: loggable selon besoin operationnel
* SENSITIVE: logging minimise et redige
* SECRET: jamais loggue en clair
* traces erreurs ne DOIVENT jamais exposer secrets/tokens/cles

## 5) Retention et purge

* retention definie par classe et justification legale/metier
* SENSITIVE/SECRET: retention la plus courte compatible obligations
* backups chiffrés obligatoires pour SENSITIVE/SECRET
* purge verifiable et auditable sur donnees expirees

## 6) Access control

* acces base sur role + principe du moindre privilege
* separation des environnements (dev/stage/prod)
* donnees prod reelles interdites en environnements non prod sans anonymisation

## 7) Tests obligatoires

* echantillonnage logs: zero occurrence de valeurs SECRET en clair
* verification ACL: acces refuse sans role autorise
* verification retention: donnees expirees purgees selon politique
* verification backup: backups SENSITIVE/SECRET chiffrés

## References associees

* [SECURITY-BASELINE.md](SECURITY-BASELINE.md)
* [THREAT-MODEL.md](THREAT-MODEL.md)
* [ERROR-MODEL.md](../api/ERROR-MODEL.md)
