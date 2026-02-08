# CONCEPTUAL ARCHITECTURE — RushCatalog + RushIndexer (v2, proxy-first)

## Vision

Le système est conçu selon un principe **local-first, humain-centré et durable** :

* le **NAS est le centre de vérité logistique** (inventaire, états, décisions, déplacements)
* les **machines clientes sont le centre de calcul** (processing lourd via agents)
* les **décisions éditoriales sont toujours humaines**
* la review se fait via **proxies/dérivés** pour une UI fluide

L’architecture vise la robustesse à long terme, la lisibilité après des mois d’inactivité, et l’évitement des surprises destructrices.


## Séparation stricte des responsabilités

### NAS — RushCatalog Server

RushCatalog, hébergé sur le NAS, agit comme **cerveau logistique et décisionnel**.

Responsabilités :

* discovery/inventaire des médias (polling)
* attribution d’un **UUID stable**
* gestion du **lifecycle** des assets (machine à états)
* gestion des **tags** (libres + structurés via custom fields)
* gestion des **décisions humaines** (KEEP/REJECT)
* orchestration d’une **queue de jobs** pour agents (locks + TTL)
* gestion des **batch moves** (INBOX → ARCHIVE/REJECTS)
* gestion des **sidecars** (association + move groupé)
* stockage et exposition des **références de dérivés**
* purge différée des REJECTED (optionnelle) avec état terminal `PURGED`
* API documentée (Swagger UI)
* événements métier internes (pluggables)

Interdictions explicites :

* aucun traitement média lourd (ffmpeg, transcription, IA) sur le NAS
* aucune décision automatique KEEP/REJECT
* aucun move automatique “au fil de l’eau”

Technologies :

* Symfony
* Doctrine ORM
* PostgreSQL
* EventDispatcher Symfony


### Machines clientes — RushIndexer Agent(s)

RushIndexer tourne en **agent background** sur desktop/laptop/raspberry-pi.

Responsabilités :

* claim de jobs via API (lock + TTL)
* accès aux originaux via **SMB/NFS** (NAS monté)
* génération des **facts** et **dérivés**
* soumission des résultats au serveur

Interdictions explicites :

* ne déplace jamais les fichiers
* ne renomme jamais les fichiers
* ne décide jamais KEEP/REJECT

L’agent peut produire des **suggestions** (tags/fields), jamais des décisions.


### UI (livrée par Symfony)

L’interface utilisateur est servie en **same-origin** par Symfony (Option A).

Caractéristiques :

* consomme l’API `/api/v1`
* réalise la review via **proxies/dérivés** (lecture web fluide)
* ne dépend pas de SMB/NFS côté navigateur

L’UI est un client parmi d’autres : elle n’a pas de privilèges “cachés”.


## Types de médias

Le système gère un concept unique : **MediaAsset**.

Types supportés :

* VIDEO (rushes)
* PHOTO
* AUDIO (musique, pistes micro externes)

Un MediaAsset représente un **groupe** : fichier principal + sidecars.


## Identité vs emplacement

* **UUID** : identité logique stable, attribuée à la première découverte
* **Path** : attribut mutable (change lors des batch moves)

Tous les échanges API utilisent le **UUID**.


## Stockage sur NAS

### Originaux

* stockés dans INBOX/ARCHIVE/REJECTS
* déplacés uniquement via batch move

### Dérivés (Derived)

* stockés sous : `RUSHES_DB/.derived/{uuid}/...`
* incluent :

    * proxies vidéo/audio
    * thumbnails
    * waveforms
    * (optionnel) autres artefacts recréables

Les dérivés ne sont jamais la source de vérité et sont recréables.


## Discovery & stabilité

Le discovery est géré par RushCatalog (NAS) en polling.

Un fichier devient `READY` uniquement si :

* stable sur au moins 2 scans consécutifs (taille identique)
* `mtime` plus ancien que 5–6 minutes


## Lifecycle (vue d’ensemble)

États principaux (normatifs) :

* `DISCOVERED → READY → PROCESSING_REVIEW → PROCESSED → DECISION_PENDING`
* `DECISION_PENDING → DECIDED_KEEP/DECIDED_REJECT → MOVE_QUEUED → ARCHIVED/REJECTED`
* `REJECTED → PURGED` (optionnel, destructif, politique explicitement activée)

Invariants :

* `PROCESSED` exige des proxies pour VIDEO/AUDIO
* aucune décision automatique
* aucun move hors batch


## Processing pipeline

### Processing review (bloquant pour la review)

Objectif : rendre la review possible.

Produit :

* facts (DB)
* thumbs (derived)
* proxies VIDEO/AUDIO (derived)
* waveform AUDIO (derived)

### Jobs sec
