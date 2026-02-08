# API CONTRACT — v1

Ce document décrit le **contrat API v1** de Retaia Core.

Cette spécification est **normative**. Toute implémentation serveur, agent ou client doit s’y conformer strictement.

Le fichier `openapi/v1.yaml` est la description contractuelle exécutable et fait foi en cas de divergence.
Ce document doit rester strictement aligné avec `openapi/v1.yaml`.

Objectif : fournir une surface stable consommée par :

* UI web (same-origin, servie par Symfony)
* Retaia Agent(s)
* futurs clients (ex: client MCP)


## 0) Conventions

### Base

* Base path : `/api/v1`
* Identité : **UUID** partout
* Dates : ISO‑8601 UTC (`YYYY-MM-DDTHH:mm:ssZ`)
* Pagination : `limit` + `cursor`
* Idempotence : header `Idempotency-Key` sur endpoints critiques

### Idempotence (règles strictes)

Endpoints avec `Idempotency-Key` obligatoire :

* `POST /assets/{uuid}/reprocess`
* `POST /assets/{uuid}/decision`
* `POST /batches/moves` (`mode=EXECUTE`)
* `POST /decisions/apply`
* `POST /assets/{uuid}/purge`
* `POST /jobs/{job_id}/submit`
* `POST /jobs/{job_id}/fail`
* `POST /assets/{uuid}/derived/upload/init`
* `POST /assets/{uuid}/derived/upload/complete`

Comportement :

* même `(actor, method, path, key)` et même body : même réponse rejouée
* même clé mais body différent : `409 IDEMPOTENCY_CONFLICT`
* durée de rétention des clés : 24h (configurable)

### Derived URLs

* URLs de dérivés **stables** (same-origin)
* Accès contrôlé par session cookie (UI) ou bearer token (clients autorisés)

### États (doit matcher [STATE-MACHINE.md](../state-machine/STATE-MACHINE.md))

`DISCOVERED, READY, PROCESSING_REVIEW, PROCESSED, DECISION_PENDING, DECIDED_KEEP, DECIDED_REJECT, MOVE_QUEUED, ARCHIVED, REJECTED, PURGED`


## 1) Auth

### UI (humain)

* Session cookie HttpOnly (same-origin)
* CSRF sur méthodes mutantes

### Agents / MCP

* Bearer token

#### Scopes (base)

* `assets:read`
* `assets:write` (**humain uniquement**) — tags/fields/notes humains
* `decisions:write` (**humain uniquement**)
* `jobs:claim` (**agents uniquement**)
* `jobs:heartbeat` (**agents uniquement**)
* `jobs:submit` (**agents uniquement**)
* `suggestions:write` (agents/MCP)
* `batches:execute` (**humain uniquement**)
* `purge:execute` (**humain uniquement**)

La matrice normative endpoint x scope x état est définie dans [`AUTHZ-MATRIX.md`](../policies/AUTHZ-MATRIX.md).


## 2) Assets

### GET `/assets`

Liste filtrable/paginée des assets.

Query params (exemples) :

* `state=DECISION_PENDING` (multi)
* `media_type=VIDEO|PHOTO|AUDIO`
* `has_proxy=true`
* `tags=foo,bar` (tags **humains** uniquement)
* `tags_mode=AND|OR` (défaut: AND)
* `suggested_tags=foo,bar` (**v1.1+**, suggestions uniquement)
* `suggested_tags_mode=AND|OR` (**v1.1+**, défaut: AND)
* `q=texte` (optionnel, recherche full-text sur `filename`, `notes`, `transcript_text`)
* `sort=-created_at`
* `limit=50&cursor=...`

Règles `q=` :

* matching case-insensitive
* `q` ne modifie pas la sémantique des filtres (`state`, `media_type`, etc.)
* tri par défaut conservé (`sort`) ; pas de score implicite exposé en v1

Response :

* `items: AssetSummary[]`
* `next_cursor`

### GET `/assets/{uuid}`

Fiche détaillée d’un asset.

Response : `AssetDetail`

### PATCH `/assets/{uuid}` (humain)

Modifications humaines : tags/notes/custom fields.

Body (exemple) :

* `tags: string[]`
* `notes: string`
* `fields: Record<string, any>`

Règles :

* refuse si `state == PURGED`

### POST `/assets/{uuid}/reprocess` (humain)

Déclenche un reprocess explicite.

Effet (normatif) :

* autorisé uniquement si `state in {PROCESSED, ARCHIVED, REJECTED}`
* invalide les données de processing (facts, dérivés, transcript, suggestions) via version bump
* transition vers `READY`
* force la revue : retour à `DECISION_PENDING` après nouveau `PROCESSED`


## 3) Decisions (humain)

### POST `/assets/{uuid}/decision`

Body :

* `action: KEEP | REJECT | CLEAR`

Règles (strictes) :

* `KEEP/REJECT` : si `state in {DECISION_PENDING, DECIDED_KEEP, DECIDED_REJECT}`
* `CLEAR` : uniquement si `state in {DECIDED_KEEP, DECIDED_REJECT}`

### POST `/assets/{uuid}/reopen`

Effet :

* `ARCHIVED|REJECTED → DECISION_PENDING`


## 4) Agents

### POST `/agents/register`

Enregistre un agent (optionnel mais recommandé).

Body :

* `agent_name`
* `agent_version`
* `platform`
* `capabilities: string[]` (voir [`CAPABILITIES.md`](../definitions/CAPABILITIES.md))
* `max_parallel_jobs` (suggestion)

Response :

* `agent_id`
* `server_policy` (quotas et règles serveur), incluant au minimum :

  * `min_poll_interval_seconds`
  * `max_parallel_jobs_allowed`
  * `allowed_job_types[]`
  * (optionnel) `quiet_hours`


## 5) Jobs

### Règles générales

* Les agents sont considérés comme **non fiables**.
* Les jobs sont **idempotents**.
* Un job peut rester **`pending` indéfiniment** s’il n’existe aucun agent disponible avec les capabilities requises.
* Un job `pending` n’est ni une erreur, ni un état bloqué.

### GET `/jobs`

Retourne les jobs `pending` compatibles avec l’agent authentifié (capabilities + policy serveur).

Response :

* `Job[]`

Règles :

* ne jamais retourner un asset `MOVE_QUEUED`
* le serveur peut limiter la liste (pagination, quotas)

### POST `/jobs/{job_id}/claim`

Claim atomique d’un job.

Response :

* `200` + `Job` (avec `lock_token`, `locked_until`) si claim accepté
* `409 STATE_CONFLICT` si job déjà claimé, non compatible ou non claimable

Règles :

* lock + TTL obligatoires

### POST `/jobs/{job_id}/heartbeat`

Body :

* `lock_token`

Response :

* `locked_until`

### POST `/jobs/{job_id}/submit`

Body :

* `lock_token`
* `job_type`
* `result: ProcessingResultPatch`

Effets :

* `extract_facts | generate_proxy | generate_thumbnails | generate_audio_waveform` :
  mise à jour des domaines `facts/derived`, puis `PROCESSING_REVIEW → PROCESSED → DECISION_PENDING` quand le profil est complet
* `transcribe_audio` : mise à jour du domaine `transcript`
* `suggest_tags` : mise à jour du domaine `suggestions`

Note v1 (important) :

* `ProcessingResultPatch` ne transporte pas les binaires.
* Les binaires (proxies/thumbs/waveforms) sont uploadés via l’API Derived.
* `submit` référence les dérivés déjà uploadés.
* Le serveur applique un merge partiel par domaine ; un job ne peut pas écraser les domaines qu'il ne possède pas.
* ownership de patch par `job_type` :
  * `extract_facts` -> `facts_patch`
  * `generate_proxy|generate_thumbnails|generate_audio_waveform` -> `derived_patch`
  * `transcribe_audio` -> `transcript_patch`
  * `suggest_tags` -> `suggestions_patch`

### POST `/jobs/{job_id}/fail`

Body :

* `lock_token`
* `error_code`
* `message`
* `retryable: boolean`


## 6) Derived (proxies/dérivés)

Principe v1 :

* les dérivés sont **uploadés via HTTP** par les agents
* l’UI y accède via HTTP (URLs stables), pas via SMB

### POST `/assets/{uuid}/derived/upload/init`

Initialise un upload (permet chunking / reprise).

Body (exemple) :

* `kind: proxy_video | proxy_audio | proxy_photo | thumb | waveform`
* `content_type`
* `size_bytes`
* `sha256?` (optionnel)

Response :

* `upload_id`
* `upload_url` (ou liste de parts si multi-part)
* `max_part_size_bytes`

### POST `/assets/{uuid}/derived/upload/part`

Upload d’une part (si chunking).

Body :

* `upload_id`
* `part_number`
* payload binaire (transport à préciser côté implémentation)

Response :

* `etag` (ou checksum)

### POST `/assets/{uuid}/derived/upload/complete`

Finalise l’upload.

Body :

* `upload_id`
* `parts[]` (si multipart)

Effet :

* le serveur stocke le dérivé dans `RUSHES_DB/.derived/{uuid}/...`
* référence interne mise à jour

### GET `/assets/{uuid}/derived`

Retourne les dérivés disponibles et leurs URLs.

### GET `/assets/{uuid}/derived/{kind}`

`kind = proxy_video | proxy_audio | proxy_photo | thumb | waveform`

Règles :

* support Range requests pour proxies
* 404 si `state == PURGED`


## 7) Batch moves

### POST `/batches/moves/preview`

Retourne un plan de move (dry-run).

Body :

* `include: KEEP | REJECT | BOTH`
* `limit?`

Response :

* `eligible[]`
* `collisions[]`
* `blocked[]`
* `summary`

### POST `/batches/moves`

Crée (et éventuellement exécute) un batch.

Body :

* `selection` (ids depuis preview ou critères)
* `mode: DRY_RUN | EXECUTE`

Response :

* `batch_id`
* `status`

### GET `/batches/moves/{batch_id}`

Retourne statut + rapport.

### Règles d'exécution batch move

* seuls les assets `DECIDED_KEEP` et `DECIDED_REJECT` sont éligibles
* lock exclusif par asset (fichier/rush) pendant l'opération filesystem
* release du lock asset après opération filesystem et avant transition d'état
* suffixe de collision obligatoire : `__{short_nonce}`
* un asset locké pour move n'est pas claimable pour processing
* `short_nonce` suit la spec [`NAMING-AND-NONCE.md`](../policies/NAMING-AND-NONCE.md)


## 7.1) Bulk decisions (v1.1)

Objectif : permettre à un client (ex: MCP) de **préparer** une action de décision en masse, sans laisser l’automatisation décider silencieusement.

Principe :

* étape 1 : preview (liste + impact + token)
* étape 2 : apply (confirmation explicite)

### POST `/decisions/preview` (v1.1)

Body :

* `action: KEEP | REJECT`
* `filter: { state, tags, tags_mode: AND|OR, media_type?, has_proxy? }`
* `max_items` (obligatoire)

Response :

* `approval_token` (one-shot)
* `eligible_uuids[]`
* `blocked[]` (uuid + reason)
* `summary`

Règles :

* seuls les assets `DECISION_PENDING` sont éligibles
* `max_items` est obligatoire et plafonné par policy serveur

### POST `/decisions/apply` (v1.1)

Body :

* `approval_token`
* `confirm: true`

Effet :

* transitions de tous les assets éligibles vers `DECIDED_KEEP` ou `DECIDED_REJECT`

Règles :

* nécessite `decisions:write`
* `approval_token` expire rapidement
* l’apply est idempotent (Idempotency-Key)


## 8) Purge (destructif)

### POST `/assets/{uuid}/purge/preview`

Prévisualise la purge.

### POST `/assets/{uuid}/purge`

Exécute la purge.

Body :

* `confirm: true`

Effet :

* `REJECTED → PURGED`
* supprime originaux + sidecars + dérivés

## 8.1) Concurrence & verrous (normatif)

* `MOVE_QUEUED` interdit : claim job, reprocess, reopen, decision write, purge
* `PURGED` interdit toute mutation
* `reprocess` est refusé si un lock move est actif sur l'asset
* `purge` est refusé si un job est `claimed` pour l'asset
* claim job : atomique, lease TTL obligatoire, heartbeat obligatoire pour jobs longs
* cycle de vie détaillé des verrous défini dans [`LOCK-LIFECYCLE.md`](../policies/LOCK-LIFECYCLE.md)


## 9) Schémas (objets)

### AssetSummary

* `uuid`
* `media_type`
* `state`
* `created_at`
* `captured_at?`
* `duration?`
* `tags[]`
* `has_proxy`
* `thumb_url?`

### AssetDetail

* `summary: AssetSummary`
* `paths: { original_relative, sidecars_relative[] }`
* `processing: { facts_done, thumbs_done, proxy_done, waveform_done, review_processing_version }`
* `derived: { proxy_video_url?, proxy_audio_url?, waveform_url?, thumbs[] }`
* `transcript: { status, text_preview?, updated_at? }`
* `suggestions: { status, tags_suggested[], source? }`
* `decisions: { current?, history[] }`
* `audit: { path_history[] }`

### Job

* `job_id`
* `job_type` (`extract_facts | generate_proxy | generate_thumbnails | generate_audio_waveform | transcribe_audio | suggest_tags`)
* `asset_uuid`
* `lock_token`
* `locked_until`
* `paths`
* `derived_target_dir`

### ProcessingResultPatch

* `facts_patch?` (JSON partiel)
* `derived_patch?` (`derived_manifest` partiel)
* `transcript_patch?`
* `suggestions_patch?`
* `warnings[]`
* `metrics`

Règles :

* merge par domaine uniquement (pas de replace global)
* un job ne peut mettre à jour que son domaine autorisé
* toute clé hors domaine autorisé renvoie `422 VALIDATION_FAILED`


## 10) Codes d’erreur (normatifs)

* `409 STATE_CONFLICT`
* `409 IDEMPOTENCY_CONFLICT`
* `423 LOCK_REQUIRED` / `LOCK_INVALID`
* `410 PURGED`
* `422 VALIDATION_FAILED`
* `429 RATE_LIMITED`
* `503 TEMPORARY_UNAVAILABLE`

Le payload d’erreur normatif est défini dans [`ERROR-MODEL.md`](ERROR-MODEL.md).


## 11) Décisions actées (v1)

* URLs de dérivés : stables (same-origin)
* Claim jobs : `GET /jobs` pour discovery + `POST /jobs/{job_id}/claim` pour lease atomique
* Dérivés : upload HTTP, pas d’écriture directe côté client sur le filesystem NAS
* Batch move : sélection v1 via ids depuis preview, lock par asset
* Purge : purge unitaire v1 (+ batch purge plus tard si nécessaire)
* Scopes : agents strictement limités aux scopes jobs/suggestions, jamais décisions/moves/purge
* Filtres `tags=` : tags humains uniquement
* Changement de décision KEEP/REJECT autorisé de façon directe
* Reprocess autorisé depuis `PROCESSED|ARCHIVED|REJECTED`

## 12) Décisions actées (v1.1)

* Introduction de `suggested_tags=` et `suggested_tags_mode=`
* Bulk decisions via preview/apply (`/decisions/preview`, `/decisions/apply`)

## 13) Points en suspens

* Batch purge : si nécessaire plus tard

## Références associées

* [STATE-MACHINE.md](../state-machine/STATE-MACHINE.md)
* [JOB-TYPES.md](../definitions/JOB-TYPES.md)
* [PROCESSING-PROFILES.md](../definitions/PROCESSING-PROFILES.md)
* [SIDECAR-RULES.md](../definitions/SIDECAR-RULES.md)
* [CAPABILITIES.md](../definitions/CAPABILITIES.md)
* [AGENT-PROTOCOL.md](../workflows/AGENT-PROTOCOL.md)
* [LOCKING-MATRIX.md](../policies/LOCKING-MATRIX.md)
* [LOCK-LIFECYCLE.md](../policies/LOCK-LIFECYCLE.md)
* [NAMING-AND-NONCE.md](../policies/NAMING-AND-NONCE.md)
* [AUTHZ-MATRIX.md](../policies/AUTHZ-MATRIX.md)
* [HOOKS-CONTRACT.md](../policies/HOOKS-CONTRACT.md)
* [ERROR-MODEL.md](ERROR-MODEL.md)
