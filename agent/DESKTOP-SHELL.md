# Agent Desktop Shell

Ce document decrit la surface GUI de `AGENT_UI`.

Statut:

* non normatif
* complete `workflows/AGENT-PROTOCOL.md`

## 1) Objectif

Definir le comportement fonctionnel du tray/menu systeme et de la fenetre de controle.

## 2) Tray / menu systeme

Actions minimales:

* ouvrir la fenetre
* ouvrir le statut
* ouvrir les preferences
* start/stop daemon
* refresh statut daemon
* quitter

## 3) Fenetre de statut / control center

Le shell desktop doit permettre:

* consultation du job courant
* affichage progression / etape / identifiants utiles
* actions de controle daemon
* acces rapide aux preferences
* acces au diagnostic/bug report

## 4) Regles de comportement

* fermer la fenetre ne doit pas necessairement quitter le tray
* le shell desktop ne doit pas executer un runtime parallele
* les controles GUI doivent refleter l'etat reel du daemon

## References associees

* [DAEMON-OPERATIONS.md](DAEMON-OPERATIONS.md)
* [NOTIFICATIONS-UX.md](NOTIFICATIONS-UX.md)
