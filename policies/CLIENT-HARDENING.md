# Client Hardening — UI_WEB / AGENT_UI / MCP

Ce document definit les exigences de durcissement des clients.

## 1) Principes

* moindre privilege OS et reseau
* stockage secret exclusivement via store OS
* zero secret en logs
* update client signee et verifiee

## 2) UI_WEB

* desactiver debug tooling en production
* CSP stricte pour contenu web embarque (si applicable)
* token non exportable/non affichable
* isolation claire entre UI state et secret store

## 3) AGENT_UI (CLI/GUI)

* mode headless Linux supporte sans composants GUI
* parité fonctionnelle obligatoire entre surfaces CLI et GUI
* permissions filesystem minimales
* service account dedie recommande
* crash dump sans secret

## 4) MCP

* execution en contexte least-privilege
* endpoints autorises explicitement (allowlist)
* refus de commandes hors spec/capabilities
* API key stockee via store OS, jamais en clair dans logs/config exportee

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
