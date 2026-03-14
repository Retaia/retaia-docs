# Test Plan — Normative Minimum (v1)

Ce document définit le minimum de tests opposables pour valider une implémentation Retaia.

## 0) Versioning projet global

Tests obligatoires :

* `v1` projet global : Core + Agent + `capabilities` + `feature_flags`
* `v1.1` projet global : clients `UI_WEB` + `AGENT_UI` (`client_kind=AGENT`) + client `MCP` (`client_kind=MCP`)
* aucune suite `v1.2` active : la piste mobile/push est actuellement non planifiée
* les suites UI/MCP sont classées en gates `v1.1` global

## 0.1) Configuration Core (.env layering + marker)

Tests obligatoires :

* precedence de config Core respectée : `.env` < `.env.<APP_ENV>` < `.env.local` < variables shell runtime (la valeur finale DOIT être celle de la dernière couche)
* absence de `.env.<APP_ENV>` et/ou `.env.local` ne fait pas échouer le boot si les variables requises sont résolues
* `APP_STORAGE_ID` mismatch avec `/.retaia.storage_id` => boot refusé (erreur explicite)
* marker `/.retaia` absent => création automatique par Core au boot/update, puis validation
* marker `/.retaia` JSON invalide => boot refusé (erreur explicite)
* échec de migration atomique du marker (`create/write/rename`) => boot/update refusé (pas de mode dégradé)
* upgrade de schéma du marker requis (drift du champ JSON `version` dans `/.retaia`) mais échoué => boot/update refusé (erreur explicite)
* changement de schéma `/.retaia` sans incrément du champ JSON `version` dans `/.retaia` => non conforme (gate bloquant)
* suppression manuelle de `/.retaia` suivie d'un redémarrage Core => recréation automatique puis validation
* multi-mount: un seul mount en échec de migration/validation marker => startup global refusé (pas de mode partiel)
* erreurs startup marker exposent un code normatif parmi: `CORE_STORAGE_MARKER_CREATE_FAILED`, `CORE_STORAGE_MARKER_JSON_INVALID`, `CORE_STORAGE_MARKER_STORAGE_ID_MISMATCH`, `CORE_STORAGE_MARKER_SCHEMA_UPGRADE_FAILED`

## 0.2) Discipline des tests unitaires

Tests obligatoires :

* toute suite marquée "unitaire" n'accède ni au réseau, ni à la DB, ni au vrai filesystem, ni à des processus externes
* les libs externes et tout module/fichier applicatif autre que l'unité testée sont mockés/stubbés/fakés
* l'horloge et les sources d'aléa sont contrôlées (mock/fake) pour garantir le déterminisme
* un test "unitaire" qui dépend d'une ressource réelle est reclassé en test d'intégration

## 1) State machine

Tests obligatoires :

* toutes transitions autorisées passent
* transitions interdites renvoient `409 STATE_CONFLICT`
* `PURGED` est terminal

## 1.1) Auth applicative

Tests obligatoires :

* `POST /auth/login`:
  * succès `200` avec body valide (`email`, `password`) et émission d'un bearer token (`access_token`, `token_type=Bearer`)
  * le token est lié à un `client_id` effectif; un nouveau login sur le même `client_id` invalide le token précédent
  * credentials invalides => `401 UNAUTHORIZED`
  * 2FA active sans `otp_code` => `401 MFA_REQUIRED`
  * 2FA active avec `otp_code` invalide => `401 INVALID_2FA_CODE`
  * 2FA active avec `otp_code` valide => `200`
  * email non vérifié => `403 EMAIL_NOT_VERIFIED`
  * body invalide => `422 VALIDATION_FAILED`
  * dépassement tentative => `429 TOO_MANY_ATTEMPTS`
* `POST /auth/refresh`:
  * refresh token valide => `200` + nouveau bearer token + refresh token rotaté
  * refresh token invalide/révoqué/expiré => `401 UNAUTHORIZED`
  * body invalide => `422 VALIDATION_FAILED`
* `POST /auth/webauthn/register/options`:
  * bearer utilisateur valide => `200`
  * bearer absent/invalide => `401 UNAUTHORIZED`
* `POST /auth/webauthn/register/verify`:
  * attestation valide + bearer utilisateur valide => `200`
  * attestation invalide => `422 VALIDATION_FAILED`
  * conflit device/credential => `409 STATE_CONFLICT`
* `POST /auth/webauthn/authenticate/options`:
  * credential connu / compte admissible => `200`
  * demande invalide => `422 VALIDATION_FAILED`
  * rate limit => `429 TOO_MANY_ATTEMPTS`
* `POST /auth/webauthn/authenticate/verify`:
  * assertion valide => `200` + bearer token + refresh token
  * assertion invalide => `401 UNAUTHORIZED`
  * body invalide => `422 VALIDATION_FAILED`
* `POST /auth/2fa/setup`:
  * bearer valide + 2FA inactive => `200` + `otpauth_uri` / `secret` pour app externe (Authy...)
  * bearer absent/invalide => `401 UNAUTHORIZED`
  * 2FA déjà active => `409 MFA_ALREADY_ENABLED`
* `POST /auth/2fa/enable`:
  * bearer valide + `otp_code` valide => `200`
  * `otp_code` invalide => `400 INVALID_2FA_CODE`
  * bearer absent/invalide => `401 UNAUTHORIZED`
  * 2FA déjà active => `409 MFA_ALREADY_ENABLED`
  * body invalide => `422 VALIDATION_FAILED`
* `POST /auth/2fa/disable`:
  * bearer valide + `otp_code` valide => `200`
  * `otp_code` invalide => `400 INVALID_2FA_CODE`
  * bearer absent/invalide => `401 UNAUTHORIZED`
  * 2FA non active => `409 MFA_NOT_ENABLED`
  * body invalide => `422 VALIDATION_FAILED`
* `POST /auth/logout`:
  * bearer valide => `200`
  * bearer absent/invalide => `401 UNAUTHORIZED`
* `GET /auth/me`:
  * bearer valide => `200` + payload utilisateur courant
  * bearer absent/invalide => `401 UNAUTHORIZED`
* `GET /app/features`:
  * bearer admin valide => `200` + payload `app_feature_enabled`
  * bearer user non-admin => `403 FORBIDDEN_ACTOR` ou `FORBIDDEN_SCOPE`
  * payload stable obligatoire: `app_feature_enabled`, `feature_governance`, `core_v1_global_features`
  * réponse inclut `feature_governance[]` (`key`, `tier`, `user_can_disable`, `dependencies[]`, `disable_escalation[]`)
  * réponse inclut `core_v1_global_features[]` (registre canonique des features non désactivables)
  * bearer absent/invalide => `401 UNAUTHORIZED`
* `PATCH /app/features`:
  * bearer admin valide + body valide => `200` + payload `app_feature_enabled` mis à jour
  * bearer absent/invalide => `401 UNAUTHORIZED`
  * acteur/scope interdit => `403 FORBIDDEN_ACTOR` ou `FORBIDDEN_SCOPE`
  * body invalide => `422 VALIDATION_FAILED`
  * `app_feature_enabled.features.ai=false` => seules les fonctionnalités MCP dépendantes de l’AI sont désactivées
* `GET /auth/me/features`:
  * bearer valide => `200` + `user_feature_enabled` + `effective_feature_enabled` + `feature_governance`
  * payload stable obligatoire: `user_feature_enabled`, `effective_feature_enabled`, `feature_governance`, `core_v1_global_features`
  * réponse inclut `core_v1_global_features[]`
  * bearer absent/invalide => `401 UNAUTHORIZED`
* `PATCH /auth/me/features`:
  * bearer valide + body valide => `200` + préférences utilisateur mises à jour
  * bearer absent/invalide => `401 UNAUTHORIZED`
  * tentative de désactivation d’une feature `CORE_V1_GLOBAL` => `403 FORBIDDEN_SCOPE`
  * body invalide => `422 VALIDATION_FAILED`
  * désactivation d’une feature parent => `disable_escalation[]` appliquée dans `effective_feature_enabled`
  * dépendance OFF => feature dépendante OFF dans `effective_feature_enabled`
  * clé absente dans `user_feature_enabled` => traitée comme `true` (pas de régression pour utilisateurs existants)
* `GET /app/policy`:
  * bearer utilisateur valide => `200` + `server_policy.feature_flags`
  * bearer client technique valide (`TechnicalBearerAuth`) => `200`
  * bearer absent/invalide => `401 UNAUTHORIZED`
  * endpoint runtime canonique pour `UI_WEB`, `AGENT`, `MCP`
* `POST /app/policy`:
  * bearer admin valide + body valide (`feature_flags`) => `200`
  * bearer absent/invalide => `401 UNAUTHORIZED`
  * acteur/scope interdit => `403 FORBIDDEN_ACTOR` ou `FORBIDDEN_SCOPE`
  * tentative de mutation d’un flag encore `code-backed` => `409 STATE_CONFLICT`
  * body invalide => `422 VALIDATION_FAILED`
* `POST /auth/lost-password/request`:
  * body valide (`email`) => `202`
  * body invalide => `422 VALIDATION_FAILED`
  * rate limit => `429 TOO_MANY_ATTEMPTS`
* `POST /auth/lost-password/reset`:
  * body valide (`token`, `new_password`) => `200`
  * token invalide/expiré => `400 INVALID_TOKEN`
  * body invalide => `422 VALIDATION_FAILED`
* `POST /auth/verify-email/request`:
  * body valide (`email`) => `202`
  * body invalide => `422 VALIDATION_FAILED`
  * rate limit => `429 TOO_MANY_ATTEMPTS`
* `POST /auth/verify-email/confirm`:
  * body valide (`token`) => `200`
  * token invalide/expiré => `400 INVALID_TOKEN`
  * body invalide => `422 VALIDATION_FAILED`
* `POST /auth/verify-email/admin-confirm`:
  * bearer admin valide + body valide (`email`) => `200`
  * acteur/scope interdit => `403 FORBIDDEN_ACTOR` ou `FORBIDDEN_SCOPE`
  * utilisateur inexistant => `404 USER_NOT_FOUND`
  * body invalide => `422 VALIDATION_FAILED`
* `POST /auth/clients/{client_id}/revoke-token`:
  * bearer admin valide + `client_id` valide => `200` et token(s) invalide(s)
  * bearer absent/invalide => `401 UNAUTHORIZED`
  * acteur/scope interdit => `403 FORBIDDEN_ACTOR` ou `FORBIDDEN_SCOPE`
  * `client_id` invalide => `422 VALIDATION_FAILED`
  * `client_id` de type `UI_WEB` protégé => `403` (non révocable via cet endpoint)
* `POST /auth/clients/token`:
  * `client_id + client_kind=AGENT + secret_key` valides => `200` + bearer token client
  * credentials client invalides => `401 UNAUTHORIZED`
  * body invalide => `422 VALIDATION_FAILED`
  * rate limit => `429 TOO_MANY_ATTEMPTS`
  * invariant: nouveau token minté pour un client révoque l’ancien token (1 token actif / client)
  * `client_kind in {UI_WEB, MCP}` refusé (`403 FORBIDDEN_ACTOR`)
* `POST /auth/clients/device/start`:
  * `client_kind=AGENT` => `200` + `device_code`, `user_code`, `verification_uri`, `verification_uri_complete`
  * `client_kind=MCP` => `403 FORBIDDEN_ACTOR`
  * body invalide => `422 VALIDATION_FAILED`
  * rate limit => `429 TOO_MANY_ATTEMPTS`
* `POST /auth/clients/device/poll`:
  * avant validation UI => statut `PENDING`
  * après approval UI => statut `APPROVED` + `secret_key` one-shot
  * approval refusée par utilisateur => statut `DENIED`
  * code expiré => statut `EXPIRED`
  * body invalide => `422 VALIDATION_FAILED`
  * polling trop fréquent => `429 SLOW_DOWN`/`TOO_MANY_ATTEMPTS`
* `POST /auth/clients/device/cancel`:
  * flow en cours => `200` canceled
  * `device_code` invalide/expiré => `400 INVALID_DEVICE_CODE|EXPIRED_DEVICE_CODE`
* `POST /auth/clients/{client_id}/rotate-secret`:
  * bearer admin valide + `client_id` valide => `200` + nouvelle `secret_key` (retournée une fois)
  * bearer absent/invalide => `401 UNAUTHORIZED`
  * acteur/scope interdit => `403 FORBIDDEN_ACTOR` ou `FORBIDDEN_SCOPE`
  * `client_id` invalide => `422 VALIDATION_FAILED`
* `POST /auth/mcp/register`:
  * bearer utilisateur valide + clé publique valide => `200` + `client_id` MCP
  * bearer absent/invalide => `401 UNAUTHORIZED`
  * acteur/scope interdit => `403 FORBIDDEN_ACTOR|FORBIDDEN_SCOPE`
  * conflit d'enrôlement => `409 STATE_CONFLICT`
  * body invalide => `422 VALIDATION_FAILED`
* `POST /auth/mcp/challenge`:
  * `client_id` MCP + fingerprint valides => `200` + challenge court
  * challenge one-shot avec TTL <= 5 minutes
  * challenge expiré ou rejoué => refusé
  * body invalide => `422 VALIDATION_FAILED`
  * rate limit => `429 TOO_MANY_ATTEMPTS`
* `POST /auth/mcp/token`:
  * challenge valide + signature valide => `200` + bearer token client `MCP`
  * challenge expiré, consommé ou rejoué => `401 UNAUTHORIZED`
  * signature/challenge invalides => `401 UNAUTHORIZED`
  * body invalide => `422 VALIDATION_FAILED`
  * rate limit => `429 TOO_MANY_ATTEMPTS`
* `POST /auth/mcp/{client_id}/rotate-key`:
  * bearer admin valide + clé publique valide => `200` + fingerprint rotaté
  * acteur/scope interdit => `403 FORBIDDEN_ACTOR|FORBIDDEN_SCOPE`
  * conflit de rotation => `409 STATE_CONFLICT`
  * body invalide => `422 VALIDATION_FAILED`
* `POST /auth/webauthn/register/options` et `POST /auth/webauthn/authenticate/options`:
  * options/challenge one-shot avec TTL <= 5 minutes
  * rejeu ou double soumission après succès => refusés
* `POST /auth/webauthn/register/verify` et `POST /auth/webauthn/authenticate/verify`:
  * challenge expiré, consommé ou rejoué => refusé
* `GET /assets/{uuid}`:
  * retourne `summary.revision_etag` et le header `ETag`
* `PATCH /assets/{uuid}`, `POST /assets/{uuid}/reprocess`, `POST /assets/{uuid}/reopen`:
  * `If-Match` obligatoire
  * précondition absente => `428 PRECONDITION_REQUIRED`
  * révision périmée => `412 PRECONDITION_FAILED`
  * `revision_etag` change sur toute mutation métier visible en UI
  * `revision_etag` ne change pas pour du bruit purement technique sans impact visible
* `POST /agents/register`:
  * `agent_id` requis
  * `agent_id` conforme UUIDv4
  * `openpgp_public_key` requis
  * `openpgp_fingerprint` requis
  * register signé avec la clé privée correspondant à la clé OpenPGP déclarée
  * `os_name`, `os_version`, `arch` requis
  * reconnexion avec le même `agent_id` => même instance corrélable côté Core
  * deux agents actifs avec le même `agent_id` : register autorisé, conflit journalisé et visible en ops
  * `agent_id` absent/vide => `422 VALIDATION_FAILED`
  * aucun identifiant DB interne Core distinct n'est exposé dans le payload API
  * clé publique OpenPGP inconnue/invalide ou signature register invalide => refus auth explicite

Matrice de migration v1 runtime (gelée) :

* `POST /auth/clients/device/poll`:
  * le pilotage client est fait uniquement via `200` + `status in {PENDING, APPROVED, DENIED, EXPIRED}`
  * aucun pilotage via `401`/`403` n'est autorisé
* `POST /auth/clients/token`:
  * `client_kind in {UI_WEB, MCP}` doit être rejeté en `403 FORBIDDEN_ACTOR` uniquement
  * rotation invalide immédiatement les tokens actifs du client
* toutes réponses d’erreur 4xx/5xx auth conformes au schéma `ErrorResponse`
* endpoints humains mutateurs exigent un bearer token (`UserBearerAuth`) conforme à la spec
* même flux login/token validé sur clients interactifs: `UI_WEB` et `AGENT`
* compatibilité UI validée:
  * `UI_WEB` utilise `WebAuthn` + bearer + refresh token comme auth primaire
  * `AGENT_UI` utilise `POST /auth/login` + bearer dans un premier temps, puis peut adopter `WebAuthn` quand la surface le permet, sans changer le modèle de compte
  * `AGENT_TECHNICAL` n'utilise jamais `WebAuthn` au runtime
* anti lock-out: l'UI n'expose jamais le token en clair et n'offre pas d'action d'auto-révocation du token UI actif (gate `v1.1` global)
* régression interdite: aucun endpoint runtime n'accepte encore `SessionCookieAuth` (API stateless/sessionless)
* 2FA optionnelle: compte sans 2FA active ne requiert pas OTP
* création de secret `AGENT` via UI (gate `v1.1` global):
  * sans 2FA active => approval UI sans OTP
  * avec 2FA active => OTP obligatoire à l’étape d’approval
  * sans validation UI => aucun `secret_key` ne peut être émise
* enregistrement de clé publique `MCP` via UI (gate `v1.1` global):
  * sans 2FA active => validation UI sans OTP
  * avec 2FA active => OTP obligatoire à la validation
  * aucun login interactif MCP ni device flow MCP

## 1.2) Agent runtime (CLI/GUI, cross-platform)

Tests obligatoires :

* `AGENT_UI` en mode `CLI` fonctionne en Linux headless (sans dépendance GUI)
* `AGENT_UI` en mode `GUI` (quand présent) utilise le même moteur de processing que `CLI` (mêmes capabilities et mêmes résultats)
* `AGENT_UI` en mode `CLI` et `GUI` expose les mêmes fonctionnalités opérateur
* `AGENT_UI` en mode `GUI` PEUT couvrir les mêmes parcours humains que `UI_WEB` sans transférer l'identité utilisateur au daemon
* aucune action user-scoped initiée depuis `AGENT_UI` n'est exécutée par `AGENT_TECHNICAL` sans contrat de délégation explicite
* client `AGENT` validé dans les deux modes d’auth: interactif (`/auth/login`) et technique (`/auth/clients/token`)
* client `MCP` validé en mode technique asymétrique standard, sans login interactif ni device flow (gate `v1.1` global)
* client `MCP` obtient son bearer technique via `POST /auth/mcp/challenge` + `POST /auth/mcp/token`
* client `MCP` peut piloter/orchestrer l'agent sans exécuter de processing (gate `v1.1` global)
* client `MCP` ne peut pas `claim/heartbeat/submit` de job (`/jobs/*` => `403 FORBIDDEN_ACTOR`) (gate `v1.1` global)
* mode service non-interactif redémarre sans login humain sur Linux/macOS/Windows
* stockage secret conforme OS (Keychain macOS, Credential Manager/DPAPI Windows, secret store Linux)
* rotation de secret `AGENT` ou rotation/révocation de clé `MCP` n’exige pas de réinstallation client
* cible Linux headless Raspberry Pi (Kodi/Plex) validée en non-régression
* capacités IA (providers/modèles/transcription/suggestions) couvertes par le plan de tests v1.1 (hors conformité v1)
* runtime status-driven validé: la vérité d'état est synchronisée par polling, même si un canal push existe (WebSocket, SSE, webhook, autres push)
* polling jobs/policy respecte les intervalles contractuels et applique backoff+jitter sur `429`

## 1.3) Gates de non-régression obligatoires (release blockers)

Tests obligatoires :

* Contrat OpenAPI:
  * snapshot OpenAPI v1 à jour et validé en CI
  * aucun drift `api/openapi/v1.yaml` vs `api/API-CONTRACTS.md`
  * aucune réintroduction de codes HTTP legacy sur `POST /auth/clients/device/poll` (`401 AUTHORIZATION_PENDING`, `403 ACCESS_DENIED`)
* Intégration auth/device:
  * `POST /auth/clients/device/poll` piloté uniquement via `200` + `status`
  * `POST /auth/clients/device/poll` -> `400 INVALID_DEVICE_CODE` pour code invalide
  * `POST /auth/clients/token` -> `403 FORBIDDEN_ACTOR` pour `client_kind in {UI_WEB, MCP}`
* `POST /auth/mcp/token` est le seul flow de mint technique autorisé pour `client_kind=MCP`
* Compat client UI/Agent/MCP:
  * AGENT compatible avec le flux status-driven device (`PENDING|APPROVED|DENIED|EXPIRED`)
  * UI_WEB, AGENT et MCP gèrent `429` (`SLOW_DOWN`/`TOO_MANY_ATTEMPTS`) avec retry/backoff déterministe sur leurs endpoints auth/runtime respectifs
  * aucun client ne dépend encore de `401/403` pour la machine d’état device flow
  * aucun client ne traite un canal push serveur (WebSocket/SSE/webhook/notification) comme source de vérité runtime
  * un changement `server_policy.feature_flags` est pris en compte au prochain polling sans redéploiement client

## 2) Jobs & leases

Tests obligatoires :

* claim atomique concurrent (un gagnant)
* lease expiry rend le job reclaimable
* heartbeat prolonge `locked_until`
* job `pending` sans agent compatible reste `pending` sans erreur
* `claim`, `heartbeat`, `submit`, `fail`, `derived/upload/*` refusés si la signature agent est absente/invalide
* rejeu d'un `X-Retaia-Signature-Nonce` déjà vu => refus explicite
* skew temps hors fenêtre autorisée sur `X-Retaia-Signature-Timestamp` => refus explicite
* rotation de clé agent explicite uniquement; aucune régénération silencieuse acceptée

## 3) Processing profiles

Tests obligatoires :

* `PROCESSED` atteint uniquement quand jobs `required` du profil sont complets
* avant validation `v1.1+`, `transcribe_audio` peut être activé plus tôt sous `feature_flags`
* dès validation `v1.1+`, tout média avec piste audio exploitable exige `transcribe_audio` pour atteindre `PROCESSED`
* changement de profil après claim exige reprocess
* pour un profil audio qui exige `generate_audio_waveform`, son absence rend le flux processing non conforme
* pour tout média avec piste audio exploitable, l'absence de `generate_audio_waveform` rend le flux processing non conforme

## 3.1) Audio waveform UX (client)

Tests obligatoires :

* si `derived.waveform_url` est présent, le client peut l’utiliser
* pour tout asset avec piste audio exploitable, `derived.waveform_url` est obligatoire dès qu'on dépasse `READY`
* absence de waveform dérivée bloque la progression métier au-delà de `READY` pour un asset audio
* un fallback UI local PEUT exister pour la lecture, mais NE REND PAS le processing conforme

## 3.2) Derived format compliance (obligatoire)

Tests obligatoires :

* `proxy_video` :
  * conteneur `video/mp4`
  * codec vidéo `H.264/AVC` lisible navigateur
  * piste audio (si présente) en `AAC-LC`
  * framerate dérivé = framerate source (tolérance max ±0.01 fps)
  * `CFR` requis (pas de VFR non contrôlé)
  * hauteur cible `720px` si la source est plus grande, sinon hauteur source conservée
  * bitrate vidéo dans la plage normative `1.5 Mbps` à `4 Mbps`
  * ratio d'aspect conservé, aucun upscale
  * keyframe interval <= 2 secondes
  * MP4 faststart (`moov` en tête)
  * audio stéréo maximum, downmix multicanal autorisé
* `proxy_audio` :
  * format `audio/mp4` (AAC-LC) ou `audio/mpeg`
  * sample rate conforme (source conservée ou normalisée 44.1k/48k)
  * canaux cohérents avec policy de downmix
* `proxy_photo` :
  * format `image/jpeg` ou `image/webp`
  * `sRGB`
  * orientation EXIF normalisée
  * ratio d'aspect conservé, aucun upscale
* `thumb` :
  * format `image/jpeg` ou `image/webp`
  * `sRGB`
  * taille preview par défaut largeur `480px`
  * vidéo courte (`< 120s`) : thumb principal extrait à `max(1s, 10% de la durée)`
  * vidéo longue (`>= 120s`) : thumb principal extrait à `5% de la durée`, avec fallback à `20s` si `5% > 20s`
  * si la frame cible est noire ou de fondu et qu'une heuristique légère est active, une frame voisine plus représentative est choisie
  * mode `storyboard` : `10` thumbs sont produits et répartis régulièrement sur la durée utile
  * mode `storyboard` : ordre chronologique stable
* `waveform` :
  * si présent en JSON: amplitudes normalisées + métadonnées minimales (`duration_ms`, `bucket_count`)
  * `bucket_count` recommandé `1000`, minimum `100`
  * bucketisation régulière sur toute la durée
  * si absent alors que le média a une piste audio exploitable et a dépassé `READY`: non-conformité bloquante
* cohérence globale :
  * `duration`/`fps`/dimensions exposés cohérents avec le fichier dérivé livré
  * aucun dérivé ne modifie implicitement le sens temporel du média

## 4) Merge patch par domaine

Tests obligatoires :

* `transcribe_audio` n'efface jamais `facts/derived`
* `extract_facts` n'efface jamais `transcript`
* clés hors domaine autorisé renvoient `422 VALIDATION_FAILED`
* `job_type` vs domaine patch suit strictement l'ownership spécifié
* multi-sélection UI "ajout keyword" : N appels `PATCH /assets/{uuid}` indépendants, erreurs partielles isolées
* ajout manuel de keywords : après confirmation UI, aucune liste Core "non appliquée" spécifique n'est créée; la mutation est immédiatement persistée par asset
* action groupée UI sans validation explicite (annulation de confirmation) : aucun appel unitaire Core émis
* historique de révisions asset mis à jour après mutation validée (`revision_history[]` append + `is_current=true` sur la dernière)
* mutation asset avec `If-Match` périmé => `412 PRECONDITION_FAILED`
* `412 PRECONDITION_FAILED` asset expose `details.current_revision_etag` et `details.current_state`
* `PATCH /assets/{uuid}`, `POST /assets/{uuid}/reprocess` et `POST /assets/{uuid}/reopen` renvoient `428 PRECONDITION_REQUIRED` si `If-Match` est absent

## 5) Apply decision (move unitaire)

Tests obligatoires :

* éligibilité limitée à `DECIDED_KEEP|DECIDED_REJECT`
* la liste Core des décisions posées mais non appliquées est dérivable strictement depuis les assets en `DECIDED_KEEP|DECIDED_REJECT`
* lock par asset posé pendant filesystem op
* release lock avant transition finale
* collision nom => suffixe `__{short_nonce}`
* une erreur sur un asset ne bloque pas l’application sur les autres assets sélectionnés en UI
* multi-sélection UI KEEP/REJECT : N appels `PATCH /assets/{uuid}` avec `state=DECIDED_KEEP|DECIDED_REJECT`
* action groupée UI avec validation explicite : exécution autorisée et traçable
* cas versionning: une révision `VALIDATED` publiée reste exploitable pendant qu'une révision suivante est `PENDING_VALIDATION`

## 6) Purge

Tests obligatoires :

* purge seulement depuis `REJECTED`
* purge supprime originaux + sidecars + dérivés
* purge idempotente avec `Idempotency-Key`

## 6.1) Sidecars unmatched observability

Tests obligatoires :

* sidecar/proxy orphelin (ex: `.lrf` sans parent) :
  * ne crée pas d'asset standalone
  * est marqué `queued` dans l'état de scan
  * incrémente `unmatched_sidecars` dans la sortie ingest
* sidecar ambigu (plusieurs parents possibles) :
  * n'est pas auto-attaché
  * expose `unmatched_reason = ambiguous_parent`
* sidecar désactivé par policy (ex: `lrv/thm` si legacy off) :
  * n'est pas auto-attaché
  * expose `unmatched_reason = disabled_by_policy`
* reporting ingest inclut toujours les 3 compteurs :
  * `queued`
  * `missing`
  * `unmatched_sidecars`

## 6.2) Lock lifecycle recovery

Tests obligatoires :

* crash après filesystem op et avant transition d'état -> recovery idempotent
* `fencing_token` obsolète renvoie `409 STALE_LOCK_TOKEN`
* expiration lock move/purge récupérée par watchdog

## 7) Idempotence API

Tests obligatoires :

* même clé + même body => même réponse
* même clé + body différent => `409 IDEMPOTENCY_CONFLICT`
* endpoints critiques refusent l'absence de clé

## 8) Contrats API

Tests obligatoires :

* conformité des réponses à `api/openapi/v1.yaml`
* détection de drift `API-CONTRACTS.md` vs OpenAPI en CI
* payload erreur conforme à `api/ERROR-MODEL.md`
* enum d’état `AssetState` strict sur les payloads d’assets
* exigences de sécurité/scopes OpenAPI présentes sur chaque endpoint mutateur
* schéma `SessionCookieAuth` absent de la spec OpenAPI
* endpoint `GET /ops/ingest/diagnostics` présent et conforme :
  * compteurs `queued`, `missing`, `unmatched_sidecars`
  * `latest_unmatched[]` avec `path`, `reason`, `detected_at`
  * `reason` limité à `missing_parent|ambiguous_parent|disabled_by_policy`
* endpoint `GET /ops/readiness` présent et conforme :
  * `status` global
  * `self_healing` avec `active`, `deadline_at`, `max_self_healing_seconds=300`
  * `checks[]` avec `name`, `status`, `message`
  * mapping `status` conforme (`database=fail` => `down`; check critique fail avec DB OK + `self_healing.active=true` et `now < deadline_at` => `degraded`; sinon `down`)
* endpoint `GET /ops/locks` présent et conforme :
  * filtres `asset_uuid`, `lock_type`, pagination `limit`, `offset`
  * payload `items[]` + `total` (total avant pagination)
* endpoint `POST /ops/locks/recover` présent et conforme :
  * body `stale_lock_minutes`, `dry_run`
  * payload `stale_examined`, `recovered`, `dry_run`
  * `stale_lock_minutes` non entier ou < 1: comportement explicite documenté (coercion v1 ou `400 VALIDATION_FAILED`)
* endpoint `GET /ops/jobs/queue` présent et conforme :
  * `summary.pending_total|claimed_total|failed_total`
  * `by_type[]` avec `job_type`, `pending`, `claimed`, `failed`, `oldest_pending_age_seconds`
* endpoint `GET /ops/agents` présent et conforme :
  * filtres `status`, pagination `limit`, `offset`
  * payload `items[]` + `total`
  * `items[]` expose `agent_id`, `client_id`, `agent_name`, `agent_version`, `os_name`, `os_version`, `arch`, `status`, `last_seen_at`, `effective_capabilities[]`
  * `agent_id` exposé correspond à l'identifiant public persistant d'instance, pas à une clé interne DB
  * `identity_conflict` booléen exposé si le même `agent_id` est vu sur plusieurs agents actifs
  * `current_job?` expose `job_id`, `job_type`, `asset_uuid`, `claimed_at`, `locked_until`
  * `last_successful_job?` expose `job_id`, `job_type`, `asset_uuid`, `completed_at`
  * `last_failed_job?` expose `job_id`, `job_type`, `asset_uuid`, `failed_at`, `error_code`
  * `debug.max_parallel_jobs` présent, aucun secret/token/path absolu exposé
  * mapping `status` conforme : lease active => `online_busy`; agent actif sans lease => `online_idle`; agent expiré côté runtime => `stale`
  * `UserBearerAuth` seul n'est pas suffisant : l'utilisateur doit aussi avoir le statut admin
* endpoint `GET /ops/ingest/unmatched` présent et conforme :
  * filtres `reason`, `since`, `limit`
  * `reason`/`since` invalides renvoient `400 VALIDATION_FAILED`
  * payload `items[]` + `total`
* endpoint `POST /ops/ingest/requeue` présent et conforme :
  * body accepte `asset_uuid` ou `path` (au moins un)
  * `path` absolu/unsafe et `reason` vide renvoient `400 VALIDATION_FAILED`
  * payload `202` avec `accepted`, `target`, `requeued_assets`, `requeued_jobs`, `deduplicated_jobs`
* cohérence validation:
  * `VALIDATION_FAILED` en `400` pour `path/query/header`
  * `VALIDATION_FAILED` en `422` pour body JSON valide mais payload métier invalide

## 8.1) Authz matrix

Tests obligatoires :

* chaque endpoint critique vérifie scope, acteur et état
* refus authz renvoie le bon code (`FORBIDDEN_SCOPE`, `FORBIDDEN_ACTOR`, `STATE_CONFLICT`)

## 8.2) Versioning v1 vs v1.1

Tests obligatoires :

* `q` (full-text) fonctionne en `v1`
* `transcribe_audio`, `suggest_tags` et `suggested_tags*` sont hors périmètre v1 et planifiés en `v1.1+`
* `transcribe_audio` devient obligatoire à partir de la phase `v1.1+` validée pour tout média avec piste audio exploitable
* avant cette phase validée, `transcribe_audio` PEUT être exercé en pré-release uniquement via `feature_flags`

## 8.3) Feature flags (général)

Tests obligatoires :

* toute nouvelle feature est introduite derrière un flag
* toute feature `v1.1+` est désactivée par défaut
* source de vérité des flags = payload runtime de Core (`server_policy.feature_flags`), jamais un hardcode client
* canal runtime flags défini dans le contrat pour `AGENT`, `UI_WEB` et `MCP` via `GET /app/policy`; le contrat existe dès v1 pour `AGENT_TECHNICAL`, puis le rollout produit global des clients `UI_WEB`, `AGENT_UI` et `MCP` est validé en v1.1
* distinction opposable: `capabilities` (agent/client), `feature_flags` (Core), `app_feature_enabled` (application) et `user_feature_enabled` (utilisateur) sont testées séparément
* règle AND validée: capability + flag requis pour exécuter une action feature
* ordre d’arbitrage validé: `feature_flags` -> `app_feature_enabled` -> `user_feature_enabled` -> dépendances/escalade
* calcul `effective_feature_enabled` conforme à [`FEATURE-RESOLUTION-ENGINE.md`](../policies/FEATURE-RESOLUTION-ENGINE.md)
* flag absent dans le payload runtime => traité comme `false`
* flags inconnus côté client => ignorés sans erreur
* flag désactivé => la feature est refusée explicitement avec un code normatif
* activation du flag active la feature sans régression sur les flux `v1`
* `server_policy` expose l’état effectif des flags utiles aux agents
* client feature OFF => UI/action API de la feature interdite
* client feature ON => disponibilité immédiate sans redéploiement
* `AGENT_TECHNICAL` applique les `feature_flags` runtime du Core dès le contrat v1 ; `UI_WEB`, `AGENT_UI` et `MCP` les appliquent dans leur rollout produit global validé en v1.1

Cas OFF/ON minimum :

* cas OFF/ON IA déplacés dans le plan de tests v1.1
* flag ON + capability manquante côté agent => job non exécutable (`pending`/refus selon policy)
* `UI_WEB` : OFF masque/neutralise la feature, ON l’active au prochain refresh flags
* `AGENT` : OFF interdit job/patch liés à la feature, ON les autorise sans rebuild agent
* `MCP` : OFF interdit uniquement les commandes/actions MCP dépendantes de la feature, ON les autorise sans redéploiement MCP
* `UI_WEB` se base uniquement sur `effective_feature_enabled` (pas de décision locale sur flags bruts)
* `app_feature_enabled.features.ai=OFF` : client `MCP` reste utilisable pour l’orchestration non-AI autorisée, mais les fonctions MCP dépendantes de l’AI sont refusées
* `app_feature_enabled.features.ai=ON` : fonctions MCP dépendantes de l’AI autorisées selon matrice authz et capabilities
* `user_feature_enabled.features.ai=OFF` : fonctionnalités AI désactivées pour l’utilisateur courant sans impact global
* admin remet ON une feature globalement après opt-out user => l’utilisateur concerné reste OFF
* tentative d’opt-out utilisateur sur une feature `CORE_V1_GLOBAL` => refus `403 FORBIDDEN_SCOPE`
* pour chaque clé de `core_v1_global_features[]`, la ligne `feature_governance.key` correspondante expose `tier=CORE_V1_GLOBAL` et `user_can_disable=false`
* assimilation flag->mainline validée: après stabilisation, le flag disparaît de `server_policy.feature_flags` et le comportement final reste couvert par des tests non conditionnels
* aucun code/test/doc OFF/ON obsolète persistant après retrait du flag (hors kill-switchs explicitement documentés)

## 8.4) Transition runtime des flags

Tests obligatoires :

* transition `OFF -> ON` sans redéploiement client : la feature devient disponible au prochain fetch de `server_policy.feature_flags`
* transition `ON -> OFF` sans redéploiement client : la feature est immédiatement retirée/neutralisée côté client
* un client démarré avant la transition n’utilise pas de cache de flags non borné dans le temps
* aucune transition runtime de flag ne modifie les comportements historiques `v1` non flaggés
* négociation version flags via `client_feature_flags_contract_version` sur `GET /app/policy` et `POST /agents/register`
* Core renvoie `feature_flags_contract_version`, `accepted_feature_flags_contract_versions[]`, `effective_feature_flags_contract_version`, `feature_flags_compatibility_mode`
* format des versions flags validé en SemVer (`MAJOR.MINOR.PATCH`)
* client version acceptée mais non-latest => réponse `COMPAT` non cassante
* client version non supportée => `426 UNSUPPORTED_FEATURE_FLAGS_CONTRACT_VERSION`
* retrait d’un flag latest conserve un tombstone `false` pour profils `COMPAT` encore acceptés
* fenêtre d’acceptance respectée: `max(2 versions stables, 90 jours)`
* tombstones purgés automatiquement après `>=30 jours` post-acceptance
* fallback si automatisation de purge en échec: conservation `<=6 mois`, puis purge manuelle obligatoire
* `accepted_feature_flags_contract_versions[]` non modifiable via endpoint admin runtime
* continuous development validé: suppression d’un flag n’interrompt pas UI/Agent/MCP déjà déployés dans la fenêtre d’acceptance
* continuous deployment validé: une release Core avec retrait de flag passe les gates CD sans exiger upgrade client synchronisée
* chaque kill-switch permanent a une entrée dans `change-management/FEATURE-FLAG-KILLSWITCH-REGISTRY.md`

## 8.4.b) Matrice de vérité feature governance

Tests obligatoires :

* `feature_flags=OFF`, `app=ON`, `user=ON` => `effective=OFF`
* `feature_flags=ON`, `app=OFF`, `user=ON` => `effective=OFF`
* `feature_flags=ON`, `app=ON`, `user=OFF` => `effective=OFF`
* `feature_flags=ON`, `app=ON`, `user=ON`, dépendance OFF => `effective=OFF`
* `feature_flags=ON`, `app=ON`, `user=ON`, dépendances ON => `effective=ON`
* admin OFF puis user ON => `effective=OFF` (l’utilisateur ne peut pas réactiver)
* admin ON après un user OFF persistant => `effective=OFF` pour cet utilisateur
* tentative user OFF sur `CORE_V1_GLOBAL` => `403 FORBIDDEN_SCOPE`
* clé `user_feature_enabled` absente => évaluée `true`

## 8.5) Contract drift (`contracts/`)

Tests obligatoires :

* chaque repo consommateur versionne `contracts/openapi-v1.sha256`
* la CI échoue si `contracts/openapi-v1.sha256` ne correspond plus au hash courant de `api/openapi/v1.yaml`
* la commande dédiée de refresh met à jour explicitement `contracts/openapi-v1.sha256`
* toute mise à jour de snapshot est visible dans la PR (pas de mutation implicite en post-merge)
* non-régression v1 : un refresh de snapshot ne modifie pas la sémantique des comportements `v1` existants
* gate de cohérence contrat/docs : CI échoue si un endpoint/champ mentionné dans `api/API-CONTRACTS.md` n'existe pas dans `api/openapi/v1.yaml`

## 8.6) Workflow Git (historique linéaire)

Tests obligatoires :

* la PR est rebased sur `master` (pas de merge de synchronisation)
* aucun commit de type `Merge branch 'master' into ...` dans l'historique PR
* le check CI `branch-up-to-date` est vert avant merge
* gate CI bloquant si un commit de merge de synchronisation est détecté
* résolution de conflits validée dans le rebase (pas de merge commit dédié)

## 8.7) Security baseline (assume breach)

Tests obligatoires :

* aucun token (`access_token`, refresh token, token technique) n'apparaît en clair dans logs, traces, UI ou crash reports
* aucune `secret_key` `AGENT` ni secret privé `MCP` n'est persistée en clair côté Core
* `secret_key` `AGENT` n'est renvoyée qu'une fois lors de l'émission/rotation quand applicable
* rotation `secret_key` `AGENT` ou révocation/rotation du credential `MCP` invalide immédiatement les accès techniques associés
* claims token minimales présentes (`sub`, `principal_type`, `client_id`, `client_kind`, `scope`, `jti`, `exp`) et absence de PII sensible
* chiffrement au repos activé pour données sensibles et backups
* flux auth sensibles soumis au rate-limit (login, lost-password, verify-email, token mint agent, device flow agent, enregistrement de clé technique UI)
* actions sécurité critiques auditées (login/logout, revoke-token, rotate-secret, enregistrer/révoquer une clé technique, 2FA enable/disable, device approval, `PATCH /app/features`, `POST /app/policy`)
* régression interdite: aucune réintroduction de `SessionCookieAuth`

## 8.8) GPG/OpenPGP standardisation

Tests obligatoires :

* conformité au standard [`GPG-OPENPGP-STANDARD.md`](../policies/GPG-OPENPGP-STANDARD.md) sur tous les clients actifs (`UI_WEB`, `AGENT`, `MCP`)

## 8.9) Observabilité feature governance

Tests obligatoires :

* update admin de `app_feature_enabled` produit un audit event `app_feature_enabled.updated`
* update user de `user_feature_enabled` produit un audit event `user_feature_enabled.updated`
* refus `FORBIDDEN_SCOPE` produit un audit event `feature_access.denied` avec `reason_code`
* calcul de `effective_feature_enabled` produit `feature_effective.resolved` traçable par `request_id`/`trace_id`
* métriques `feature_toggle_admin_total`, `feature_toggle_user_total`, `feature_denied_total`, `feature_effective_off_total` exposées
* histogramme `feature_resolution_duration_ms` exposé
* logs/traces ne contiennent ni token, ni secret, ni PII en clair
* roundtrip encrypt/decrypt valide avec librairie OpenPGP autorisée par stack
* signature/verification valide pour payloads sensibles signés
* rejet explicite des algorithmes interdits (SHA-1, RSA < 3072, DSA legacy)
* adresses, coordonnées GPS, transcriptions non lisibles en clair dans dump DB/backups
* rotation/rekey OpenPGP sans perte d'accès légitime
* mode transparent par défaut: aucun setup PGP manuel requis pour un utilisateur standard
* mode avancé: intégration `gpg-agent`/clés existantes fonctionne quand activée
* fallback sûr: indisponibilité du mode avancé ne bloque pas l'usage standard

## 8.10) Crypto + RGPD (leak-resilience)

Tests obligatoires :

* adresses, coordonnées GPS et transcriptions non lisibles en clair dans dump DB
* adresses, coordonnées GPS et transcriptions non lisibles en clair dans backups/extracts
* logs/traces/crash reports ne contiennent jamais ces données en clair
* export de données personnelles traçable et conforme au workflow RGPD
* effacement RGPD (quand applicable) purge les données selon la policy de retention
* exercice de notification fuite RGPD exécuté et tracé (SLA 72h vérifié en simulation)
* rotation/rekey crypto n'introduit pas de perte d'accès légitime ni de régression authz

## 8.11) Full-text + filtres localisation sur données chiffrées

Tests obligatoires :

* `q` fonctionne en v1 sans plaintext indexé pour la transcription
* `location_country` fonctionne sur index dérivé
* `location_city` fonctionne sur index dérivé
* `geo_bbox` fonctionne sur index spatial dérivé
* combinaison `q + filtres localisation + autres filtres` conserve la sémantique attendue
* dump DB/backups de l'index de recherche ne révèle pas adresse, GPS, transcription en clair
* reindex après rotation de clés conserve les résultats attendus sans fuite de plaintext

## 9) Couverture minimale

Minimum :

* scénarios P0 ci-dessus à 100%
* chemins critiques move/purge/lock couverts avant merge
* routes UI canoniques conformes à `ui/UI-GLOBAL-SPEC.md`
* shell UI desktop conforme (sidebar, barre de contexte, zone liste/detail, rail droit)
* actions groupées UI couvertes avec le lifecycle `selection_active -> changes_pending -> confirmation_open -> executing -> result_ready`
* aucun appel Core avant confirmation UI explicite
* registre de raccourcis conforme à `ui/KEYBOARD-SHORTCUTS-REGISTRY.md`
* blocage des raccourcis globaux en contexte de saisie, hors exceptions explicites
* persistance du theme (`system|light|dark`), du mode de vue (`table|grid`) et de la densité par workspace

## 10) I18N / L10N (parcours critiques)

Tests obligatoires :

* les parcours review, décision, move et purge sont entièrement traduits en `en` et `fr`
* fallback `locale utilisateur -> en -> clé brute` conforme à la policy i18n
* les clés manquantes `en` ou `fr` échouent le pipeline CI (gate bloquant)
* les libellés d'actions destructives sont validés sans ambiguïté avant release
* les libellés de navigation visibles suivent le vocabulaire UI canonique
* les routes restent techniques et non localisées

## Références associées

* [STATE-MACHINE.md](../state-machine/STATE-MACHINE.md)
* [JOB-TYPES.md](../definitions/JOB-TYPES.md)
* [PROCESSING-PROFILES.md](../definitions/PROCESSING-PROFILES.md)
* [API-CONTRACTS.md](../api/API-CONTRACTS.md)
* [ERROR-MODEL.md](../api/ERROR-MODEL.md)
* [AUTHZ-MATRIX.md](../policies/AUTHZ-MATRIX.md)
* [SECURITY-BASELINE.md](../policies/SECURITY-BASELINE.md)
* [GPG-OPENPGP-STANDARD.md](../policies/GPG-OPENPGP-STANDARD.md)
* [CRYPTO-SECURITY-MODEL.md](../policies/CRYPTO-SECURITY-MODEL.md)
* [SEARCH-PRIVACY-INDEX.md](../policies/SEARCH-PRIVACY-INDEX.md)
* [RGPD-DATA-PROTECTION.md](../policies/RGPD-DATA-PROTECTION.md)
* [LOCK-LIFECYCLE.md](../policies/LOCK-LIFECYCLE.md)
* [CODE-QUALITY.md](../change-management/CODE-QUALITY.md)
* [I18N-LOCALIZATION.md](../policies/I18N-LOCALIZATION.md)

* `MCP` ne peut jamais exécuter `DELETE`, `purge` ni aucune action destructive équivalente (`403 FORBIDDEN_ACTOR`)
