# Test Plan — Normative Minimum (v1)

Ce document définit le minimum de tests opposables pour valider une implémentation Retaia.

## 0) Versioning projet global

Tests obligatoires :

* `v1` projet global : Core + Agent + `capabilities` + `feature_flags`
* `v1.1` projet global : client `RUST_UI` (`client_kind=UI_RUST`) + client `MCP_CLIENT` (`client_kind=MCP`)
* les suites UI/MCP sont classées en gates `v1.1` global même si l'API v1 les supporte contractuellement

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
* `GET /app/features`:
  * bearer valide => `200` + payload `app_feature_enabled`
  * réponse inclut `feature_governance[]` (`key`, `tier`, `user_can_disable`, `dependencies[]`, `disable_escalation[]`)
  * bearer absent/invalide => `401 UNAUTHORIZED`
* `PATCH /app/features`:
  * bearer admin valide + body valide => `200` + payload `app_feature_enabled` mis à jour
  * bearer absent/invalide => `401 UNAUTHORIZED`
  * acteur/scope interdit => `403 FORBIDDEN_ACTOR` ou `FORBIDDEN_SCOPE`
  * body invalide => `422 VALIDATION_FAILED`
* `GET /auth/me/features`:
  * bearer valide => `200` + `user_feature_enabled` + `effective_feature_enabled` + `feature_governance`
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
  * bearer client technique valide (`OAuth2ClientCredentials`) => `200`
  * bearer absent/invalide => `401 UNAUTHORIZED`
  * endpoint runtime canonique pour `UI_RUST`, `AGENT`, `MCP`
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
  * `client_kind=UI_RUST` refusé (`403 FORBIDDEN_ACTOR`)
* `POST /auth/clients/device/start`:
  * `client_kind in {AGENT, MCP}` => `200` + `device_code`, `user_code`, `verification_uri`, `verification_uri_complete`
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

Matrice de migration v1 runtime (gelée) :

* `POST /auth/clients/device/poll`:
  * le pilotage client est fait uniquement via `200` + `status in {PENDING, APPROVED, DENIED, EXPIRED}`
  * aucun pilotage via `401`/`403` n'est autorisé
* `POST /auth/clients/token`:
  * `client_kind=UI_RUST` doit être rejeté en `403 FORBIDDEN_ACTOR` uniquement
  * rotation invalide immédiatement les tokens actifs du client
* toutes réponses d’erreur 4xx/5xx auth conformes au schéma `ErrorResponse`
* endpoints humains mutateurs exigent un bearer token (`UserBearerAuth`) conforme à la spec
* même flux login/token validé sur clients interactifs: `UI_RUST` et `AGENT` (gate `v1.1` global pour `UI_RUST`)
* compatibilité desktop validée: client `UI_RUST` (Rust/Tauri) utilise `POST /auth/login` + `Authorization: Bearer` (gate `v1.1` global)
* anti lock-out: l'UI n'expose jamais le token en clair et n'offre pas d'action d'auto-révocation du token UI actif (gate `v1.1` global)
* régression interdite: aucun endpoint runtime n'accepte encore `SessionCookieAuth` (Bearer-only)
* 2FA optionnelle: compte sans 2FA active ne requiert pas OTP
* création de secret `AGENT`/`MCP` via UI (gate `v1.1` global):
  * sans 2FA active => approval UI sans OTP
  * avec 2FA active => OTP obligatoire à l’étape d’approval
  * sans validation UI => aucun `secret_key` ne peut être émise

## 1.2) Agent runtime (CLI/GUI, cross-platform)

Tests obligatoires :

* `CLI` agent fonctionne en Linux headless (sans dépendance GUI)
* `GUI` agent (quand présent) utilise le même moteur de processing que `CLI` (mêmes capabilities et mêmes résultats)
* client `AGENT` validé dans les deux modes d’auth: interactif (`/auth/login`) et technique (`/auth/clients/token` ou OAuth2)
* client `MCP` validé en mode technique (`/auth/clients/token` ou OAuth2), sans login interactif (gate `v1.1` global)
* client `MCP` peut piloter/orchestrer l'agent sans exécuter de processing (gate `v1.1` global)
* client `MCP` ne peut pas `claim/heartbeat/submit` de job (`/jobs/*` => `403 FORBIDDEN_ACTOR`) (gate `v1.1` global)
* mode service non-interactif redémarre sans login humain sur Linux/macOS/Windows
* stockage secret conforme OS (Keychain macOS, Credential Manager/DPAPI Windows, secret store Linux)
* rotation de secret client n’exige pas de réinstallation agent
* cible Linux headless Raspberry Pi (Kodi/Plex) validée en non-régression
* capacités IA (providers/modèles/transcription/suggestions) couvertes par le plan de tests v1.1 (hors conformité v1)

## 1.3) Gates de non-régression obligatoires (release blockers)

Tests obligatoires :

* Contrat OpenAPI:
  * snapshot OpenAPI v1 à jour et validé en CI
  * aucun drift `api/openapi/v1.yaml` vs `api/API-CONTRACTS.md`
  * aucune réintroduction de codes HTTP legacy sur `POST /auth/clients/device/poll` (`401 AUTHORIZATION_PENDING`, `403 ACCESS_DENIED`)
* Intégration auth/device:
  * `POST /auth/clients/device/poll` piloté uniquement via `200` + `status`
  * `POST /auth/clients/device/poll` -> `400 INVALID_DEVICE_CODE` pour code invalide
  * `POST /auth/clients/token` -> `403 FORBIDDEN_ACTOR` pour `client_kind=UI_RUST`
* Compat client UI/Agent/MCP:
  * UI_RUST, AGENT, MCP compatibles avec le flux status-driven (`PENDING|APPROVED|DENIED|EXPIRED`) (gate `v1.1` global pour UI_RUST/MCP)
  * AGENT/MCP gèrent `429` (`SLOW_DOWN`/`TOO_MANY_ATTEMPTS`) avec retry/backoff déterministe
  * aucun client ne dépend encore de `401/403` pour la machine d’état device flow

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
* `transcribe_audio`, `suggest_tags` et `suggested_tags*` sont hors périmètre v1 et planifiés en `v1.1+`
* endpoints bulk decisions (`/decisions/preview`, `/decisions/apply`) ne sont actifs qu'en `v1.1+`

## 8.3) Feature flags (général)

Tests obligatoires :

* toute nouvelle feature est introduite derrière un flag
* toute feature `v1.1+` est désactivée par défaut
* source de vérité des flags = payload runtime de Core (`server_policy.feature_flags`), jamais un hardcode client
* canal runtime flags défini et testé pour `AGENT` en v1, puis `UI_RUST` et `MCP` en v1.1 global via `GET /app/policy` (pas seulement `POST /agents/register`)
* distinction opposable: `capabilities` (agent/client), `feature_flags` (Core), `app_feature_enabled` (application) et `user_feature_enabled` (utilisateur) sont testées séparément
* règle AND validée: capability + flag requis pour exécuter une action feature
* ordre d’arbitrage validé: `feature_flags` -> `app_feature_enabled` -> `user_feature_enabled` -> dépendances/escalade
* flag absent dans le payload runtime => traité comme `false`
* flags inconnus côté client => ignorés sans erreur
* flag désactivé => la feature est refusée explicitement avec un code normatif
* activation du flag active la feature sans régression sur les flux `v1`
* `server_policy` expose l’état effectif des flags utiles aux agents
* mapping des flags v1.1 conforme : `features.decisions.bulk` (+ flags IA dans le paquet normatif v1.1)
* client feature OFF => UI/action API de la feature interdite
* client feature ON => disponibilité immédiate sans redéploiement
* `AGENT` applique les `feature_flags` runtime du Core en v1 ; `UI_RUST` et `MCP` les appliquent en v1.1 global

Cas OFF/ON minimum :

* cas OFF/ON IA déplacés dans le plan de tests v1.1
* flag ON + capability manquante côté agent => job non exécutable (`pending`/refus selon policy)
* `features.decisions.bulk=OFF` : `/decisions/preview` et `/decisions/apply` non utilisables
* `features.decisions.bulk=ON` : flux preview/apply utilisable
* `UI_RUST` : OFF masque/neutralise la feature, ON l’active au prochain refresh flags
* `AGENT` : OFF interdit job/patch liés à la feature, ON les autorise sans rebuild agent
* `MCP` : OFF interdit les commandes/actions liées à la feature, ON les autorise sans redéploiement MCP
* `user_feature_enabled.features.ai=OFF` : fonctionnalités AI désactivées pour l’utilisateur courant sans impact global
* tentative d’opt-out utilisateur sur une feature `CORE_V1_GLOBAL` => refus `403 FORBIDDEN_SCOPE`
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
* gate CI bloquant si un commit de merge de synchronisation est détecté
* résolution de conflits validée dans le rebase (pas de merge commit dédié)

## 8.7) Security baseline (assume breach)

Tests obligatoires :

* aucun token (`access_token`, refresh token, token technique) n'apparaît en clair dans logs, traces, UI ou crash reports
* aucune `secret_key` client (`AGENT`/`MCP`) n'est persistée en clair côté Core
* `secret_key` n'est renvoyée qu'une fois lors de l'émission/rotation
* rotation `secret_key` invalide immédiatement les tokens actifs du `client_id`
* claims token minimales présentes (`sub`, `principal_type`, `client_id`, `client_kind`, `scope`, `jti`, `exp`) et absence de PII sensible
* chiffrement au repos activé pour données sensibles et backups
* flux auth sensibles soumis au rate-limit (login, lost-password, verify-email, token mint, device flow)
* actions sécurité critiques auditées (login/logout, revoke-token, rotate-secret, 2FA enable/disable, device approval, `PATCH /app/features`)
* régression interdite: aucune réintroduction de `SessionCookieAuth`

## 8.8) GPG/OpenPGP standardisation

Tests obligatoires :

* conformité au standard [`GPG-OPENPGP-STANDARD.md`](../policies/GPG-OPENPGP-STANDARD.md) sur tous les clients (`UI_RUST`, `AGENT`, `MCP`)
* roundtrip encrypt/decrypt valide avec librairie OpenPGP autorisée par stack
* signature/verification valide pour payloads sensibles signés
* rejet explicite des algorithmes interdits (SHA-1, RSA < 3072, DSA legacy)
* adresses, coordonnées GPS, transcriptions non lisibles en clair dans dump DB/backups
* rotation/rekey OpenPGP sans perte d'accès légitime
* mode transparent par défaut: aucun setup PGP manuel requis pour un utilisateur standard
* mode avancé: intégration `gpg-agent`/clés existantes fonctionne quand activée
* fallback sûr: indisponibilité du mode avancé ne bloque pas l'usage standard

## 8.9) Crypto + RGPD (leak-resilience)

Tests obligatoires :

* adresses, coordonnées GPS et transcriptions non lisibles en clair dans dump DB
* adresses, coordonnées GPS et transcriptions non lisibles en clair dans backups/extracts
* logs/traces/crash reports ne contiennent jamais ces données en clair
* export de données personnelles traçable et conforme au workflow RGPD
* effacement RGPD (quand applicable) purge les données selon la policy de retention
* exercice de notification fuite RGPD exécuté et tracé (SLA 72h vérifié en simulation)
* rotation/rekey crypto n'introduit pas de perte d'accès légitime ni de régression authz

## 8.10) Full-text + filtres localisation sur données chiffrées

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
* [SECURITY-BASELINE.md](../policies/SECURITY-BASELINE.md)
* [GPG-OPENPGP-STANDARD.md](../policies/GPG-OPENPGP-STANDARD.md)
* [CRYPTO-SECURITY-MODEL.md](../policies/CRYPTO-SECURITY-MODEL.md)
* [SEARCH-PRIVACY-INDEX.md](../policies/SEARCH-PRIVACY-INDEX.md)
* [RGPD-DATA-PROTECTION.md](../policies/RGPD-DATA-PROTECTION.md)
* [LOCK-LIFECYCLE.md](../policies/LOCK-LIFECYCLE.md)
* [CODE-QUALITY.md](../change-management/CODE-QUALITY.md)
* [I18N-LOCALIZATION.md](../policies/I18N-LOCALIZATION.md)
