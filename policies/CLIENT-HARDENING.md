# Client Hardening — UI_RUST / AGENT / MCP

Ce document definit les exigences de durcissement des clients.

## 1) Principes

* moindre privilege OS et reseau
* stockage secret exclusivement via store OS
* zero secret en logs
* update client signee et verifiee

## 2) UI_RUST

* desactiver debug tooling en production
* CSP stricte pour contenu web embarque (si applicable)
* token non exportable/non affichable
* isolation claire entre UI state et secret store

## 3) AGENT (CLI/GUI)

* mode headless Linux supporte sans composants GUI
* permissions filesystem minimales
* service account dedie recommande
* crash dump sans secret

## 4) MCP

* execution en contexte least-privilege
* endpoints autorises explicitement (allowlist)
* refus de commandes hors spec/capabilities

## 5) Update et distribution

* mises a jour signees obligatoires
* verification de signature avant installation
* rollback securise en cas d'echec verification

## 6) Tests obligatoires

* token/secret absent des logs clients
* verification store OS active sur macOS/Windows/Linux
* refus d'update non signee
* hardening non-regressif sur build release

## References associees

* [SECURITY-BASELINE.md](SECURITY-BASELINE.md)
* [RELEASE-SIGNING.md](RELEASE-SIGNING.md)
* [AGENT-PROTOCOL.md](../workflows/AGENT-PROTOCOL.md)
