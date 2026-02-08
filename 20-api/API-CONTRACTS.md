# API CONTRACT — v1

Ce document décrit le **contrat API v1** de RushCatalog.

Objectif : fournir une surface stable consommée par :

* UI web (same-origin, servie par Symfony)
* RushIndexer Agent(s)
* futurs clients (ex: client MCP)


Cette spécification OpenAPI est **normative**.
Toute implémentation serveur ou agent doit s’y conformer strictement.
---

## 0) Conventions

### Base

* Base path : `/api/v1`
* Identité : **UUID** partout (jamais de path comme identité)
* Dates : ISO-8601 UTC (`YYYY-MM-DDTHH:mm:ssZ`)
* Pagination : `limit` + `cursor`
* Idempotence : header `Idempotency-Key` sur endpoints critiques

### Derived URLs

* URLs de dérivés **stables** (Option A same-origin)
* Accès contrôlé par session cookie (UI) ou token (clients autorisés)

### États (doit matcher STATE-MACHINE.md)

`DISCOVERED, READY, PROCESSING_REVIEW, PROCESSED, DECISION_PENDING, DECIDED_KEEP, DECIDED_REJECT, MOVE_QUEUED, ARCHIVED, REJECTED, PURGED`

---

## 1) Auth

### UI (humain)

* Session cookie HttpOnly (same-origin)
* CSRF sur méthodes mutantes

### Agents / MCP

* Bearer token

#### Scopes (base)

* `assets:read`

* `assets:write` (tags/fields/notes humains — **interdit aux agents**)

* `decisions:write` (**humain uniquement**)

* `jobs:claim` (**agents uniquement**)

* `jobs:heartbeat` (**agents uniquement**)

* `jobs:submit` (**agents uniquement**)

* `suggestions:write` (agents/MCP)

* `batches:execute` (**humain uniquement**)

* `purge:execute` (**humain uniquement**)

* `assets:read`

* `assets:write` (tags/fields/notes humains)

* `decisions:write`

* `jobs:claim`

* `jobs:heartbeat`

* `jobs:submit`

* `suggestions:write`

* `batches:execute`

* `purge:execute`

---

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
* `q=texte` (optionnel)
* `sort=-created_at`
* `limit=50&cursor=...`

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

* invalide facts/dérivés (version bump)
* transition vers `READY`
* force la revue : retour à `DECISION_PENDING` après nouveau `PROCESSED`

---

## 3) Decisions (humain)

### POST `/assets/{uuid}/decision`

Body :

* `action: KEEP | REJECT | CLEAR`

Règles (strictes) :

* `KEEP/REJECT` : uniquement si `state == DECISION_PENDING`
* `CLEAR` : uniquement si `state in {DECIDED_KEEP, DECIDED_REJECT}`

### POST `/assets/{uuid}/reopen`

Effet :

* `ARCHIVED|REJECTED → DECISION_PENDING`

---

## 4) Agents

### POST `/agents/register`

Enregistre un agent (optionnel mais recommandé).

Body :

* `agent_name`
* `agent_version`
* `platform`
* `capabilities: { review_processing: boolean, transcribe: boolean, suggest_tags: boolean }`
* `max_parallel_jobs` (suggestion)

Response :

* `agent_id`

* `server_policy` (quotas et règles serveur), incluant au minimum :

    * `min_poll_interval_seconds`
    * `max_parallel_jobs_allowed`
    * `allowed_job_types[]`
    * (optionnel) `quiet_hours`

* `agent_id`

* `server_policy` (quotas, intervalles)

---

## 5) Jobs

### POST `/jobs/claim`

Claim un job.

Body :

* `job_type: PROCESS_REVIEW | TRANSCRIBE | SUGGEST_TAGS`
* `agent_id`

Response :

* `Job` si un job est attribué
* sinon : `200 { job: null, retry_after_seconds: number }`

Règles :

* ne jamais retourner un asset `MOVE_QUEUED`
* lock + TTL obligatoires

Règles :

* ne jamais retourner un asset `MOVE_QUEUED`
* lock + TTL obligatoires

### POST `/jobs/{job_id}/heartbeat`

Body :

* `lock_token`

Response :

* `locked_until`

### POST `/jobs/{job_id}/submit`

Body :

* `lock_token`
* `result: ProcessingResult`

Effets :

* `PROCESS_REVIEW` : `PROCESSING_REVIEW → PROCESSED → DECISION_PENDING` (après validation des garanties)
* `TRANSCRIBE` : mise à jour `transcript_status`
* `SUGGEST_TAGS` : mise à jour `suggestions_status`

Note v1 (important) :

* `ProcessingResult` ne transporte pas les binaires.
* Les binaires (proxies/thumbs/waveforms) sont uploadés via l’API Derived.
* `submit` référence les dérivés déjà uploadés.

### POST `/jobs/{job_id}/fail`

Body :

* `lock_token`
* `error_code`
* `message`
* `retryable: boolean`

---

## 6) Derived (proxies/dérivés)

Principe v1 :

* les dérivés sont **uploadés via HTTP** par les agents
* l’UI y accède via HTTP (URLs stables), pas via SMB

### POST `/assets/{uuid}/derived/upload/init`

Initialise un upload (permet chunking / reprise).

Body (exemple) :

* `kind: proxy_video | proxy_audio | thumb | waveform`
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

`kind = proxy_video | proxy_audio | thumb | waveform`

Règles :

* support Range requests pour proxies
* 404 si `state == PURGED`

---

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

---

## 7.1) Bulk decisions (v1.1)

Objectif : permettre à un client (ex: MCP) de **préparer** une action de décision en masse, sans laisser l’automatisation décider silencieusement.

Principe :

* étape 1 : preview (liste + impact + token)
* étape 2 : apply (confirmation explicite)

### POST `/decisions/preview` (v1.1)

Prépare une décision en masse.

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

Applique la décision après confirmation.

Body :

* `approval_token`
* `confirm: true`

Effet :

* transitions de tous les assets éligibles vers `DECIDED_KEEP` ou `DECIDED_REJECT`

Règles :

* nécessite `decisions:write`
* `approval_token` expire rapidement
* l’apply est idempotent (Idempotency-Key)

---

## 8) Purge (destructif) (destructif)

### POST `/assets/{uuid}/purge/preview`

Prévisualise la purge.

### POST `/assets/{uuid}/purge`

Exécute la purge.

Body :

* `confirm: true`

Effet :

* `REJECTED → PURGED`
* supprime originaux + sidecars + dérivés

---

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
* `job_type`
* `asset_uuid`
* `lock_token`
* `locked_until`
* `paths`
* `derived_target_dir`

### ProcessingResult

* `facts` (JSON)
* `derived_manifest` (liste des dérivés attendus/produits avec leurs `kind` et références serveur)
* `transcript?`
* `suggestions?`
* `warnings[]`
* `metrics`

---

## 10) Codes d’erreur (normatifs)

* `409 STATE_CONFLICT`
* `423 LOCK_REQUIRED` / `LOCK_INVALID`
* `410 PURGED`
* `422 VALIDATION_FAILED`
* `429 RATE_LIMITED`
* `503 TEMPORARY_UNAVAILABLE`

---

## 11) Décisions actées (v1)

* URLs de dérivés : **stables** (Option A same-origin)
* Claim jobs : réponse **200 + retry_after_seconds** si aucun job
* Dérivés : **upload HTTP**, pas d’écriture directe côté client sur le filesystem NAS
* Batch move : sélection v1 via **ids depuis preview**
* Purge : purge unitaire v1 (+ batch purge plus tard si nécessaire)
* Scopes : agents strictement limités aux scopes jobs/suggestions, jamais décisions/moves/purge
* Filtres `tags=` : **tags humains uniquement**

## 12) Décisions actées (v1.1)

* Introduction de `suggested_tags=` et `suggested_tags_mode=` (filtres distincts)
* Bulk decisions via preview/apply (`/decisions/preview`, `/decisions/apply`)

## 13) Points en suspens

* Full-text search : `q=` en v1 (si oui, préciser le comportement exact)
* Reprocess + décisions existantes : règle exacte si l’asset était déjà `DECIDED_*` (actuellement : reprocess ne réapplique pas la décision automatiquement)
* Bulk decisions : la v1.1 introduit preview/apply (ci-dessus).
