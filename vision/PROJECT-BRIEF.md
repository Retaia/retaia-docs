# PROJECT BRIEF — Retaia

## Résumé du projet

Retaia est un système **multi-apps local-first** de gestion de médiathèque de production (vidéo, photo, audio), conçu autour d’un **Core comme source de vérité métier** et d’un **NAS comme support de stockage**, avec du **processing distribué via des agents**.

Le découpage produit suit une logique de **multi-apps à responsabilités séparées**, proche d’une architecture micro-services simplifiée : chaque application a un rôle clair, mais le contrat métier reste centralisé dans Core.

Le projet sépare strictement plusieurs applications spécialisées :

* la **gestion, l’inventaire, les décisions et les déplacements** (orchestrés par Retaia Core, appliqués sur le NAS)
* le **processing lourd** (réalisé en arrière-plan par les agents)
* la **review humaine**, effectuée via une UI web fluide reposant sur des **proxies/dérivés**
* l’**orchestration outillée**, via un client MCP distinct, dont les fonctions dépendantes de l’AI sont gouvernées par feature flags

L’objectif est de construire un système **fiable, durable et compréhensible dans le temps**, qui respecte la décision humaine et la souveraineté des données.


## Problème à résoudre

Les créateurs accumulent des rushes vidéo, photos et fichiers audio :

* stockés sur NAS
* copiés depuis plusieurs machines
* rarement triés correctement
* difficiles à retrouver
* presque jamais réutilisés

Les solutions existantes sont souvent :

* orientées media server
* trop automatisées (IA décisionnelle)
* opaques sur les déplacements réels des fichiers

Il manque un outil qui respecte :

* les **workflows réels de production**
* la **décision humaine**
* la **traçabilité**
* la **souveraineté des données**


## Objectifs principaux

* Centraliser l’inventaire média dans Core, sur un stockage NAS piloté
* Garantir qu’aucun fichier incomplet n’est jamais traité
* Automatiser le processing courant **sans action manuelle récurrente** via des agents en arrière‑plan, tout en gardant l’enrôlement, l’approval et les actions sensibles sous contrôle humain
* Permettre une **review fluide via proxies** après processing
* Séparer strictement **facts**, **suggestions** et **decisions**
* Permettre un tri humain clair (KEEP / REJECT)
* Permettre la sélection multiple en UI, avec application des déplacements asset par asset côté Core
* Gérer proprement le cycle de vie long terme (réouverture, purge différée)


## Principes non négociables

* **Local-first** : aucune dépendance cloud
* **Core = source de vérité métier et manager**
* **NAS = support de stockage piloté par Core**
* **Agent daemon = calcul uniquement**
* **Décisions humaines uniquement** pour KEEP / REJECT
* **Review via proxies**, jamais via originaux SMB dans le navigateur
* **Aucune action destructive implicite**
* **Batch = concept UI uniquement (sélection multiple)**
* **Purge destructive uniquement sur REJECTED et explicitement configurée**
* **Architecture boring, lisible et durable**


## Composants

### Retaia Core Server

Rôle : cerveau logistique et décisionnel, source de vérité métier.

Responsabilités :

* discovery et inventaire des médias
* attribution d’un UUID stable
* gestion du lifecycle (machine à états)
* gestion des tags (libres + structurés)
* gestion des décisions humaines
* orchestration des jobs de processing
* application des décisions de move par asset (multi-sélection UI possible)
* gestion des sidecars
* exposition des proxies/dérivés
* purge différée avec état `PURGED`
* audit et historique
* API documentée (Swagger)

Technologies :

* Symfony
* Doctrine
* PostgreSQL

Interdictions :

* aucun processing média lourd
* aucune décision automatique


### Retaia Agent

Rôle : moteur de processing en arrière‑plan, avec surfaces `AGENT_UI` en CLI et GUI.

Règle d'architecture :

* le daemon `AGENT_TECHNICAL` reste le moteur technique de processing
* `AGENT_UI` reste la surface humaine de l'agent
* `AGENT_UI` peut à terme devenir aussi riche que `UI_WEB` pour les parcours humains, tout en gardant le pilotage local du daemon
* cette convergence fonctionnelle ne fusionne pas les identités : actions humaines via `USER_INTERACTIVE`, processing via `AGENT_TECHNICAL`
* le compte utilisateur reste unique et multi-device :
  * un nouveau browser ou une nouvelle machine ne crée pas un nouveau compte
  * `UI_WEB` enregistre des devices de confiance via `WebAuthn`
  * `AGENT_UI` partage le même modèle de compte humain, même si son mécanisme interactif évolue par phases

Responsabilités :

* tourner en continu sur desktop/laptop/rpi
* claim des jobs via API
* accéder aux originaux via SMB/NFS
* générer facts et dérivés (proxies, thumbs, waveforms)
* produire des suggestions (tags, champs)

Interdictions :

* ne déplace jamais les fichiers
* ne prend jamais de décision KEEP / REJECT


### UI Web

Rôle : review et management humain.

Caractéristiques :

* servie par Symfony (same‑origin)
* consomme l’API `/api/v1`
* review via proxies/dérivés (lecture fluide)
* aucune dépendance SMB côté navigateur

### AGENT_UI

Rôle : surface humaine locale de l'agent, en CLI et éventuellement en GUI.

Caractéristiques :

* partage le même modèle de compte humain que `UI_WEB`
* pilote le daemon local sans lui transférer implicitement l'identité utilisateur
* peut converger fonctionnellement avec `UI_WEB` pour les parcours humains, sans fusionner avec `AGENT_TECHNICAL`


## Types de médias supportés

* Vidéo (rushes)
* Photo
* Audio (musique, pistes micro externes)

Tous sont modélisés comme **MediaAsset**.


## Lifecycle (vue simplifiée)

* `DISCOVERED → READY → PROCESSING_REVIEW → PROCESSED`
* `PROCESSED → DECISION_PENDING → DECIDED_KEEP / DECIDED_REJECT`
* `DECIDED_KEEP → ARCHIVED` et `DECIDED_REJECT → REJECTED` (apply explicite)
* `REJECTED → PURGED` (optionnel, destructif)


## Résultat attendu

Un outil qui :

* inspire confiance
* automatise sans jamais décider à la place de l’humain
* reste compréhensible après des mois sans usage
* permet de retrouver, trier, réutiliser et nettoyer ses médias sans peur

Si, après un an d’usage réel, l’utilisateur **fait confiance au système** et n’utilise plus de workflows parallèles "par sécurité", alors le projet est réussi.

## Références associées

* [CONCEPTUAL-ARCHITECTURE.md](../architecture/CONCEPTUAL-ARCHITECTURE.md)
* [WORKFLOWS.md](../workflows/WORKFLOWS.md)
* [STATE-MACHINE.md](../state-machine/STATE-MACHINE.md)
* [SUCCESS-CRITERIA.md](../success-criteria/SUCCESS-CRITERIA.md)
