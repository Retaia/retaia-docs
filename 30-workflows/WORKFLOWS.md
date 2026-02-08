# WORKFLOWS — RushCatalog + RushIndexer

Ce document décrit les **workflows canoniques** du système RushCatalog + RushIndexer.

Ils sont **normatifs** : toute implémentation ou évolution future doit les respecter.


## Workflow 1 — Discovery & inventaire (NAS)

### Objectif

Découvrir les fichiers médias présents sur le NAS sans jamais traiter des fichiers incomplets.

### Acteur

RushCatalog Server (NAS)

### Étapes

1. Scan périodique des dossiers configurés (polling).
2. Détection des fichiers vidéo, photo et audio supportés.
3. Enregistrement ou mise à jour de l’asset (UUID, path, size, mtime).
4. Association des sidecars connus (même dossier, même base name).
5. Vérification de stabilité :

   * taille identique sur **2 scans consécutifs**
   * `mtime` plus ancien que **5–6 minutes**
6. Passage de l’état `DISCOVERED` à `READY` si conditions remplies.

### Règles

* Aucun traitement média n’est effectué.
* Aucun move ou rename n’est effectué.
* Le discovery est **read-only**.


## Workflow 2 — Enregistrement d’un agent RushIndexer

### Objectif

Permettre à un agent de processing (desktop/laptop/raspberry-pi) de s’identifier et d’annoncer ses capacités.

### Acteurs

RushIndexer Agent, RushCatalog Server

### Étapes

1. L’agent se déclare auprès du serveur (client_id, version, hostname).
2. L’agent annonce ses capacités (ex: proxy vidéo OK, transcription OK/NOK).
3. Le serveur enregistre l’agent et lui attribue des paramètres (quota, priorités).

### Règles

* Un agent peut tourner en arrière-plan en continu.
* Les décisions KEEP/REJECT ne sont jamais accessibles à un agent.


## Workflow 3 — Claim d’un job (processing review)

### Objectif

Attribuer un asset READY à un agent pour produire les éléments nécessaires à la review.

### Acteurs

RushCatalog Server, RushIndexer Agent

### Étapes

1. L’agent demande un job `process_for_review`.
2. Le serveur choisit un asset éligible (`READY`) et crée une réservation (lock + TTL).
3. Le serveur retourne : UUID, lock_token, chemins (pour SMB/NFS), liste des sidecars.
4. L’état passe à `PROCESSING_REVIEW`.

### Règles

* Échanges par **UUID**, jamais par path comme vérité.
* Un asset ne peut être réservé que par un seul agent à la fois.
* Si l’agent crash, le TTL expire et le job est reprenable.


## Workflow 4 — Processing review (agent en arrière-plan)

### Objectif

Produire tout ce qui rend la review possible dans l’UI : facts + dérivés.

### Acteur

RushIndexer Agent

### Étapes

1. Vérifier que le NAS est monté (SMB/NFS).
2. Lire le fichier principal et ses sidecars (read-only).
3. Extraire les facts (métadonnées techniques) et les envoyer au serveur.
4. Générer les dérivés dans `RUSHES_DB/.derived/{uuid}/...` :

   * VIDEO : proxy (obligatoire), thumbs
   * AUDIO : proxy (obligatoire), waveform (recommandé)
   * PHOTO : thumbs
5. Enregistrer les références de dérivés (paths) côté serveur.
6. En cas de job long : envoyer des heartbeats pour prolonger le TTL.
7. Soumettre le résultat final, libérer le lock.
8. Le serveur passe l’asset à `PROCESSED`.

### Règles

* Aucun move, rename ou suppression.
* L’agent ne prend jamais de décision KEEP/REJECT.
* `PROCESSED` exige que les proxies soient présents pour VIDEO/AUDIO.


## Workflow 5 — Jobs secondaires post-review

### Objectif

Produire des enrichissements non bloquants : transcription et suggestions de tags.

### Acteurs

RushCatalog Server, RushIndexer Agent (ou autres clients), éventuellement MCP

### Étapes

1. Après `PROCESSED`, le serveur rend éligible des jobs secondaires (si activés) :

   * transcription
   * suggestions de tags (LLM)
2. Un agent claim le job, traite et soumet.
3. Le serveur met à jour :

   * `transcript_status`
   * `suggestions_status`

### Règles

* Ces jobs ne modifient pas l’état principal (pas de transition).
* Les suggestions ne sont jamais appliquées automatiquement comme décision.
* Les suggestions peuvent être recalculées et remplacées.


## Workflow 6 — Review & décision humaine

### Objectif

Permettre à un humain de décider du devenir d’un média via l’UI, après processing.

### Acteur

Utilisateur via l’interface RushCatalog

### Étapes

1. Consultation des assets (proxy vidéo/audio, thumbs, waveform, facts, transcript si dispo).
2. Ajout/modification de tags libres et champs structurés.
3. (Optionnel) acceptation manuelle de suggestions de tags.
4. Prise de décision : `DECIDED_KEEP` ou `DECIDED_REJECT`.

### Règles

* Les décisions sont **humaines uniquement**.
* Aucun move n’est déclenché à ce stade.
* Une décision peut être annulée (retour `DECISION_PENDING`).


## Workflow 7 — Batch apply (déplacements)

### Objectif

Appliquer en une fois les décisions KEEP / REJECT.

### Acteurs

Utilisateur, RushCatalog Server

### Étapes

1. L’utilisateur déclenche l’action "Apply moves".
2. Dry-run :

   * liste des assets éligibles (`DECIDED_*` et `PROCESSED`)
   * détection des collisions de noms
   * liste des sidecars concernés
3. Lock batch pour éviter la concurrence (no-claim sur assets du batch).
4. Passage des assets en `MOVE_QUEUED`.
5. Déplacement des groupes (parent + sidecars) :

   * INBOX → ARCHIVE pour KEEP
   * INBOX → REJECTS pour REJECT
6. Renommage déterministe en cas de collision.
7. Mise à jour du path courant et de l’historique.
8. Passage à `ARCHIVED` ou `REJECTED`.
9. Rapport d’exécution (succès / erreurs non bloquantes).

### Règles

* Aucun move sans `PROCESSED`.
* Aucun move sans décision humaine.
* Les erreurs sur un asset ne bloquent pas le batch complet.


## Workflow 8 — Réouverture (re-review) d’un asset ARCHIVED/REJECTED

### Objectif

Permettre de reclasser un asset longtemps après (ex: REJECT après 6 mois).

### Acteur

Utilisateur via l’UI

### Étapes

1. L’utilisateur sélectionne un asset `ARCHIVED` ou `REJECTED`.
2. Action explicite "Reopen".
3. Le serveur passe l’asset en `DECISION_PENDING`.
4. L’utilisateur redécide KEEP/REJECT.
5. Application via batch move.

### Règles

* La réouverture est toujours une action humaine explicite.
* Aucun move immédiat.


## Workflow 9 — Reprocess

### Objectif

Relancer un processing sans casser l’historique.

### Acteurs

Utilisateur, RushCatalog Server, RushIndexer Agent

### Étapes

1. L’utilisateur demande un reprocess (action explicite).
2. Le serveur invalide facts/dérivés (version bump).
3. L’asset repasse `PROCESSED → READY`.
4. Un agent reprocess via le job `process_for_review`.

### Règles

* Les decisions humaines ne sont jamais écrasées automatiquement.
* Les facts et suggestions peuvent être remplacés.


## Workflow 10 — Purge différée des REJECTED (Clean after 180 days)

### Objectif

Libérer de l’espace en supprimant définitivement des assets rejetés, avec nettoyage des dérivés.

### Acteurs

Utilisateur (UI) et/ou politique de purge (serveur)

### Étapes

1. Les assets `REJECTED` deviennent éligibles à purge après un délai (ex: 180 jours).
2. L’utilisateur confirme une purge (ou une politique auto est activée explicitement).
3. Suppression des fichiers :

   * originaux + sidecars
   * dérivés sous `RUSHES_DB/.derived/{uuid}/...`
4. Passage de l’état à `PURGED`.
5. Conservation d’un audit minimal.

### Règles

* La purge est destructive.
* La purge ne s’applique jamais à `ARCHIVED`.
* La purge est idempotente (relance possible sans casse).


## Workflow 11 — Travail offline / on-the-go

### Objectif

Permettre le travail hors connexion sans compromettre l’intégrité de la médiathèque.

### Acteurs

Utilisateur, outils de montage

### Étapes

1. Sélection d’assets via RushCatalog (bins, filtres).
2. Préparation d’un projet local (ex: DaVinci Resolve).
3. Travail offline (montage, notes).
4. Reconnexion au NAS.
5. Relinking vers les originaux.

### Règles

* Le travail offline ne modifie jamais le NAS.
* Aucun move, rename ou suppression.
* Les décisions sont prises uniquement une fois reconnecté.


## Workflow 12 — Exports & livrables

### Objectif

Produire des livrables sans polluer la base de rushes.

### Acteur

Utilisateur

### Étapes

1. Export depuis l’outil de montage.
2. Stockage dans un dossier EXPORTS dédié.
3. Organisation par projet / format / destination.

### Règles

* Les exports ne retournent jamais dans l’inventaire.
* Les exports ne sont jamais reprocessés.


## Workflow 13 — Gestion des photos

### Objectif

Appliquer le même lifecycle aux photos qu’aux vidéos.

### Étapes

1. Discovery des photos sur le NAS.
2. Passage `DISCOVERED → READY`.
3. Processing review (EXIF + thumbs).
4. Décision humaine KEEP/REJECT.
5. Batch apply.

### Règles

* Une seule logique pour tous les médias.
* Aucune exception spécifique "photo".


## Workflow 14 — Gestion des fichiers audio

### Objectif

Gérer musique et prises son comme des assets de production.

### Étapes

1. Discovery des fichiers audio.
2. Processing review (facts + proxy + waveform).
3. Décision humaine KEEP/REJECT.
4. Batch apply.

### Règles

* L’audio est un asset de première classe.
* Peut être lié à un asset vidéo comme sidecar logique.


## Workflow 15 — Gestion des erreurs

### Objectif

Éviter toute corruption ou perte de données.

### Principes

* Les erreurs de processing ne déclenchent jamais de move.
* Les locks expirent automatiquement.
* Les actions filesystem sont journalisées.
* Aucun fichier n’est supprimé automatiquement (sauf via politique de purge explicitement activée).


## Invariants globaux

* NAS = source de vérité logistique
* Laptop/clients = compute only
* UUID = identité stable
* Path = attribut mutable
* Décisions humaines uniquement
* Déplacements uniquement en batch
* Purge destructive uniquement sur `REJECTED` et explicitement configurée
* Aucune action destructive sans traçabilité
