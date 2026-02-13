# Test Plan — Normative Minimum (v1)

Ce document définit le minimum de tests opposables pour valider une implémentation Retaia.

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
  * `client_id` de type `UI_RUST` protégé => `403` (non révocable via cet endpoint)
* `POST /auth/clients/token`:
  * `client_id + client_kind in {AGENT, MCP} + secret_key` valides => `200` + bearer token client
  * credentials client invalides => `401 UNAUTHORIZED`
  * body invalide => `422 VALIDATION_FAILED`
  * rate limit => `429 TOO_MANY_ATTEMPTS`
  * invariant: nouveau token minté pour un client révoque l’ancien token (1 token actif / client)
  * `client_kind=UI_RUST` refusé (422/403 selon policy)
* `POST /auth/clients/device/start`:
  * `client_kind in {AGENT, MCP}` => `200` + `device_code`, `user_code`, `verification_uri`, `verification_uri_complete`
  * body invalide => `422 VALIDATION_FAILED`
  * rate limit => `429 TOO_MANY_ATTEMPTS`
* `POST /auth/clients/device/poll`:
  * avant validation UI => statut `PENDING`
  * après approval UI => statut `APPROVED` + `secret_key` one-shot
  * approval refusée par utilisateur => statut/code `DENIED`/`ACCESS_DENIED`
  * code expiré => statut/code `EXPIRED`/`EXPIRED_DEVICE_CODE`
  * polling trop fréquent => `429 SLOW_DOWN`/`TOO_MANY_ATTEMPTS`
* `POST /auth/clients/device/cancel`:
  * flow en cours => `200` canceled
  * `device_code` invalide/expiré => `400 INVALID_DEVICE_CODE|EXPIRED_DEVICE_CODE`
* `POST /auth/clients/{client_id}/rotate-secret`:
  * bearer admin valide + `client_id` valide => `200` + nouvelle `secret_key` (retournée une fois)
  * bearer absent/invalide => `401 UNAUTHORIZED`
  * acteur/scope interdit => `403 FORBIDDEN_ACTOR` ou `FORBIDDEN_SCOPE`
  * `client_id` invalide => `422 VALIDATION_FAILED`
  * rotation invalide immédiatement les tokens actifs du client
* toutes réponses d’erreur 4xx/5xx auth conformes au schéma `ErrorResponse`
* endpoints humains mutateurs exigent un bearer token (`UserBearerAuth`) conforme à la spec
* même flux login/token validé sur clients interactifs: `UI_RUST` et `AGENT`
* compatibilité desktop validée: client `UI_RUST` (Rust/Tauri) utilise `POST /auth/login` + `Authorization: Bearer`
* anti lock-out: l'UI n'expose jamais le token en clair et n'offre pas d'action d'auto-révocation du token UI actif
* régression interdite: aucun endpoint runtime n'accepte encore `SessionCookieAuth` (Bearer-only)
* 2FA optionnelle: compte sans 2FA active ne requiert pas OTP
* création de secret `AGENT`/`MCP` via UI:
  * sans 2FA active => approval UI sans OTP
  * avec 2FA active => OTP obligatoire à l’étape d’approval
  * sans validation UI => aucun `secret_key` ne peut être émise

## 1.2) Agent runtime (CLI/GUI, cross-platform)

Tests obligatoires :

* `CLI` agent fonctionne en Linux headless (sans dépendance GUI)
* `GUI` agent (quand présent) utilise le même moteur de processing que `CLI` (mêmes capabilities et mêmes résultats)
* client `AGENT` validé dans les deux modes d’auth: interactif (`/auth/login`) et technique (`/auth/clients/token` ou OAuth2)
* client `MCP` validé en mode technique (`/auth/clients/token` ou OAuth2), sans login interactif
* mode service non-interactif redémarre sans login humain sur Linux/macOS/Windows
* stockage secret conforme OS (Keychain macOS, Credential Manager/DPAPI Windows, secret store Linux)
* rotation de secret client n’exige pas de réinstallation agent
* cible Linux headless Raspberry Pi (Kodi/Plex) validée en non-régression

## 2) Jobs & leases

Tests obligatoires :

* claim atomique concurrent (un gagnant)
* lease expiry rend le job reclaimable
* heartbeat prolonge `locked_until`
* job `pending` sans agent compatible reste `pending` sans erreur

## 3) Processing profiles

Tests obligatoires :

* `PROCESSED` atteint uniquement quand jobs `required` du profil sont complets
* `audio_music` n'exige pas `transcribe_audio`
* `audio_voice` exige `transcribe_audio`
* changement de profil après claim exige reprocess

## 4) Merge patch par domaine

Tests obligatoires :

* `transcribe_audio` n'efface jamais `facts/derived`
* `extract_facts` n'efface jamais `transcript`
* clés hors domaine autorisé renvoient `422 VALIDATION_FAILED`
* `job_type` vs domaine patch suit strictement l'ownership spécifié

## 5) Batch move

Tests obligatoires :

* éligibilité limitée à `DECIDED_KEEP|DECIDED_REJECT`
* lock par asset posé pendant filesystem op
* release lock avant transition finale
* collision nom => suffixe `__{short_nonce}`
* un échec asset ne bloque pas tout le batch

## 6) Purge

Tests obligatoires :

* purge seulement depuis `REJECTED`
* purge supprime originaux + sidecars + dérivés
* purge idempotente avec `Idempotency-Key`

## 6.1) Lock lifecycle recovery

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

## 8.1) Authz matrix

Tests obligatoires :

* chaque endpoint critique vérifie scope, acteur et état
* refus authz renvoie le bon code (`FORBIDDEN_SCOPE`, `FORBIDDEN_ACTOR`, `STATE_CONFLICT`)

## 8.2) Versioning v1 vs v1.1

Tests obligatoires :

* `q` (full-text) fonctionne en `v1`
* `transcribe_audio` fonctionne en `v1`
* `suggest_tags` et `suggested_tags*` ne sont actifs qu'en `v1.1+`
* endpoints bulk decisions (`/decisions/preview`, `/decisions/apply`) ne sont actifs qu'en `v1.1+`

## 8.3) Feature flags (général)

Tests obligatoires :

* toute nouvelle feature est introduite derrière un flag
* toute feature `v1.1+` est désactivée par défaut
* source de vérité des flags = payload runtime de Core (`server_policy.feature_flags`), jamais un hardcode client
* canal runtime flags défini et testé pour `UI_RUST`, `AGENT`, `MCP` (pas seulement `POST /agents/register`)
* flag absent dans le payload runtime => traité comme `false`
* flags inconnus côté client => ignorés sans erreur
* flag désactivé => la feature est refusée explicitement avec un code normatif
* activation du flag active la feature sans régression sur les flux `v1`
* `server_policy` expose l’état effectif des flags utiles aux agents
* mapping des flags v1.1 conforme : `features.ai.suggest_tags`, `features.ai.suggested_tags_filters`, `features.decisions.bulk`
* `job_type=suggest_tags` sur `/jobs/{job_id}/submit` exige `jobs:submit` + `suggestions:write`
* client feature OFF => UI/action API de la feature interdite
* client feature ON => disponibilité immédiate sans redéploiement
* `UI_RUST`, `AGENT` et `MCP` appliquent tous les `feature_flags` runtime du Core

Cas OFF/ON minimum :

* `features.ai.suggest_tags=OFF` : refus `job_type=suggest_tags`, `suggestions_patch` et actions UI associées
* `features.ai.suggest_tags=ON` : `suggest_tags` opérationnel sans impact sur les flux `v1`
* `features.ai.suggested_tags_filters=OFF` : filtres `suggested_tags*` non exposés/non envoyés
* `features.ai.suggested_tags_filters=ON` : filtres `suggested_tags*` utilisables
* `features.decisions.bulk=OFF` : `/decisions/preview` et `/decisions/apply` non utilisables
* `features.decisions.bulk=ON` : flux preview/apply utilisable
* `UI_RUST` : OFF masque/neutralise la feature, ON l’active au prochain refresh flags
* `AGENT` : OFF interdit job/patch liés à la feature, ON les autorise sans rebuild agent
* `MCP` : OFF interdit les commandes/actions liées à la feature, ON les autorise sans redéploiement MCP

## 8.4) Transition runtime des flags

Tests obligatoires :

* transition `OFF -> ON` sans redéploiement client : la feature devient disponible au prochain fetch de `server_policy.feature_flags`
* transition `ON -> OFF` sans redéploiement client : la feature est immédiatement retirée/neutralisée côté client
* un client démarré avant la transition n’utilise pas de cache de flags non borné dans le temps
* aucune transition runtime de flag ne modifie les comportements historiques `v1` non flaggés

## 8.5) Contract drift (`contracts/`)

Tests obligatoires :

* chaque repo consommateur versionne `contracts/openapi-v1.sha256`
* la CI échoue si `contracts/openapi-v1.sha256` ne correspond plus au hash courant de `api/openapi/v1.yaml`
* la commande dédiée de refresh met à jour explicitement `contracts/openapi-v1.sha256`
* toute mise à jour de snapshot est visible dans la PR (pas de mutation implicite en post-merge)
* non-régression v1 : un refresh de snapshot ne modifie pas la sémantique des comportements `v1` existants

## 9) Couverture minimale

Minimum :

* scénarios P0 ci-dessus à 100%
* chemins critiques move/purge/lock couverts avant merge

## 10) I18N / L10N (parcours critiques)

Tests obligatoires :

* les parcours review, décision, move et purge sont entièrement traduits en `en` et `fr`
* fallback `locale utilisateur -> en -> clé brute` conforme à la policy i18n
* les clés manquantes `en` ou `fr` échouent le pipeline CI (gate bloquant)
* les libellés d'actions destructives sont validés sans ambiguïté avant release

## Références associées

* [STATE-MACHINE.md](../state-machine/STATE-MACHINE.md)
* [JOB-TYPES.md](../definitions/JOB-TYPES.md)
* [PROCESSING-PROFILES.md](../definitions/PROCESSING-PROFILES.md)
* [API-CONTRACTS.md](../api/API-CONTRACTS.md)
* [ERROR-MODEL.md](../api/ERROR-MODEL.md)
* [AUTHZ-MATRIX.md](../policies/AUTHZ-MATRIX.md)
* [LOCK-LIFECYCLE.md](../policies/LOCK-LIFECYCLE.md)
* [CODE-QUALITY.md](../change-management/CODE-QUALITY.md)
* [I18N-LOCALIZATION.md](../policies/I18N-LOCALIZATION.md)
