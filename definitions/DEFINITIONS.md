# DEFINITIONS — Retaia Core + Retaia Agent

Ce document définit les **termes normatifs** utilisés dans le projet Retaia Core + Retaia Agent.

Ces définitions **priment sur tout usage courant** ou interprétation implicite.


## MediaAsset

Un **MediaAsset** est l’unité fondamentale du système.

Il représente un **groupe logique de fichiers** :

* un fichier principal (vidéo, photo ou audio)
* éventuellement des **sidecars** associés

Un MediaAsset possède :

* un **UUID stable** (identité logique)
* un **media_type** (`VIDEO`, `PHOTO`, `AUDIO`)
* un **path courant mutable**
* un **état de lifecycle** défini par la machine à états

Un MediaAsset n’est jamais dupliqué par projet.


## UUID

Le **UUID** est l’identité logique stable d’un MediaAsset.

* Il est attribué lors de la première découverte.
* Il ne change jamais, même si le fichier est déplacé, renommé ou reprocessé.
* Toute interaction API référence un MediaAsset par son UUID.

Le UUID n’est pas un hash de contenu et n’implique aucune lecture lourde.


## Path

Le **path** est l’emplacement logique courant du fichier principal dans un storage donné.

* Le path est **mutable**.
* Il change lors des batch moves.
* Tous les changements de path sont historisés.
* Le path transporté par API est **relatif** (jamais absolu hôte/NAS/conteneur).

Le path n’est jamais une identité.


## Storage ID

Le **storage_id** identifie un storage logique côté Core (ex: NAS principal, volume secondaire).

* Il est stable et déterministe côté serveur.
* Il ne transporte jamais un chemin absolu hôte.
* Il permet à l'agent de résoudre un path relatif via son mapping local `storage_mounts`.


## Relative Path

Un **relative_path** est un chemin relatif à la racine d’un `storage_id`.

* ne DOIT PAS être absolu
* ne DOIT PAS contenir de traversée (`..`)
* doit rester transportable entre environnements (hôte, conteneur, OS)


## Sidecar

Un **sidecar** est un fichier associé à un MediaAsset.

Exemples :

* `.SRT`, `.LRF` pour des vidéos (base DJI Air 3)
* `.LRV`, `.THM` en legacy uniquement si politique locale explicite
* `.XMP` pour des photos
* aucun sidecar audio en v1 (base actuelle)

Les sidecars :

* sont découverts par règles déterministes
* font partie du MediaAsset
* sont déplacés, renommés et supprimés avec le fichier principal


## Derived (Dérivé)

Un **Derived** est un fichier généré à partir d’un MediaAsset, destiné à la review ou à l’enrichissement.

Exemples :

* proxy vidéo
* proxy audio
* thumbnail
* waveform

Caractéristiques :

* stocké hors de l’arborescence des originaux
* non utilisé comme source de vérité
* recréable à tout moment


## Proxies

Un **proxy** est un type de Derived optimisé pour la lecture via l’UI.

* requis pour atteindre l’état `PROCESSED` (profil dépendant du type de média)
* utilisé exclusivement pour la review (UI)
* généré par Retaia Agent

Les proxies ne remplacent jamais les originaux.


## RUSHES_DB

`RUSHES_DB` désigne le **système logique** de gestion des médias sur le NAS.

Il inclut :

* originaux + sidecars
* dérivés sous `RUSHES_DB/.derived/{uuid}/...`
* règles de lifecycle et de décision

Ce n’est pas un simple dossier.


## INBOX

`INBOX` est l’état et l’emplacement des médias nouvellement découverts.

* aucune décision humaine prise
* aucun move automatique
* processing autorisé


## ARCHIVE

`ARCHIVE` est l’état et l’emplacement des médias validés (KEEP).

* assets réutilisables
* organisation stable


## REJECTS

`REJECTS` est l’état et l’emplacement des médias refusés (REJECT).

* assets non retenus
* éligibles à purge différée


## PURGED

`PURGED` est un **état terminal**.

Il indique qu’un MediaAsset a été supprimé de manière définitive.

Garanties :

* originaux supprimés
* sidecars supprimés
* dérivés supprimés (`RUSHES_DB/.derived/{uuid}`)
* audit minimal conservé en base


## DISCOVERED

État initial d’un MediaAsset.

* fichier détecté
* stabilité non garantie


## READY

État indiquant qu’un MediaAsset est stable et éligible au processing.

Conditions :

* stabilité confirmée (scans + mtime)


## PROCESSING_REVIEW

État indiquant qu’un agent Retaia Agent traite l’asset pour la review.

* facts
* thumbs
* proxies


## PROCESSED

État indiquant que le traitement nécessaire à la review est terminé.

Garanties :

* proxies disponibles selon le `processing_profile` (incluant PHOTO/VIDEO/AUDIO)
* thumbs disponibles
* facts stockés


## DECISION_PENDING

État indiquant qu’un MediaAsset attend une décision humaine.

Aucun move n’est autorisé dans cet état.


## DECIDED_KEEP / DECIDED_REJECT

États représentant une décision humaine explicite.

* KEEP : conservation
* REJECT : refus

Ces états ne déclenchent aucun move immédiat.


## MOVE_QUEUED

État indiquant qu’un MediaAsset est planifié pour un batch move.


## ARCHIVED

État indiquant qu’un MediaAsset a été déplacé vers ARCHIVE.

* état stable
* réouvrable


## REJECTED

État indiquant qu’un MediaAsset a été déplacé vers REJECTS.

* état stable
* réouvrable
* éligible à purge


## Retaia Agent

Un **Retaia Agent** est un client de processing en arrière-plan.

* tourne sur desktop / laptop / raspberry-pi
* claim des jobs
* génère facts et dérivés
* ne prend jamais de décision


## Processing Review

Le **processing review** est le traitement minimal requis pour permettre la review UI.

Il inclut :

* extraction des facts
* génération des proxies
* génération des thumbs / waveforms


## Transcription

La **transcription** est un job secondaire optionnel.

* basé sur l’audio
* produit du texte
* utilisé pour recherche et suggestions


## Suggestions

Les **suggestions** sont des propositions automatiques.

Exemples :

* tags suggérés
* valeurs suggérées de champs structurés

Règles :

* jamais appliquées automatiquement
* toujours validées par un humain


## Batch Move

Un **Batch Move** est une action explicite appliquant plusieurs décisions en une fois.

* précédé d’un dry-run
* journalisé
* seul mécanisme autorisé pour déplacer des originaux


## Source de vérité

La **source de vérité** est Retaia Core Server.

* décide des états
* orchestre les moves
* garantit la cohérence


## Invariants terminologiques

* UUID ≠ Path
* PROCESSED ≠ DECIDED
* ARCHIVED ≠ BACKUP
* REJECTED ≠ DELETION
* PURGED = DELETION

Toute implémentation doit respecter strictement ces distinctions.

## Références associées

* [STATE-MACHINE.md](../state-machine/STATE-MACHINE.md)
* [JOB-TYPES.md](JOB-TYPES.md)
* [PROCESSING-PROFILES.md](PROCESSING-PROFILES.md)
* [SIDECAR-RULES.md](SIDECAR-RULES.md)
* [WORKFLOWS.md](../workflows/WORKFLOWS.md)
