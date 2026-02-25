# WORKFLOWS — Retaia Core + Retaia Agent

Ce document décrit les **workflows canoniques** du système Retaia Core + Retaia Agent.

Ils sont **normatifs** : toute implémentation ou évolution future doit les respecter.


## Workflow 1 — Discovery & inventaire (NAS)

### Objectif

Découvrir les fichiers médias présents sur le NAS sans jamais traiter des fichiers incomplets.

### Acteur

Retaia Core Server (NAS)

### Étapes

1. Scan périodique des dossiers configurés (polling).
2. Détection des fichiers vidéo, photo et audio supportés.
3. Enregistrement ou mise à jour de l’asset (UUID, path, size, mtime).
4. Association des sidecars connus (même dossier, même base name).
5. Vérification de stabilité :

   * taille identique sur **2 scans consécutifs**
   * `mtime` plus ancien que **5–6 minutes**
6. Passage de l’état `DISCOVERED` à `READY` si conditions remplies.
7. Attribution d'un `processing_profile` (auto par défaut, modifiable manuellement avant claim).

### Règles

* Aucun traitement média n’est effectué.
* Aucun move ou rename n’est effectué.
* Le discovery est **read-only**.


## Workflow 2 — Enregistrement d’un agent Retaia Agent

### Objectif

Permettre à un agent de processing (desktop/laptop/raspberry-pi) de s’identifier et d’annoncer ses capacités.

### Acteurs

Retaia Agent, Retaia Core Server

### Étapes

1. L’agent se déclare auprès du serveur (`agent_name`, `agent_version`, `platform`).
2. L’agent annonce ses capabilities déclaratives (ex: `media.proxies.video@1`, `speech.transcription@1`).
3. Le serveur enregistre l’agent et lui attribue des paramètres (quota, priorités).

### Règles

* Un agent peut tourner en arrière-plan en continu.
* Les décisions KEEP/REJECT ne sont jamais accessibles à un agent.


## Workflow 3 — Claim d’un job (processing review)

### Objectif

Attribuer un asset READY à un agent pour produire les éléments nécessaires à la review.

### Acteurs

Retaia Core Server, Retaia Agent

### Étapes

1. L’agent récupère les jobs claimables via `GET /jobs`.
2. L’agent tente un claim atomique via `POST /jobs/{job_id}/claim`.
3. Le serveur crée une réservation (lock + TTL) et retourne `asset_uuid`, `lock_token`, `source` (`storage_id`, `original_relative`, `sidecars_relative[]`) et métadonnées nécessaires.
4. Le job passe en `claimed`.
5. L’asset passe en `PROCESSING_REVIEW` dès qu’au moins un job review est en cours.

### Règles

* Échanges par **UUID**, jamais par path comme vérité.
* Un asset ne peut être réservé que par un seul agent à la fois.
* Si l’agent crash, le TTL expire et le job est reprenable.


## Workflow 4 — Processing review (agent en arrière-plan)

### Objectif

Produire tout ce qui rend la review possible dans l’UI : facts + dérivés.

### Acteur

Retaia Agent

### Étapes

1. Vérifier qu'un mount local existe pour `source.storage_id` (SMB/NFS/NAS local).
2. Résoudre puis lire le fichier principal et ses sidecars (read-only) via `storage_mounts[source.storage_id] + source.*_relative`.
3. Extraire les facts (métadonnées techniques) et les envoyer au serveur.
4. Générer les dérivés en local temporaire côté agent :

   * VIDEO : proxy (obligatoire), thumbs
   * AUDIO : proxy (obligatoire), waveform (recommandé)
   * PHOTO : proxy (obligatoire), thumbs
5. Uploader les dérivés via l'API (`/assets/{uuid}/derived/upload/*`).
6. Enregistrer les références de dérivés côté serveur.
7. En cas de job long : envoyer des heartbeats pour prolonger le TTL.
8. Soumettre le résultat final, libérer le lock.
9. Le serveur passe l’asset à `PROCESSED` quand tous les jobs requis par le `processing_profile` sont terminés.

### Règles

* Aucun move, rename ou suppression.
* L’agent ne prend jamais de décision KEEP/REJECT.
* Les agents n'écrivent jamais directement dans `RUSHES_DB/.derived`.
* `PROCESSED` dépend du `processing_profile` de l'asset.


## Workflow 5 — Jobs secondaires post-review

### Objectif

Produire des enrichissements non bloquants : transcription et suggestions de tags.

### Acteurs

Retaia Core Server, Retaia Agent (ou autres clients), éventuellement MCP

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

Utilisateur via l’interface Retaia Core

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

Utilisateur, Retaia Core Server

### Étapes

1. L’utilisateur déclenche l’action "Apply moves".
2. Dry-run :

   * liste des assets éligibles (`DECIDED_KEEP` et `DECIDED_REJECT`)
   * détection des collisions de noms
   * liste des sidecars concernés
3. Passage des assets en `MOVE_QUEUED`.
4. Pour chaque asset : lock exclusif par fichier/rush.
5. Déplacement des groupes (parent + sidecars) :

   * INBOX → ARCHIVE pour KEEP
   * INBOX → REJECTS pour REJECT
6. Renommage déterministe en cas de collision avec suffixe `__{short_nonce}`.
7. Mise à jour du path courant et de l’historique.
8. Release du lock de l'asset.
9. Passage à `ARCHIVED` ou `REJECTED`.
10. Rapport d’exécution (succès / erreurs non bloquantes).

### Règles

* Aucun move sans décision humaine.
* Un asset locké pour move n'est pas claimable pour processing.
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

Utilisateur, Retaia Core Server, Retaia Agent

### Étapes

1. L’utilisateur demande un reprocess (action explicite).
2. Le serveur invalide toutes les données de processing (facts, dérivés, transcript, suggestions) via version bump.
3. L’asset repasse `PROCESSED|ARCHIVED|REJECTED → READY`.
4. Un ou plusieurs agents reprocessent via des jobs atomiques par capability.

### Règles

* Les décisions humaines ne sont jamais écrasées automatiquement.
* Les données de processing sont reconstruites depuis `READY`.


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

1. Sélection d’assets via Retaia Core (bins, filtres).
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
3. Processing review (EXIF + proxy + thumbs).
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

## Références associées

* [STATE-MACHINE.md](../state-machine/STATE-MACHINE.md)
* [AGENT-PROTOCOL.md](AGENT-PROTOCOL.md)
* [JOB-TYPES.md](../definitions/JOB-TYPES.md)
* [PROCESSING-PROFILES.md](../definitions/PROCESSING-PROFILES.md)
* [SIDECAR-RULES.md](../definitions/SIDECAR-RULES.md)
* [NAMING-AND-NONCE.md](../policies/NAMING-AND-NONCE.md)
* [LOCK-LIFECYCLE.md](../policies/LOCK-LIFECYCLE.md)
* [API-CONTRACTS.md](../api/API-CONTRACTS.md)
