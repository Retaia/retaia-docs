# STATE MACHINE — MediaAsset Lifecycle (v2, proxy-first)

Ce document définit la **machine à états formelle** des MediaAssets dans le système Retaia Core + Retaia Agent, version **proxy-first** avec Retaia Agent en **agent background**.

Il est **normatif** : toute implémentation doit respecter strictement ces états, transitions et interdictions.


## Principe fondamental

* Les **états** décrivent le **cycle de vie métier** (découverte → traitement → décision → move).
* Les détails de traitement (proxy/thumb/transcription/suggestions) sont des **phases/flags**, pas des états principaux.
* KEEP/REJECT est une **décision humaine**.
* Les moves sont **batch**.


## États principaux

### DISCOVERED

#### Signification

Asset découvert sur le NAS, stabilité non confirmée.

#### Transitions autorisées

* `DISCOVERED → READY`


### READY

#### Signification

Fichier stable et éligible au processing.

#### Conditions d’entrée

* stable sur ≥ 2 scans consécutifs (taille identique)
* `mtime` plus ancien que 5–6 minutes

#### Transitions autorisées

* `READY → PROCESSING_REVIEW` (claim d'un premier job atomique de processing review)


### PROCESSING_REVIEW

#### Signification

Traitement “pour review” en cours via un ou plusieurs jobs atomiques : facts + thumbs + proxy + éventuels enrichissements requis par profil.

#### Transitions autorisées

* `PROCESSING_REVIEW → PROCESSED` (quand tous les jobs requis par le profil media sont terminés)
* `PROCESSING_REVIEW → READY` (échec + retry/backoff côté jobs)

#### Règles

* Réservation via lock + TTL
* Aucun move autorisé


### PROCESSED

#### Signification

Traitement nécessaire à la review terminé.

#### Garanties (non négociables)

* facts extraits et stockés en DB
* thumbs générés
* proxy généré et disponible pour la review
* références vers dérivés enregistrées
* tous les prérequis du `processing_profile` sont satisfaits

#### Transitions autorisées

* `PROCESSED → DECISION_PENDING` (automatique, après exécution des hooks/plugins post-processed)
* `PROCESSED → READY` (reprocess explicite)


### DECISION_PENDING

#### Signification

Traitement OK, attente décision humaine.

#### Transitions autorisées

* `DECISION_PENDING → DECIDED_KEEP`
* `DECISION_PENDING → DECIDED_REJECT`


### DECIDED_KEEP

#### Signification

Décision humaine KEEP.

#### Transitions autorisées

* `DECIDED_KEEP → MOVE_QUEUED`
* `DECIDED_KEEP → DECIDED_REJECT` (changement d’avis humain)
* `DECIDED_KEEP → DECISION_PENDING` (annulation explicite)


### DECIDED_REJECT

#### Signification

Décision humaine REJECT.

#### Transitions autorisées

* `DECIDED_REJECT → MOVE_QUEUED`
* `DECIDED_REJECT → DECIDED_KEEP` (changement d’avis humain)
* `DECIDED_REJECT → DECISION_PENDING` (annulation explicite)


### MOVE_QUEUED

#### Signification

Asset planifié pour un batch move (apply).

#### Transitions autorisées

* `MOVE_QUEUED → ARCHIVED`
* `MOVE_QUEUED → REJECTED`

#### Règles

* Verrou par asset (fichier/rush) : aucun job processing ne peut être claim sur ces assets


### ARCHIVED

#### Signification

Asset déplacé vers ARCHIVE.

#### Transitions autorisées

* `ARCHIVED → DECISION_PENDING` (réouverture explicite pour re-review et reclasser)
* `ARCHIVED → READY` (reprocess explicite)


### REJECTED

#### Signification

Asset déplacé vers REJECTS.

#### Transitions autorisées

* `REJECTED → DECISION_PENDING` (réouverture explicite, optionnelle)
* `REJECTED → READY` (reprocess explicite)
* `REJECTED → PURGED` (purge destructive, explicite ou via politique)


## Détails de processing (flags/phases, pas des états)

Ces flags existent dans la DB et sont mis à jour par les jobs.

### Processing review (requis pour PROCESSED)

* `facts_done` (bool)
* `thumbs_done` (bool)
* `proxy_done` (bool) — requis
* `waveform_done` (bool) — requis si `processing_profile` l'exige
* `processing_profile` (string) — ex: `video_standard`, `audio_music`, `audio_voice`
* `review_processing_version` (string/int)

### Transcription (job secondaire)

* `transcript_status` = `NONE | RUNNING | DONE | FAILED`
* `transcript_version`
* `transcript_updated_at`

### Suggestions (tags)

* `suggestions_status` = `NONE | RUNNING | DONE | FAILED`
* `suggestions_version`
* `suggestions_source` (modèle, prompt_version, etc.)

Règle : aucune suggestion ne modifie automatiquement les décisions ou tags validés par l’humain.


## Jobs secondaires (post-review)

Après `PROCESSED`, le serveur peut rendre éligible :

* `transcribe_audio` (si profil audio et activé)
* `suggest_tags` (LLM, basé sur transcript + metadata)

Ces jobs ne changent pas l’état principal.

## Hooks autour de DECISION_PENDING

Pour permettre les extensions sans casser le lifecycle principal :

* un hook/plugin peut s'exécuter après `PROCESSED` et avant `DECISION_PENDING`
* un hook/plugin peut s'exécuter à l'entrée de `DECISION_PENDING`
* ces hooks ne doivent jamais contourner les transitions de la machine à états
* ces hooks ne doivent jamais prendre de décision KEEP / REJECT


## Reprocess (explicite)

Transitions autorisées :

* `PROCESSED → READY`
* `ARCHIVED → READY`
* `REJECTED → READY`

Effets :

* Invalidation des données de processing (facts, dérivés, transcript, suggestions) via version bump
* Retour à un état technique minimal connu (`READY`)
* Regénération des outputs selon le `processing_profile`
* Les décisions humaines existantes ne sont pas réappliquées automatiquement


## Suppression différée REJECTED & nettoyage des dérivés

Objectif : permettre une option du type “Clean REJECTED after 180 days”.

### État terminal : PURGED

`PURGED` est un état terminal utilisé après suppression destructive.

#### Signification

L’asset a été supprimé (originaux + sidecars) et ses dérivés ont été nettoyés.

#### Garanties

* originaux supprimés
* sidecars supprimés
* dérivés supprimés sous `RUSHES_DB/.derived/{uuid}/...`
* audit minimal conservé (trace de l’existence passée)

#### Transitions autorisées

* `REJECTED → PURGED` (action explicite de purge)

#### Règles

* Toute purge est destructive et doit être explicitement confirmée (UI)
* Une purge automatique (cron) est autorisée uniquement si :

    * l’asset est `REJECTED`
    * `rejected_at` dépasse le seuil (ex: 180 jours)
    * la politique de purge est explicitement activée


## États principaux (complément)

### PURGED

#### Signification

L’asset a été purgé (suppression définitive des fichiers et dérivés).

#### Transitions autorisées

* Aucune (état terminal)


## Transitions interdites (exemples importants)

* `DISCOVERED → PROCESSING_REVIEW`
* `READY → DECIDED_*`
* `PROCESSED → ARCHIVED/REJECTED` (sans décision + batch)
* `DECISION_PENDING → MOVE_QUEUED`
* `DECIDED_* → ARCHIVED/REJECTED` (sans batch)
* `ARCHIVED/REJECTED → PROCESSED` (doit repasser par `READY` via reprocess explicite)
* `PURGED → *` (état terminal)

Toute transition non listée comme autorisée est interdite par défaut.


## Lecture rapide (résumé)

```
DISCOVERED
  ↓
READY
  ↓
PROCESSING_REVIEW
  ↓
PROCESSED
  ↓
DECISION_PENDING
  ↓
DECIDED_KEEP / DECIDED_REJECT
  ↓
MOVE_QUEUED
  ↓
ARCHIVED / REJECTED



REJECTED
  ↓
PURGED (optionnel, destructif)



DISCOVERED
  ↓
READY
  ↓
PROCESSING_REVIEW
  ↓
PROCESSED
  ↓
DECISION_PENDING
  ↓
DECIDED_KEEP / DECIDED_REJECT
  ↓
MOVE_QUEUED
  ↓
ARCHIVED / REJECTED
  ↘
   (REOPEN) → DECISION_PENDING
```


## Règle finale

Si une fonctionnalité nécessite une transition qui n’est pas décrite ici,

➡️ **la machine à états doit être modifiée explicitement avant toute implémentation.**

## Références associées

* [WORKFLOWS.md](../workflows/WORKFLOWS.md)
* [API-CONTRACTS.md](../api/API-CONTRACTS.md)
* [JOB-TYPES.md](../definitions/JOB-TYPES.md)
