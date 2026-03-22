# Job Types — Processing Pipeline

Ce document définit les **types de jobs** que le serveur Retaia Core peut créer et confier aux agents de processing.

Ces règles sont **normatives**.


## 1. Définition

Un **job** représente une unité de travail atomique confiée à un agent.

Un job :

* est **déterministe**
* est **idempotent**
* produit des outputs explicites
* ne prend **jamais** de décision métier

Un job n’est **pas** :

* un workflow complet
* une décision KEEP / REJECT
* une action destructive


## 2. Structure d’un job

Chaque job est défini par :

* `job_type`
* `asset_uuid`
* `required_capabilities[]`
* `inputs`
* `expected_outputs`
* `invariants`

Un job qui ne respecte pas cette structure est invalide.

## 2.1 Registre canonique — `job_type -> required_capabilities -> outputs`

| `job_type` | Disponibilite | `required_capabilities[]` | Outputs structurants obligatoires | Surface partagee cible |
| --- | --- | --- | --- | --- |
| `extract_facts` | `v1` | `media.facts@1` | `facts` | `AssetDetail.fields` et complétude Core |
| `generate_preview` | `v1` | `media.previews.video@1` ou `media.previews.audio@1` ou `media.previews.photo@1` | `preview_video` ou `preview_audio` ou `preview_photo` | `AssetDetail.derived` |
| `generate_thumbnails` | `v1` | `media.thumbnails@1` | `thumbs[]` | `AssetDetail.derived.thumbs[]` |
| `generate_audio_waveform` | `v1` | `audio.waveform@1` | `waveform_data` | `AssetDetail.derived.waveform_url` |
| `transcribe_audio` | `v1.1+` (activable plus tôt sous `feature_flags`) | `speech.transcription@1` | `transcript_text` | `AssetDetail.transcript` |
| `suggest_tags` | `v1.1+` (activable plus tôt sous `feature_flags`) | `meta.tags.suggestions@1`, `llm.client.ollama@1` | `suggested_tags[]` | surface AI future, hors conformité `v1` |

Règles :

* ce registre est la source unique de vérité pour l'association entre `job_type`, capabilities requises et outputs structurants
* aucun job ne PEUT produire un output structurant partagé absent de ce registre
* tout output structurant partagé DOIT être rattaché à exactement un `job_type` canonique


## 3. Job types définis

Les jobs de processing review sont atomiques et orchestrés par le serveur selon le `processing_profile` de l'asset.

### 3.1 `extract_facts`

**Objectif**  
Extraire les métadonnées techniques minimales (durée, codec, format, dimensions, etc.).

**Required capabilities**

* `media.facts@1`

**Inputs**

* asset_uuid
* source_locator (read-only: `storage_id`, `original_relative`, `sidecars_relative[]`)

**Expected outputs**

* facts (JSON)

Contrat minimal `facts` (normatif) :

* pour `PHOTO` :
  * `media_format`
  * `width`
  * `height`
* pour `AUDIO` :
  * `duration_ms`
  * `media_format`
  * `audio_codec`
* pour `VIDEO` :
  * `duration_ms`
  * `media_format`
  * `video_codec`
  * `width`
  * `height`
  * `fps`
  * `audio_codec` si une piste audio exploitable est détectée

Règles :

* `extract_facts` PEUT produire des champs supplémentaires, mais NE DOIT PAS omettre les champs minimaux applicables au `media_type`
* l'absence d'un champ minimal applicable rend le résultat de facts incomplet
* `extract_facts` PEUT aussi produire des facts enrichis typés quand ils sont disponibles de façon déterministe, notamment :
  * `captured_at`
  * `exposure_time_s`
  * `aperture_f_number`
  * `iso`
  * `focal_length_mm`
  * `camera_make`
  * `camera_model`
  * `lens_model`
  * `orientation`
  * `bitrate_kbps`
  * `sample_rate_hz`
  * `channel_count`
  * `bits_per_sample`
  * `rotation_deg`
  * `timecode_start`
  * `pixel_format`
  * `color_range`
  * `color_space`
  * `color_transfer`
  * `color_primaries`
  * `recorder_model`
  * `gps_latitude`
  * `gps_longitude`
  * `gps_altitude_m`
  * `gps_altitude_relative_m`
  * `gps_altitude_absolute_m`
  * `exposure_compensation_ev`
  * `color_mode`
  * `color_temperature_k`
  * `has_dji_metadata_track`
  * `dji_metadata_track_types[]`
* les champs `gps_*` sont des facts source ; lorsqu'ils sont acceptés par Core, ils DOIVENT être stockés dans des colonnes/champs dédiés typés côté Core, jamais cachés implicitement dans `AssetDetail.fields`

**Invariants**

* aucune modification du média original
* output entièrement recréable

**Failure modes**

* source illisible → fatal
* timeout/OOM → retryable


### 3.2 `generate_preview`

**Objectif**  
Générer le dérivé principal de consultation selon le type média.

Règle normative :

* la preview produite DOIT être directement exploitable par l'UI web via les Web APIs HTML standards du navigateur :
  * `HTMLVideoElement` pour `preview_video`
  * `HTMLAudioElement` pour `preview_audio`
  * `HTMLImageElement` pour `preview_photo`

**Required capabilities**

* `media.previews.video@1` (VIDEO)
* `media.previews.audio@1` (AUDIO)
* `media.previews.photo@1` (PHOTO)

**Inputs**

* asset_uuid
* source_locator (read-only: `storage_id`, `original_relative`, `sidecars_relative[]`)
* media_type
* preview_profile

`preview_profile` (normatif) :

* `video_review_default_v1`
  * profil canonique pour `VIDEO`
  * produit `preview_video`
* `audio_review_default_v1`
  * profil canonique pour `AUDIO`
  * produit `preview_audio`
* `photo_review_default_v1`
  * profil canonique pour `PHOTO`
  * produit `preview_photo`

Règles :

* un job `generate_preview` DOIT utiliser exactement un `preview_profile` canonique
* le suffixe `_v1` fait partie du contrat de rendu ; tout changement non rétrocompatible DOIT créer un nouveau `preview_profile`
* un `preview_profile` ne DOIT PAS changer le type de dérivé produit ; il change seulement le contrat de rendu de ce type

**Expected outputs**

* derived_manifest[] (kind + référence upload)

Sortie attendue par `preview_profile` :

* `video_review_default_v1` -> exactement un `preview_video`
* `audio_review_default_v1` -> exactement un `preview_audio`
* `photo_review_default_v1` -> exactement un `preview_photo`

**Invariants**

* aucune modification du média original
* aucun déplacement de fichier
* outputs entièrement recréables
* la preview DOIT rester lisible sans codec/plugin propriétaire ou dépendance hors Web platform standard

**Failure modes**

* source illisible → fatal
* erreur d’encodage/rendu → retryable


### 3.3 `generate_thumbnails`

**Objectif**  
Générer des vignettes à partir d’un média vidéo.

**Required capabilities**

* `media.thumbnails@1`

**Inputs**

* asset_uuid
* source_locator (read-only: `storage_id`, `original_relative`, `sidecars_relative[]`)
* thumbnail_profile

Précondition normative :

* `generate_thumbnails` NE DOIT être créé que pour un asset `VIDEO`

`thumbnail_profile` (normatif) :

* `video_representative_v1`
  * produit au moins un thumb `representative`
* `video_storyboard_v1`
  * produit exactement `10` thumbs vidéo répartis régulièrement sur la durée utile, incluant le thumb principal

Règles :

* un job `generate_thumbnails` DOIT utiliser exactement un `thumbnail_profile` canonique
* le suffixe `_v1` fait partie du contrat de sélection temporelle ; tout changement non rétrocompatible DOIT créer un nouveau `thumbnail_profile`
* `video_representative_v1` est le profil par défaut
* `video_storyboard_v1` est optionnel

Règles temporelles associées à `video_representative_v1` et `video_storyboard_v1` :

* vidéo courte : durée strictement inférieure à `120s`
* vidéo longue : durée supérieure ou égale à `120s`
* vidéo courte : frame de référence à `max(1s, 10% de la durée)`
* vidéo longue : frame de référence à `5% de la durée`, avec fallback à `20s` si `5% > 20s`
* le moteur DOIT éviter les frames noires ou de fondu si une heuristique légère permet d'en sélectionner une voisine plus représentative
* les thumbs de `video_storyboard_v1` DOIVENT être triés chronologiquement
* une légère marge de sécurité aux extrémités du média est autorisée pour éviter des frames d'ouverture/fermeture non représentatives
* pour une image fixe, aucun job `generate_thumbnails` distinct n'est requis en v1; la preview image couvre la consultation
* pour un audio sans image, aucun thumb temporel n'est requis; seule la preview/waveform couvre la review

**Expected outputs**

* thumbs[]

`thumbs[]` (minimum normatif) :

* avec `video_representative_v1` : au moins un thumb `representative`
* avec `video_storyboard_v1` : exactement `10` thumbs vidéo DOIVENT être produits
* chaque thumb DOIT rester dérivable de manière déterministe à partir du `thumbnail_profile`
* chaque thumb DOIT exposer un ordre stable dans le manifest dérivé

**Invariants**

* aucune modification du média original
* outputs entièrement recréables
* la sélection temporelle DOIT rester stable pour un même média, un même profil et une même version d'algorithme

**Failure modes**

* source illisible → fatal
* erreur de rendu → retryable


### 3.4 `generate_audio_waveform`

**Objectif**  
Extraire une waveform audio quand le `processing_profile` l'exige.

**Required capabilities**

* `audio.waveform@1`

**Inputs**

* asset_uuid
* source_locator (read-only: `storage_id`, `original_relative`, `sidecars_relative[]`)

**Expected outputs**

* waveform_data

`waveform_data` (minimum normatif) :

* payload couvrant toute la durée audio
* bucketisation temporelle régulière
* `bucket_count` recommandé : `1000`
* `bucket_count` minimum : `100`
* amplitudes normalisées entre `0` et `1`
* méthode d'agrégation stable dans une même implémentation

Projection runtime partagée :

* `waveform_data` DOIT être rendu disponible via la ressource canonique pointée par `AssetDetail.derived.waveform_url`
* le payload servi via `waveform_url` DOIT rester cohérent avec `bucket_count` et la série normalisée produits par le job

**Invariants**

* aucune modification du média original
* output dérivable à l’identique

**Failure modes**

* piste audio absente → fatal


### 3.5 `transcribe_audio`

Disponibilité : **v1.1+** (activable plus tôt sous `feature_flags` pendant le développement et la pré-release).

Ce job peut rester indéfiniment en statut pending tant qu’aucun agent ne déclare la capability requise.

**Objectif**  
Produire une transcription (et éventuellement des timecodes) à partir de l’audio d’un média. À partir de la phase `v1.1+` validée, ce job devient requis pour tout média dont le `processing_profile` l'exige afin d'atteindre `PROCESSED`.

**Required capabilities**

* `speech.transcription@1`
* `speech.transcription.local.whispercpp@1` (minimum local-first)

**Inputs**

* asset_uuid
* source_locator (read-only: `storage_id`, `original_relative`, `sidecars_relative[]`)
* language (optionnel)
* transcription_profile (optionnel)
* transcription_engine (optionnel; ex: `whispercpp`)
* remote_transcription_allowed (optionnel, défaut: `false`)

**Expected outputs**

* transcript_text
* segments[] (optionnel : start_ms, end_ms, text)
* confidence (optionnel)

**Invariants**

* aucune modification du média original
* aucune décision KEEP / REJECT
* output recréable (si le moteur change de manière non rétrocompatible, incrémenter la version de capability)

**Failure modes**

* pas de piste audio → fatal
* timeout / OOM → retryable
* moteur indisponible → retryable
* backend distant demandé sans opt-in explicite → failed non bloquant (policy violation)


### 3.6 `suggest_tags`

Disponibilité : **v1.1+** (dépendant de l'AI).

**Objectif**  
Produire des suggestions de tags à partir des facts/transcript/metadata.

**Required capabilities**

* `meta.tags.suggestions@1`
* `llm.client.ollama@1`
* `llm.client.chatgpt@1` (optionnel, sous flag)
* `llm.client.claude@1` (optionnel, sous flag)

**Inputs**

* asset_uuid
* facts_ref
* transcript_ref (optionnel)
* human_tags_ref (optionnel)
* human_fields_ref (optionnel)
* notes_ref (optionnel)
* suggestion_profile (optionnel)
* llm_provider (optionnel, runtime policy; valeurs: `ollama|chatgpt|claude`)
* llm_model (recommandé; valeur issue du catalogue runtime choisi par l'utilisateur)

Priorité des inputs (normative) :

1. `facts_ref` : base structurée obligatoire
2. `transcript_ref` : enrichissement sémantique préféré quand présent
3. `human_tags_ref`, `human_fields_ref`, `notes_ref` : contexte humain prioritaire pour contraindre les suggestions, éviter les doublons et préserver la terminologie métier validée

Règles :

* `suggest_tags` DOIT refuser de tourner si `facts_ref` est absent
* l'absence de `transcript_ref` NE DOIT PAS bloquer le job
* les métadonnées humaines existantes DOIVENT être traitées comme contexte faisant autorité, jamais comme une cible à réécrire automatiquement

**Expected outputs**

* suggested_tags[]
* source (model, profile_version, etc.)

**Invariants**

* aucune décision KEEP / REJECT
* aucune modification automatique des tags humains

**Failure modes**

* modèle indisponible → retryable
* entrée insuffisante → failed non bloquant
* provider indisponible → `failed` retryable
* aucun fallback implicite de provider n'est autorisé dans le contrat partagé `v1.1+`; tout changement de provider DOIT résulter d'un choix runtime explicite déjà validé par Core et l'utilisateur
* modèle absent du catalogue runtime autorisé → `failed` non bloquant (validation configuration)
* provider désactivé par feature flag runtime -> `failed` non bloquant (`FORBIDDEN_SCOPE`)


## 4. Règles d’évolution

* Ajouter un nouveau job type est un **changement compatible**.
* Modifier les invariants ou outputs d’un job est un **changement structurel**.
* Supprimer un job type nécessite une migration explicite.


## 5. Anti-patterns

Les pratiques suivantes sont interdites :

* créer des jobs multi-responsabilités
* implémenter des décisions métier dans un job
* faire dépendre un job d’un état implicite
* produire des outputs non documentés


## 6. Objectif

Le système de jobs vise à :

* rendre le processing prévisible
* permettre le retry sécurisé
* isoler les responsabilités
* rendre l’orchestration explicite

Toute implémentation qui viole ces objectifs est invalide.

## Références associées

* [CAPABILITIES.md](CAPABILITIES.md)
* [PROCESSING-PROFILES.md](PROCESSING-PROFILES.md)
* [STATE-MACHINE.md](../state-machine/STATE-MACHINE.md)
* [AGENT-PROTOCOL.md](../workflows/AGENT-PROTOCOL.md)
* [API-CONTRACTS.md](../api/API-CONTRACTS.md)
