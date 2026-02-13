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
* source_path (read-only)

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
* source_path (read-only)
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
* source_path (read-only)
* thumbnail_profile

**Expected outputs**

* thumbnails[]

**Invariants**

* aucune modification du média original
* outputs entièrement recréables

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
* source_path (read-only)

**Expected outputs**

* waveform_data

**Invariants**

* aucune modification du média original
* output dérivable à l’identique

**Failure modes**

* piste audio absente → fatal


### 3.5 `transcribe_audio`

Disponibilité : **v1+**.

Ce job peut rester indéfiniment en statut pending tant qu’aucun agent ne déclare la capability requise.

**Objectif**  
Produire une transcription (et éventuellement des timecodes) à partir de l’audio d’un média, uniquement pour les profils qui l'exigent.

**Required capabilities**

* `speech.transcription@1`

**Inputs**

* asset_uuid
* source_path (read-only)
* language (optionnel)
* transcription_profile (optionnel)

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


### 3.6 `suggest_tags`

Disponibilité : **v1.1+** (AI-powered).

**Objectif**  
Produire des suggestions de tags à partir des facts/transcript/metadata.

**Required capabilities**

* `meta.tags.suggestions@1`
* `llm.client.ollama@1`
* `llm.client.chatgpt@1`
* `llm.client.anthropic@1`

**Inputs**

* asset_uuid
* facts_ref
* transcript_ref (optionnel)
* suggestion_profile (optionnel)
* llm_provider (optionnel, runtime policy; valeurs: `ollama|chatgpt|anthropic`)

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
