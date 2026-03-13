# Agent Configuration UX

Ce document decrit le cadrage fonctionnel de configuration pour `retaia-agent`.

Statut:

* non normatif
* complete `workflows/AGENT-PROTOCOL.md`

## 1) Objectif

Garantir une configuration coherente de `AGENT_UI` entre GUI et CLI, y compris en environnement headless.

## 2) Invariants

* `AGENT_UI` en GUI et CLI partage le meme contrat de configuration
* les memes champs doivent etre disponibles dans les deux surfaces
* la validation doit etre identique entre GUI et CLI
* une configuration invalide ne doit pas etre consideree comme appliquee

## 3) Champs minimum

* URL Core
* URL provider local/AI si applicable
* mode d'auth
* identifiants techniques si le mode l'exige
* parametres runtime
* `storage_mounts`

## 4) Regles UX

* validation explicite des champs
* message clair sur sauvegarde valide
* message clair sur configuration invalide
* la configuration doit rester pilotable sans GUI

## 5) Headless / CLI-only

Le mode CLI-only doit permettre au minimum:

* initialisation
* affichage de la config effective
* validation
* mise a jour
* controle du daemon

## References associees

* [DAEMON-OPERATIONS.md](DAEMON-OPERATIONS.md)
* [../workflows/AGENT-PROTOCOL.md](../workflows/AGENT-PROTOCOL.md)
* [../architecture/DEPLOYMENT-TOPOLOGY.md](../architecture/DEPLOYMENT-TOPOLOGY.md)
