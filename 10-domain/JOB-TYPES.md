# Job Types — Processing Pipeline

Ce document définit les **types de jobs** que le serveur RushCatalog peut créer et confier aux agents de processing.

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

### 3.1 `generate_video_proxies`

**Objectif**
Générer des proxies vidéo à partir d’un média source.

**Required capabilities**

* `media.proxies.video@1`

**Inputs**

* asset_uuid
* source_path (read-only)
* proxy_profile

**Expected outputs**

* proxy_files[]
* technical_metadata

**Invariants**

* aucune modification du média original
* aucun déplacement de fichier
* outputs entièrement recréables

**Failure modes**

* source illisible → fatal
* erreur d’encodage → retryable


### 3.2 `generate_thumbnails`

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


### 3.3 `generate_audio_waveform`

**Objectif**
Extraire une waveform audio.

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


### 3.4 `transcribe_audio`

Ce job peut rester indéfiniment en statut pending tant qu’aucun agent ne déclare la capability requise.

**Objectif**  
Produire une transcription (et éventuellement des timecodes) à partir de l’audio d’un média.

**Required capabilities**
- `speech.transcription@1`

**Inputs**
- asset_uuid
- source_path (read-only)
- language (optionnel)
- transcription_profile (optionnel)

**Expected outputs**
- transcript_text
- segments[] (optionnel : start_ms, end_ms, text)
- confidence (optionnel)

**Invariants**
- aucune modification du média original
- aucune décision KEEP / REJECT
- output recréable (si le moteur change de manière non rétrocompatible, incrémenter la version de capability)

**Failure modes**
- pas de piste audio → fatal
- timeout / OOM → retryable (selon policy serveur)
- moteur indisponible → retryable


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
