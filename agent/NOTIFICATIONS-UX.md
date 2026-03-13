# Agent Notifications UX

Ce document decrit les notifications operateur attendues pour `retaia-agent`.

Statut:

* non normatif
* complete `workflows/AGENT-PROTOCOL.md`

## 1) Principes

* les notifications sont emises sur evenement ou transition utile
* pas de repetition en boucle sur un etat stable
* une notification ne doit pas devenir la source de verite du runtime

## 2) Notifications minimales

* nouveau job recu
* tous les jobs termines
* job en echec
* agent deconnecte / reconnexion
* auth expiree / re-auth requise
* configuration sauvegardee
* configuration invalide

## 3) Notifications optionnelles

* mise a jour disponible
* daemon demarre
* daemon arrete
* statut daemon rafraichi

## 4) Regles UX

* deduplication obligatoire sur etat stable
* message court, comprehensible, oriente action
* aucune fuite de secret/token/PII

## References associees

* [DAEMON-OPERATIONS.md](DAEMON-OPERATIONS.md)
* [DESKTOP-SHELL.md](DESKTOP-SHELL.md)
* [../api/OBSERVABILITY-CONTRACT.md](../api/OBSERVABILITY-CONTRACT.md)
