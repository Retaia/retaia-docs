# PROJECT BRIEF — Retaia Core + Retaia Agent

## Résumé du projet

Retaia Core + Retaia Agent est un système **local-first** de gestion de médiathèque de production (vidéo, photo, audio), conçu pour fonctionner autour d’un **NAS comme centre de vérité**, avec du **processing distribué via des agents**.

Le projet sépare strictement :

* la **gestion, l’inventaire, les décisions et les déplacements** (centralisés sur le NAS via Retaia Core)
* le **processing lourd** (réalisé en arrière-plan par des agents Retaia Agent sur desktop/laptop/raspberry‑pi)
* la **review humaine**, effectuée via une UI web fluide reposant sur des **proxies/dérivés**

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

* Centraliser l’inventaire média sur le NAS
* Garantir qu’aucun fichier incomplet n’est jamais traité
* Automatiser le processing **sans action manuelle** via des agents en arrière‑plan
* Permettre une **review fluide via proxies** après processing
* Séparer strictement **facts**, **suggestions** et **decisions**
* Permettre un tri humain clair (KEEP / REJECT)
* Appliquer les déplacements **en batch** pour éviter les erreurs
* Gérer proprement le cycle de vie long terme (réouverture, purge différée)


## Principes non négociables

* **Local-first** : aucune dépendance cloud
* **NAS = source de vérité logistique**
* **Agents = compute only**
* **Décisions humaines uniquement** pour KEEP / REJECT
* **Review via proxies**, jamais via originaux SMB dans le navigateur
* **Aucune action destructive implicite**
* **Batch move obligatoire**
* **Purge destructive uniquement sur REJECTED et explicitement configurée**
* **Architecture boring, lisible et durable**


## Composants

### Retaia Core Server (NAS)

Rôle : cerveau logistique et décisionnel.

Responsabilités :

* discovery et inventaire des médias
* attribution d’un UUID stable
* gestion du lifecycle (machine à états)
* gestion des tags (libres + structurés)
* gestion des décisions humaines
* orchestration des jobs de processing
* gestion des batch moves
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


### Retaia Agent (clients)

Rôle : moteur de processing en arrière‑plan.

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


## Types de médias supportés

* Vidéo (rushes)
* Photo
* Audio (musique, pistes micro externes)

Tous sont modélisés comme **MediaAsset**.


## Lifecycle (vue simplifiée)

* `DISCOVERED → READY → PROCESSING_REVIEW → PROCESSED`
* `PROCESSED → DECISION_PENDING → DECIDED_KEEP / DECIDED_REJECT`
* `DECIDED_* → MOVE_QUEUED → ARCHIVED / REJECTED`
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
