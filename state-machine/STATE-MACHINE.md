# STATE MACHINE — MediaAsset Lifecycle (v2, proxy-first)

Ce document définit la **machine à états formelle** des MediaAssets dans le système Retaia, version **proxy-first** avec traitement en arrière-plan par les agents.

Il est **normatif** : toute implémentation doit respecter strictement ces états, transitions et interdictions.


## Principe fondamental

* Les **états** décrivent le **cycle de vie métier** (découverte → traitement → décision → move).
* Les détails de traitement (proxy/thumb/transcription/suggestions) sont des **phases/flags**, pas des états principaux.
* KEEP/REJECT est une **décision humaine**.
* L'application d'un move est **unitaire par asset** côté Core.
* Une sélection de plusieurs assets ("batch") est un concept UI uniquement.


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

* `DECIDED_KEEP → ARCHIVED` (application explicite de la décision)
* `DECIDED_KEEP → DECIDED_REJECT` (changement d’avis humain)
* `DECIDED_KEEP → DECISION_PENDING` (annulation explicite)


### DECIDED_REJECT

#### Signification

Décision humaine REJECT.

#### Transitions autorisées

* `DECIDED_REJECT → REJECTED` (application explicite de la décision)
* `DECIDED_REJECT → DECIDED_KEEP` (changement d’avis humain)
* `DECIDED_REJECT → DECISION_PENDING` (annulation explicite)


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

### PURGED

#### Signification

L’asset a été purgé (suppression définitive des fichiers et dérivés).

#### Transitions autorisées

* Aucune (état terminal)


## Détails de processing (flags/phases, pas des états)

Ces flags existent dans la DB et sont mis à jour par les jobs.

### Processing review (requis pour PROCESSED)

* `facts_done` (bool)
* `thumbs_done` (bool)
* `proxy_done` (bool) — requis
* `waveform_done` (bool) — requis pour tout média avec piste audio exploitable
* `processing_profile` (string) — ex: `video_standard`, `audio_undefined`, `audio_music`, `audio_voice`
* `review_processing_version` (string/int)

### Transcription

* `transcript_status` = `NONE | RUNNING | DONE | FAILED`
* `transcript_version`
* `transcript_updated_at`
* à partir de la phase `v1.1+` validée, la transcription devient un prérequis de `PROCESSED` pour tout média avec piste audio exploitable dont le `processing_profile` l'exige
* avant cette phase validée, elle PEUT être activée plus tôt sous `feature_flags` sans modifier la conformité v1

### Suggestions (tags)

Disponibilité : **v1.1+** (AI-powered).

* `suggestions_status` = `NONE | RUNNING | DONE | FAILED`
* `suggestions_version`
* `suggestions_source` (modèle, prompt_version, etc.)

Règle : aucune suggestion ne modifie automatiquement les décisions ou tags validés par l’humain.


## Jobs secondaires (post-review)

Après `PROCESSED`, le serveur peut rendre éligible :

* `suggest_tags` (**v1.1+**, LLM, basé sur transcript + metadata)

Règle : dès que la phase `v1.1+` validée rend `transcribe_audio` obligatoire pour un média avec piste audio exploitable dont le profil l'exige, cette transcription n'est plus un job secondaire post-review mais un prérequis de `PROCESSED`.

Règle audio ambigu :

* `processing_profile=audio_undefined` bloque le passage à `PROCESSED`
* Core DOIT exiger un choix humain explicite vers `audio_music` ou `audio_voice`
* si ce choix rend `transcribe_audio` requis dans la phase active, Core DOIT créer automatiquement le job après mutation du profil

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

Règles :

* Toute purge est destructive et doit être explicitement confirmée (UI), sauf politique auto activée.
* Une purge automatique (cron) est autorisée uniquement si :
  * l’asset est `REJECTED`
  * `rejected_at` dépasse le seuil (ex: 180 jours)
  * la politique de purge est explicitement activée
* La purge supprime originaux + sidecars + dérivés et conserve un audit minimal.


## Transitions interdites (exemples importants)

* `DISCOVERED → PROCESSING_REVIEW`
* `READY → DECIDED_*`
* `PROCESSED → ARCHIVED/REJECTED` (sans décision)
* `DECISION_PENDING → ARCHIVED/REJECTED` (sans décision explicite + apply)
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
ARCHIVED / REJECTED
  ↘
   (REOPEN) → DECISION_PENDING
  ↘
   PURGED (optionnel, destructif, si REJECTED)
```


## Règle finale

Si une fonctionnalité nécessite une transition qui n’est pas décrite ici,

➡️ **la machine à états doit être modifiée explicitement avant toute implémentation.**

## Références associées

* [WORKFLOWS.md](../workflows/WORKFLOWS.md)
* [API-CONTRACTS.md](../api/API-CONTRACTS.md)
* [JOB-TYPES.md](../definitions/JOB-TYPES.md)
* [PROCESSING-PROFILES.md](../definitions/PROCESSING-PROFILES.md)
* [LOCKING-MATRIX.md](../policies/LOCKING-MATRIX.md)
