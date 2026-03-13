# Agent Daemon Operations

Ce document cadre le mode daemon du client agent.

Statut:

* non normatif
* complete `workflows/AGENT-PROTOCOL.md`

## 1) Objectif

Le client agent doit pouvoir tourner en arriere-plan avec un daemon unique, pilotable depuis CLI ou GUI.

## 2) Regles fonctionnelles

* une seule instance de daemon partagee
* aucun runtime parallele CLI vs GUI
* le daemon est l'unique moteur d'execution runtime
* CLI et GUI sont des surfaces de controle, d'observabilite et de diagnostic

## 3) Lifecycle attendu

Capacites minimales:

* installer le daemon
* demarrer
* arreter
* lire le statut
* desinstaller

Regles:

* l'autostart au boot doit etre supporte
* le mode sans GUI doit rester de premier rang
* le pilotage CLI et GUI doit refléter le meme etat daemon

## 4) Observabilite operateur

Le daemon doit publier:

* un snapshot runtime courant
* un historique de debug de plus long terme
* un rapport de diagnostic exportable/copiable

Le minimum visible cote operateur:

* etat daemon (`running|paused|stopped|degraded`)
* job courant
* dernier job observe
* cause visible d'un blocage auth/connectivite si connue

## References associees

* [CONFIGURATION-UX.md](CONFIGURATION-UX.md)
* [DESKTOP-SHELL.md](DESKTOP-SHELL.md)
* [NOTIFICATIONS-UX.md](NOTIFICATIONS-UX.md)
* [../workflows/AGENT-PROTOCOL.md](../workflows/AGENT-PROTOCOL.md)
