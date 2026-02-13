# API CONTRACT — v1

Ce document décrit le **contrat API v1** de Retaia Core.

Cette spécification est **normative**. Toute implémentation serveur, agent ou client doit s’y conformer strictement.

Le fichier `openapi/v1.yaml` est la description contractuelle exécutable et fait foi en cas de divergence.
Ce document doit rester strictement aligné avec `openapi/v1.yaml`.

Objectif : fournir une surface stable consommée par :

* client UI (`UI_RUST`, Rust/Tauri)
* client Agent
* client MCP


## 0) Conventions

### Base

* Base path : `/api/v1`
* Identité : **UUID** partout
* Dates : ISO‑8601 UTC (`YYYY-MM-DDTHH:mm:ssZ`)
* Pagination : `limit` + `cursor`
* Idempotence : header `Idempotency-Key` sur endpoints critiques

### Versioning mineur (v1 / v1.1)

* `v1` = socle stable (ingestion, processing review, transcription, décision humaine, moves, purge, recherche full-text `q`).
* `v1.1` = extensions compatibles.
* Toute fonctionnalité AI-powered (ex: `suggest_tags`, filtres `suggested_tags*`) est `v1.1+`.
* Exception explicite : `transcribe_audio` est disponible dès `v1`.

### Feature flags (normatif)

* Source de vérité : les flags sont pilotés par **Retaia Core** au runtime. Les clients (UI, agents, MCP) NE DOIVENT PAS hardcoder un état de flag.
* Toute nouvelle fonctionnalité DOIT être protégée par un feature flag serveur dès son introduction.
* Les fonctionnalités `v1.1+` suivent la même règle et restent inactives tant que leur flag n'est pas activé.
* Convention de nommage : `features.<domaine>.<fonction>` (ex: `features.ai.suggest_tags`).
* Contrat de transport : l’état effectif des flags DOIT être transporté dans un payload standard `server_policy.feature_flags` (au minimum via `POST /agents/register`).
* Distinction normative (sans ambiguïté) :
  * `feature_flags` = activation runtime des fonctionnalités côté Core
  * `capabilities` = aptitudes techniques déclarées par les agents pour exécuter des jobs
  * `contracts/` = snapshots versionnés pour détecter un drift du contrat OpenAPI
* Sémantique stricte :
  * flag absent = `false`
  * flag inconnu côté client = ignoré
  * comportement safe-by-default : sans signal explicite `true` renvoyé par Core, la feature reste indisponible
* Quand un flag est `false`, l’endpoint reste stable et la feature est refusée de façon explicite (`403 FORBIDDEN_SCOPE` ou `409 STATE_CONFLICT` selon le cas).
* L’activation d’un flag ne DOIT pas modifier le comportement des fonctionnalités `v1`.

Mapping normatif v1.1 (base actuelle, obligatoire pour tous les consommateurs) :

* `features.ai.suggest_tags` :
  * autorise `job_type=suggest_tags` sur `POST /jobs/{job_id}/submit`
  * autorise `suggestions_patch`
  * autorise le bloc `suggestions` dans `AssetDetail`
  * client: OFF => ne pas afficher/exécuter les actions liées à la suggestion AI ; ON => disponible sans redéploiement
* `features.ai.suggested_tags_filters` :
  * autorise les query params `suggested_tags`, `suggested_tags_mode` sur `GET /assets`
  * client: OFF => ne pas exposer ces filtres ni les envoyer ; ON => disponible sans redéploiement
* `features.decisions.bulk` :
  * autorise `POST /decisions/preview` et `POST /decisions/apply`
  * client: OFF => interdire toute UI/action bulk decisions et tout appel API associé ; ON => disponible sans redéploiement

Règles client (normatives, UI/agents/MCP) :

* feature OFF => appel API de la feature interdit et UI correspondante masquée/désactivée
* feature ON => feature disponible immédiatement, sans déploiement client supplémentaire
* `UI_RUST`, `AGENT` et `MCP` DOIVENT tous consommer les `feature_flags` runtime pilotés par Core
* aucun client ne DOIT hardcoder l’état d’un flag ni dépendre d’un flag local statique
* toute décision de disponibilité fonctionnelle côté client DOIT être dérivée du dernier payload runtime reçu

### Idempotence (règles strictes)

Endpoints avec `Idempotency-Key` obligatoire :

* `POST /assets/{uuid}/reprocess`
* `POST /assets/{uuid}/decision`
* `POST /batches/moves` (`mode=EXECUTE`)
* `POST /decisions/apply` (**v1.1+**)
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
* Accès contrôlé par bearer token (`Authorization: Bearer ...`) pour tous les clients

### États (doit matcher [STATE-MACHINE.md](../state-machine/STATE-MACHINE.md))

`DISCOVERED, READY, PROCESSING_REVIEW, PROCESSED, DECISION_PENDING, DECIDED_KEEP, DECIDED_REJECT, MOVE_QUEUED, ARCHIVED, REJECTED, PURGED`

Dans `openapi/v1.yaml`, les états sont typés via un enum strict (`AssetState`).


## 1) Auth

### Typologie des acteurs (normatif)

* `USER_INTERACTIVE` : utilisateur humain connecté via client `UI_RUST` (Rust/Tauri) ou client `AGENT` en mode interactif
* `CLIENT_TECHNICAL` : client non-humain authentifié par `client_id + secret_key`
* `AGENT_TECHNICAL` : agent non-interactif (daemon/service) authentifié par `client_id + secret_key` ou client-credentials OAuth2
* `client_kind` interactif est borné à `UI_RUST` ou `AGENT`; le mode technique autorise `AGENT` et `MCP`

### UI (humain)

* Bearer token utilisateur obtenu via login (`POST /auth/login`)
* l'interface de login est normative pour permettre l'obtention du token utilisateur
* le `client_kind=UI_RUST` DOIT être implémenté en Rust/Tauri (Electron non supporté)
* le token UI est non exportable dans l'interface (jamais affiché en clair)
* un utilisateur ne peut pas invalider son token UI depuis l'UI (anti lock-out)
* l'UI DOIT supporter l'enrôlement 2FA TOTP via app externe (Authy, Google Authenticator, etc.)

### Agents / MCP

* modes non interactifs : bearer technique (`OAuth2ClientCredentials`)
* modes interactifs (agent CLI/GUI opéré par un humain) : bearer utilisateur via `POST /auth/login`
* mode client applicatif non-interactif (`AGENT`, `MCP`) : `client_id + secret_key` pour obtenir un bearer token via `POST /auth/clients/token`

Règles 2FA par client (obligatoire) :

* la 2FA est optionnelle au niveau compte utilisateur
* `UI_RUST` : login utilisateur (`/auth/login`) avec 2FA obligatoire uniquement si activée sur le compte
* `AGENT` / `MCP` en mode technique (`/auth/clients/token`) : pas de 2FA directe au runtime
* création d’un `secret_key` pour `AGENT`/`MCP` : DOIT passer par une validation utilisateur via UI
* si 2FA est activée sur ce compte utilisateur, la validation UI de création `secret_key` DOIT exiger la 2FA
* flow cible pour `AGENT`/`MCP` : type GitHub device authorization (ouverture URL navigateur, auth UI, validation 2FA optionnelle, approval explicite)

Règle de cardinalité des tokens (obligatoire) :

* `USER_INTERACTIVE` : un même utilisateur PEUT avoir plusieurs tokens actifs simultanément sur des clients différents, avec contrainte stricte **1 token actif par `(user_id, client_id)`**
* `CLIENT_TECHNICAL` / `AGENT_TECHNICAL` : contrainte stricte **1 token actif par `client_id`**
* émission d'un nouveau token pour la même clé de cardinalité => révocation immédiate du token précédent

#### Scopes (base)

* `assets:read`
* `assets:write` (**humain uniquement**) — tags/fields/notes humains
* `decisions:write` (**humain uniquement**)
* `jobs:claim` (**agents uniquement**)
* `jobs:heartbeat` (**agents uniquement**)
* `jobs:submit` (**agents uniquement**)
* `suggestions:write` (**v1.1+**, agents/MCP)
* `batches:execute` (**humain uniquement**)
* `purge:execute` (**humain uniquement**)

La matrice normative endpoint x scope x état est définie dans [`AUTHZ-MATRIX.md`](../policies/AUTHZ-MATRIX.md).
`openapi/v1.yaml` déclare explicitement les schémas de sécurité (`UserBearerAuth`, `OAuth2ClientCredentials`) et les scopes requis par endpoint.

Migration obligatoire (anti dette technique) :

* `SessionCookieAuth` est retiré du contrat et est interdit pour toute nouvelle implémentation.
* Core DOIT supprimer le code runtime lié au cookie session auth (`SessionCookieAuth`).
* UI, Agent et MCP DOIVENT migrer vers Bearer-only et supprimer toute dépendance cookie.

### Endpoints auth applicatifs (normatif)

`POST /auth/login`

* security: aucune (`security: []`)
* body requis: `{ email, password }`
* body optionnel: `client_id`, `client_kind`, `otp_code` (`otp_code` obligatoire si 2FA active)
* réponses:
  * `200` succès + bearer token (`access_token`, `token_type=Bearer`, `expires_in?`, `refresh_token?`, `client_id`, `client_kind`)
  * `401 UNAUTHORIZED` (credentials invalides), `MFA_REQUIRED` (2FA active sans OTP), `INVALID_2FA_CODE` (OTP invalide)
  * `403 EMAIL_NOT_VERIFIED`
  * `422 VALIDATION_FAILED`
  * `429 TOO_MANY_ATTEMPTS`

`POST /auth/2fa/setup`

* security: `UserBearerAuth`
* effet: génère le matériel d'enrôlement TOTP (`secret`, `otpauth_uri`, `qr_svg?`) pour app externe
* réponses:
  * `200` setup généré
  * `401 UNAUTHORIZED`
  * `409 MFA_ALREADY_ENABLED`

`POST /auth/2fa/enable`

* security: `UserBearerAuth`
* body requis: `{ otp_code }`
* effet: active la 2FA TOTP pour l'utilisateur courant
* réponses:
  * `200` succès
  * `400 INVALID_2FA_CODE`
  * `401 UNAUTHORIZED`
  * `409 MFA_ALREADY_ENABLED`
  * `422 VALIDATION_FAILED`

`POST /auth/2fa/disable`

* security: `UserBearerAuth`
* body requis: `{ otp_code }`
* effet: désactive la 2FA TOTP pour l'utilisateur courant
* réponses:
  * `200` succès
  * `400 INVALID_2FA_CODE`
  * `401 UNAUTHORIZED`
  * `409 MFA_NOT_ENABLED`
  * `422 VALIDATION_FAILED`

`POST /auth/logout`

* security: `UserBearerAuth`
* réponses:
  * `200` succès
  * `401 UNAUTHORIZED`

`GET /auth/me`

* security: `UserBearerAuth`
* réponses:
  * `200` utilisateur courant
  * `401 UNAUTHORIZED`

`POST /auth/lost-password/request`

* security: aucune (`security: []`)
* body requis: `{ email }`
* réponses:
  * `202` accepté
  * `422 VALIDATION_FAILED`
  * `429 TOO_MANY_ATTEMPTS`

`POST /auth/lost-password/reset`

* security: aucune (`security: []`)
* body requis: `{ token, new_password }`
* réponses:
  * `200` succès
  * `400 INVALID_TOKEN`
  * `422 VALIDATION_FAILED`

`POST /auth/verify-email/request`

* security: aucune (`security: []`)
* body requis: `{ email }`
* réponses:
  * `202` accepté
  * `422 VALIDATION_FAILED`
  * `429 TOO_MANY_ATTEMPTS`

`POST /auth/verify-email/confirm`

* security: aucune (`security: []`)
* body requis: `{ token }`
* réponses:
  * `200` succès
  * `400 INVALID_TOKEN`
  * `422 VALIDATION_FAILED`

`POST /auth/verify-email/admin-confirm`

* security: `UserBearerAuth`
* prérequis authz: acteur admin (contrôlé par la matrice [`AUTHZ-MATRIX.md`](../policies/AUTHZ-MATRIX.md))
* body requis: `{ email }`
* réponses:
  * `200` succès
  * `403 FORBIDDEN_ACTOR` ou `FORBIDDEN_SCOPE` (selon matrice)
  * `404 USER_NOT_FOUND`
  * `422 VALIDATION_FAILED`

`POST /auth/clients/{client_id}/revoke-token`

* security: `UserBearerAuth`
* prérequis authz: acteur admin (contrôlé par la matrice [`AUTHZ-MATRIX.md`](../policies/AUTHZ-MATRIX.md))
* effet: invalide les bearer tokens actifs du client ciblé (pas d'arrêt de process)
* contrainte: un `client_kind=UI_RUST` est protégé et NE DOIT PAS être révocable via cet endpoint
* réponses:
  * `200` token(s) invalide(s)
  * `401 UNAUTHORIZED`
  * `403 FORBIDDEN_ACTOR` ou `FORBIDDEN_SCOPE` (selon matrice, incluant le cas token UI protégé)
  * `422 VALIDATION_FAILED`

`POST /auth/clients/token`

* security: aucune (`security: []`)
* body requis: `{ client_id, client_kind, secret_key }`
* `client_kind` autorisés: `AGENT | MCP` (`UI_RUST` exclu)
* effet: émet un bearer token client
* règle stricte: **1 token actif par client_id** (mint d’un nouveau token => révocation de l’ancien token pour ce client)
* réponses:
  * `200` token client (`access_token`, `token_type=Bearer`, `expires_in?`, `client_id`, `client_kind`)
  * `401 UNAUTHORIZED` (credentials client invalides)
  * `403 FORBIDDEN_ACTOR` (`client_kind` interactif refusé)
  * `422 VALIDATION_FAILED`
  * `429 TOO_MANY_ATTEMPTS`

`POST /auth/clients/{client_id}/rotate-secret`

* security: `UserBearerAuth`
* prérequis authz: acteur admin (contrôlé par la matrice [`AUTHZ-MATRIX.md`](../policies/AUTHZ-MATRIX.md))
* effet: régénère la `secret_key` et invalide les tokens actifs du client ciblé
* réponses:
  * `200` nouvelle `secret_key` (retournée une seule fois à la rotation)
  * `401 UNAUTHORIZED`
  * `403 FORBIDDEN_ACTOR` ou `FORBIDDEN_SCOPE` (selon matrice)
  * `422 VALIDATION_FAILED`

Règle d'erreur (obligatoire) :

* toute réponse 4xx/5xx de ces endpoints DOIT retourner le schéma `ErrorResponse`

Règle d’unification clients (obligatoire) :

* le flux login utilisateur (`POST /auth/login`) et `UserBearerAuth` DOIVENT être communs pour les clients interactifs `UI_RUST` et `AGENT`


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
* `q=texte` (optionnel, **v1**, recherche full-text sur `filename`, `notes`, `transcript_text`)
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
  * `feature_flags` (map runtime `flag_name -> boolean`, source de vérité Core)
  * (optionnel) `quiet_hours`

Normes d’exécution agent (obligatoires) :

* un agent DOIT fournir un binaire `CLI` (mode headless Linux obligatoire)
* un agent PEUT fournir une `GUI` pour usage desktop
* si une `GUI` existe, elle DOIT déléguer au même moteur que la `CLI` (mêmes capabilities, mêmes contraintes protocole)
* l’auth non-interactive agent DOIT fonctionner sans login humain (service/daemon)
* support plateforme cible : Linux headless (Raspberry Pi Kodi/Plex), macOS laptop, Windows desktop


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
* `transcribe_audio` (**v1**) : mise à jour du domaine `transcript`
* `suggest_tags` (**v1.1+**) : mise à jour du domaine `suggestions`

Note v1 (important) :

* `ProcessingResultPatch` ne transporte pas les binaires.
* Les binaires (proxies/thumbs/waveforms) sont uploadés via l’API Derived.
* `submit` référence les dérivés déjà uploadés.
* Le serveur applique un merge partiel par domaine ; un job ne peut pas écraser les domaines qu'il ne possède pas.
* ownership de patch par `job_type` :
  * `extract_facts` -> `facts_patch`
  * `generate_proxy|generate_thumbnails|generate_audio_waveform` -> `derived_patch`
  * `transcribe_audio` -> `transcript_patch`
  * `suggest_tags` (**v1.1+**) -> `suggestions_patch`

Règle authz complémentaire :

* pour `job_type=suggest_tags`, l'acteur DOIT avoir `jobs:submit` **et** `suggestions:write`
* pour `job_type=suggest_tags`, le flag `features.ai.suggest_tags` DOIT être actif

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

Objectif : permettre à un client d’automatisation de **préparer** une action de décision en masse, sans laisser l’automatisation décider silencieusement.

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
* `suggestions: { status, tags_suggested[], source? }` (**v1.1+**)
* `decisions: { current?, history[] }`
* `audit: { path_history[] }`

### Job

* `job_id`
* `job_type` (`extract_facts | generate_proxy | generate_thumbnails | generate_audio_waveform | transcribe_audio`)
* `job_type` (`suggest_tags`) (**v1.1+**)
* `asset_uuid`
* `lock_token`
* `locked_until`
* `paths`
* `derived_target_dir`

### ProcessingResultPatch

* `facts_patch?` (JSON partiel)
* `derived_patch?` (`derived_manifest` partiel)
* `transcript_patch?`
* `suggestions_patch?` (**v1.1+**)
* `warnings[]`
* `metrics`

Règles :

* merge par domaine uniquement (pas de replace global)
* un job ne peut mettre à jour que son domaine autorisé
* toute clé hors domaine autorisé renvoie `422 VALIDATION_FAILED`


## 10) Codes d’erreur (normatifs)

* `400 INVALID_TOKEN`
* `401 UNAUTHORIZED`
* `403 FORBIDDEN_SCOPE` / `FORBIDDEN_ACTOR`
* `403 EMAIL_NOT_VERIFIED`
* `404 USER_NOT_FOUND`
* `400 INVALID_2FA_CODE`
* `401 MFA_REQUIRED`
* `409 STATE_CONFLICT`
* `409 IDEMPOTENCY_CONFLICT`
* `409 MFA_ALREADY_ENABLED` / `MFA_NOT_ENABLED`
* `423 LOCK_REQUIRED` / `LOCK_INVALID`
* `410 PURGED`
* `422 VALIDATION_FAILED`
* `429 TOO_MANY_ATTEMPTS`
* `429 RATE_LIMITED`
* `503 TEMPORARY_UNAVAILABLE`

Le payload d’erreur normatif est défini dans [`ERROR-MODEL.md`](ERROR-MODEL.md).


## 11) Décisions actées (v1)

* URLs de dérivés : stables (same-origin)
* Claim jobs : `GET /jobs` pour discovery + `POST /jobs/{job_id}/claim` pour lease atomique
* Dérivés : upload HTTP, pas d’écriture directe côté client sur le filesystem NAS
* Batch move : sélection v1 via ids depuis preview, lock par asset
* Purge : purge unitaire v1 (+ batch purge plus tard si nécessaire)
* Scopes : agents strictement limités aux scopes jobs (jamais décisions/moves/purge)
* Filtres `tags=` : tags humains uniquement
* Recherche full-text `q=` disponible
* Transcription (`transcribe_audio`) disponible
* Changement de décision KEEP/REJECT autorisé de façon directe
* Reprocess autorisé depuis `PROCESSED|ARCHIVED|REJECTED`

## 12) Décisions actées (v1.1)

* Introduction des capacités AI-powered (`suggest_tags`, `suggestions_patch`, bloc `suggestions` dans `AssetDetail`)
* Introduction de `suggested_tags=` et `suggested_tags_mode=`
* Scope `suggestions:write` pour les flux AI dédiés
* Bulk decisions via preview/apply (`/decisions/preview`, `/decisions/apply`)

## 13) Points en suspens

* Batch purge : si nécessaire plus tard

## 14) Contrat snapshot local (`contracts/`) pour détecter le drift OpenAPI

Objectif :

* détecter tout changement de `api/openapi/v1.yaml` même sans version bump (`info.version` inchangé)

Règles normatives (tous les repos consommateurs : UI, core, agents, MCP, tooling CI) :

* chaque repo consommateur DOIT versionner un snapshot de contrat dans `contracts/`
* fichier minimum requis : `contracts/openapi-v1.sha256`
* la valeur DOIT être le hash SHA-256 calculé depuis `api/openapi/v1.yaml` de `retaia-docs`
* la CI DOIT échouer si le hash versionné localement ne correspond plus au hash de la spec courante (drift détecté)
* la mise à jour du hash DOIT être explicite dans une PR, via une commande dédiée (pas d’update implicite en pipeline)

Notes d'interprétation :

* ce mécanisme détecte les changements contractuels OpenAPI même si la version API ne change pas
* il ne remplace pas le versioning majeur (`/v2`) en cas de rupture de compatibilité

## 15) Adoption (repos consommateurs)

Checklist minimale d’implémentation :

* créer le dossier `contracts/` à la racine du repo consommateur
* ajouter une commande dédiée de refresh (ex: `make contracts-refresh`) qui :
  * récupère `api/openapi/v1.yaml` depuis `retaia-docs` (révision de référence)
  * calcule le hash SHA-256 du fichier
  * écrit uniquement la valeur hash dans `contracts/openapi-v1.sha256`
* ajouter une commande CI de vérification (ex: `make contracts-check`) qui :
  * recalcule le hash du `v1.yaml` de référence
  * compare avec `contracts/openapi-v1.sha256`
  * échoue (exit code non nul) en cas de mismatch
* exiger dans la PR la trace explicite du refresh (`contracts/openapi-v1.sha256` modifié + justification migration)

Exemple de scripts (POSIX) :

```bash
# Refresh contrôlé
shasum -a 256 api/openapi/v1.yaml | awk '{print $1}' > contracts/openapi-v1.sha256

# Check CI bloquant
test "$(cat contracts/openapi-v1.sha256)" = "$(shasum -a 256 api/openapi/v1.yaml | awk '{print $1}')"
```

Procédure de refresh contrôlé :

* étape 1 : mettre à jour `retaia-docs`
* étape 2 : exécuter la commande dédiée de refresh dans chaque repo consommateur impacté
* étape 3 : documenter l’impact consommateur (flags/capabilities/migration) dans la PR
* étape 4 : faire passer le gate CI `contract drift` avant merge

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
* [CODE-QUALITY.md](../change-management/CODE-QUALITY.md)
