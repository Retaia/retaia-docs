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

**Invariants**

* aucune modification du média original
* output entièrement recréable

**Failure modes**

* source illisible → fatal
* timeout/OOM → retryable


### 3.2 `generate_proxy`

**Objectif**  
Générer un proxy de review (video, audio ou image) selon le type média.

**Required capabilities**

* `media.proxies.video@1` (VIDEO)
* `media.proxies.audio@1` (AUDIO)
* `media.proxies.photo@1` (PHOTO)

**Inputs**

* asset_uuid
* source_locator (read-only: `storage_id`, `original_relative`, `sidecars_relative[]`)
* media_type
* proxy_profile

**Expected outputs**

* derived_manifest[] (kind + référence upload)

**Invariants**

* aucune modification du média original
* aucun déplacement de fichier
* outputs entièrement recréables

**Failure modes**

* source illisible → fatal
* erreur d’encodage/rendu → retryable


### 3.3 `generate_thumbnails`

**Objectif**  
Générer des vignettes à partir d’un média.

**Required capabilities**

* `media.thumbnails@1`

**Inputs**

* asset_uuid
* source_locator (read-only: `storage_id`, `original_relative`, `sidecars_relative[]`)
* thumbnail_profile

`thumbnail_profile` (normatif) :

* mode par défaut vidéo : `representative_frame`
* mode optionnel : `storyboard`
* vidéo courte : durée strictement inférieure à `120s`
* vidéo longue : durée supérieure ou égale à `120s`
* vidéo courte : frame de référence à `max(1s, 10% de la durée)`
* vidéo longue : frame de référence à `5% de la durée`, avec fallback à `20s` si `5% > 20s`
* le moteur DOIT éviter les frames noires ou de fondu si une heuristique légère permet d'en sélectionner une voisine plus représentative
* mode `storyboard` : produire `10` thumbs répartis de manière régulière sur la durée utile, incluant la frame représentative principale
* les thumbs storyboard DOIVENT être triés chronologiquement
* une légère marge de sécurité aux extrémités du média est autorisée pour éviter des frames d'ouverture/fermeture non représentatives
* pour une image fixe, le thumb est dérivé directement de l'image source
* pour un audio sans image, aucun thumb temporel n'est requis; seul le proxy/waveform couvre la review

**Expected outputs**

* thumbnails[]

`thumbnails[]` (minimum normatif) :

* en mode vidéo par défaut : au moins un thumb `representative`
* en mode `storyboard` : exactement `10` thumbs vidéo DOIVENT être produits
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

**Invariants**

* aucune modification du média original
* output dérivable à l’identique

**Failure modes**

* piste audio absente → fatal


### 3.5 `transcribe_audio`

Disponibilité : **v1.1+** (activable plus tôt sous `feature_flags` pendant le développement et la pré-release).

Ce job peut rester indéfiniment en statut pending tant qu’aucun agent ne déclare la capability requise.

**Objectif**  
Produire une transcription (et éventuellement des timecodes) à partir de l’audio d’un média. À partir de la phase `v1.1+` validée, ce job devient requis pour tout média avec piste audio exploitable afin d'atteindre `PROCESSED`.

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
* timeout / OOM → retryable (selon policy serveur)
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
* suggestion_profile (optionnel)
* llm_provider (optionnel, runtime policy; valeurs: `ollama|chatgpt|claude`)
* llm_model (recommandé; valeur issue du catalogue runtime choisi par l'utilisateur)

**Expected outputs**

* suggested_tags[]
* source (model, profile_version, etc.)

**Invariants**

* aucune décision KEEP / REJECT
* aucune modification automatique des tags humains

**Failure modes**

* modèle indisponible → retryable
* entrée insuffisante → failed non bloquant
* provider indisponible → fallback provider ou retryable selon policy serveur
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
