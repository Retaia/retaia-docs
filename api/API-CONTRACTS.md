# API CONTRACT — v1

Ce document décrit le **contrat API v1** de Retaia Core.

Cette spécification est **normative**. Toute implémentation serveur, agent ou client doit s’y conformer strictement.

Les fichiers OpenAPI versionnés sont :

* `openapi/v1.yaml` (gate runtime actuelle, opposable)
* `openapi/v1.1.yaml` (prévision version mineure)
* `openapi/v1.2.yaml` (piste reservee, actuellement non planifiee)

`openapi/v1.yaml` reste la description contractuelle exécutable de référence tant que les gates CI pointent v1.
Ce document doit rester strictement aligné avec `openapi/v1.yaml`.

Objectif : fournir une surface stable consommée par :

* client Agent (`AGENT`) — livré en v1 projet global
* client UI web principal (`UI_WEB_APP`, `client_kind=UI_WEB`) — livré en v1.1 projet global
* client agent UI (`AGENT_UI`, `client_kind=AGENT`) — livré en v1.1 projet global
* client MCP (`MCP_CLIENT`, `client_kind=MCP`) — livré en v1.1 projet global


## 0) Conventions

### Base

* Base path : `/api/v1`
* Identité : **UUID** partout
* Dates : ISO‑8601 UTC (`YYYY-MM-DDTHH:mm:ssZ`)
* Pagination : `limit` + `cursor`
* Idempotence : header `Idempotency-Key` sur endpoints critiques
* Approche d'implémentation préférée : **DDD** (Domain-Driven Design), avec **TDD** et **BDD** comme pratiques de validation par défaut

### Versioning mineur (v1 / v1.1)

* `v1` = socle stable (ingestion, processing review, décision humaine, moves, purge, recherche full-text `q`).
* `v1.1` = extensions compatibles.
* Toute fonctionnalité AI-powered (ex: `transcribe_audio`, `suggest_tags`, filtres `suggested_tags*`) est hors périmètre de conformité v1 et planifiée en `v1.1+`.

### Versioning projet global (rollout)

* `v1` (projet global) :
  * Core v1
  * Agent v1
  * système `capabilities` v1
  * système `feature_flags` v1
* `v1.1` (projet global) :
  * client `UI_WEB_APP` (mappé sur `client_kind=UI_WEB`)
  * client `AGENT_UI` (mappé sur `client_kind=AGENT`)
  * client `MCP_CLIENT` (mappé sur `client_kind=MCP`)
* `v1.2` : piste reservee, actuellement non planifiee au produit

### Feature flags (normatif)

* Source de vérité : les flags sont pilotés par **Retaia Core** au runtime. Les clients (UI, agents, MCP) NE DOIVENT PAS hardcoder un état de flag.
* Toute nouvelle fonctionnalité DOIT être protégée par un feature flag serveur dès son introduction.
* Une feature stabilisée DOIT être assimilée au comportement nominal puis son feature flag DOIT être supprimé (pas de flag permanent hors kill-switch explicite).
* Les fonctionnalités `v1.1+` suivent la même règle et restent inactives tant que leur flag n'est pas activé.
* Convention de nommage : `features.<domaine>.<fonction>`.
* Contrat de transport : l’état effectif des flags DOIT être transporté dans un payload standard `server_policy.feature_flags` pour tous les clients (`UI_WEB`, `AGENT`, `MCP`) via `GET /app/policy`.
* Versionnement/acceptance obligatoire des flags :
  * client -> Core : `client_feature_flags_contract_version` (query `GET /app/policy` ou body `POST /agents/register`)
  * Core -> client : `feature_flags_contract_version`, `accepted_feature_flags_contract_versions`, `effective_feature_flags_contract_version`, `feature_flags_compatibility_mode`
  * format de version: SemVer (`MAJOR.MINOR.PATCH`)
  * si la version client est acceptée mais non-latest, Core DOIT servir un profil compatible (`feature_flags_compatibility_mode=COMPAT`)
  * Core DOIT éviter toute casse UI/Agent lors du retrait d’un flag (profil compat + tombstones `false` pour flags retirés, tant qu’une version acceptée les attend)
  * si la version client n'est pas supportée: `426` + `ErrorResponse.code=UNSUPPORTED_FEATURE_FLAGS_CONTRACT_VERSION`
* Fenêtre d'acceptance minimale:
  * au moins **2 versions client stables** (UI/Agent/MCP) ou **90 jours** après introduction de la version de contrat (le plus long des deux)
  * tombstones `false` purgés automatiquement après fermeture de la fenêtre d'acceptance + **30 jours**
  * fallback opérationnel: si l'automatisation de purge échoue, conservation maximale **6 mois**, puis purge manuelle obligatoire
* Distinction normative (sans ambiguïté) :
  * `feature_flags` = activation runtime des fonctionnalités côté Core
  * `app_feature_enabled` = activation applicative effective (switches niveau application, gouvernés par admin)
  * `user_feature_enabled` = préférences utilisateur (opt-out individuel, hors features core v1 globales)
  * `capabilities` = aptitudes techniques déclarées par les agents pour exécuter des jobs
  * `contracts/` = snapshots versionnés pour détecter un drift du contrat OpenAPI
* Règle de combinaison (obligatoire) :
  * exécution autorisée uniquement si `capability requise présente` **ET** `feature_flag(s) requis actif(s)` **ET** `app_feature_enabled` **ET** `user_feature_enabled`
  * capability présente + flag OFF => refus normatif (`403 FORBIDDEN_SCOPE`/équivalent policy)
  * flag ON + capability absente => non exécutable (`pending`, `403` ou `409` selon endpoint/policy)
* Sémantique stricte :
  * flag absent = `false`
  * flag inconnu côté client = ignoré
  * comportement safe-by-default : sans signal explicite `true` renvoyé par Core, la feature reste indisponible
* Phases de gouvernance d'un flag :
  * phase d'introduction/validation initiale : le flag PEUT être `code-backed` uniquement
  * phase de rollout élargi : le flag PEUT être migré en `DB-backed` (ou backend mutable équivalent)
  * un flag `code-backed` DOIT rester visible dans `GET /app/policy`, mais NE DOIT PAS être mutable via `POST /app/policy`
* Quand un flag est `false`, l’endpoint reste stable et la feature est refusée de façon explicite (`403 FORBIDDEN_SCOPE` ou `409 STATE_CONFLICT` selon le cas).
* L’activation d’un flag ne DOIT pas modifier le comportement des fonctionnalités `v1`.
* Le cycle de vie complet (introduction -> rollout -> assimilation -> retrait) est défini dans [`FEATURE-FLAG-LIFECYCLE.md`](../change-management/FEATURE-FLAG-LIFECYCLE.md).
* Ce cycle DOIT permettre le continuous development sans casse des clients encore dans la fenêtre d'acceptance.
* Ownership runtime: `accepted_feature_flags_contract_versions` est piloté par release/config Core (pas modifiable via endpoint admin runtime).
* Les kill-switches permanents autorisés DOIVENT être listés dans [`FEATURE-FLAG-KILLSWITCH-REGISTRY.md`](../change-management/FEATURE-FLAG-KILLSWITCH-REGISTRY.md).

### Orchestration runtime (normatif)

* Core est l'orchestrateur unique des états métier, jobs, policies et flags.
* Les clients actifs (`UI_WEB`, `AGENT`, `MCP`) DOIVENT synchroniser l'état runtime via **polling HTTP** (source de vérité).
* Les canaux push serveur-vers-client sont autorisés pour diffusion d'information/alerte (WebSocket, SSE, webhook client, autres canaux push).
* Ces canaux push servent de signal temps réel/UX, mais NE SONT PAS source de vérité métier.
* Tout changement de disponibilité fonctionnelle DOIT être observé via polling des endpoints contractuels (notamment `GET /app/policy`).
* Sur `429` (`SLOW_DOWN`/`TOO_MANY_ATTEMPTS`), le client DOIT appliquer backoff + jitter avant la tentative suivante.
* Le pilotage d'état du device flow reste strictement status-driven via `POST /auth/clients/device/poll` (`200` + `status`).
* Les opérations mutatrices REST (`POST`, `PATCH`, etc.) restent autorisées selon la matrice auth/authz.

Mapping normatif v1.1 (base actuelle, obligatoire pour tous les consommateurs) :

* les capacités AI (`transcribe_audio`, `suggest_tags`, providers/modèles, filtres `suggested_tags*`) sont planifiées en v1.1+ et hors validation de conformité v1.

Règles client (normatives, UI/agents/MCP) :

* feature OFF => appel API de la feature interdit et UI correspondante masquée/désactivée
* feature ON => feature disponible immédiatement, sans déploiement client supplémentaire
* `UI_WEB`, `AGENT` et `MCP` DOIVENT tous consommer les `feature_flags` runtime pilotés par Core
* aucun client ne DOIT hardcoder l’état d’un flag ni dépendre d’un flag local statique
* toute décision de disponibilité fonctionnelle côté client DOIT être dérivée du dernier payload runtime reçu
* un client DOIT accepter `feature_flags_compatibility_mode=COMPAT` sans échec fonctionnel
* `UI_WEB` DOIT piloter l'affichage/actions avec `effective_feature_enabled` (jamais avec une heuristique locale sur les flags bruts)
* `AGENT` et `MCP` DOIVENT bloquer toute action liée à une feature marquée OFF dans `effective_feature_enabled`
* un opt-out utilisateur (`user_feature_enabled=false`) reste persistant même si l’admin remet ensuite la feature ON globalement

Gouvernance des `app_feature_enabled` (opposable) :

* lecture (`GET /app/features`) : admin uniquement (`UserBearerAuth` + policy admin)
* modification (`PATCH /app/features`) : admin uniquement (`403 FORBIDDEN_ACTOR` / `FORBIDDEN_SCOPE` sinon)
* portée : switches applicatifs globaux (pas des préférences locales client)
* effet runtime obligatoire : un switch applicatif désactivé DOIT empêcher l’exécution des fonctionnalités associées pour le scope applicatif
* règle MCP obligatoire : `app_feature_enabled.features.ai=false` DOIT désactiver le client `MCP` (bootstrap UI, enrôlement de clé et appels authentifiés MCP refusés)

Gouvernance des `user_feature_enabled` (opposable) :

* lecture/modification : utilisateur authentifié sur lui-même via `GET/PATCH /auth/me/features`
* portée : préférences utilisateur (opt-out local à l’utilisateur courant)
* contrainte : les features classées `CORE_V1_GLOBAL` NE DOIVENT PAS être désactivables au scope utilisateur
* tentative de désactivation d’une feature `CORE_V1_GLOBAL` => `403 FORBIDDEN_SCOPE`
* effet runtime obligatoire : `user_feature_enabled=false` DOIT désactiver la feature pour l’utilisateur et appliquer la cascade de dépendances
* valeur par défaut (migration-safe) : absence de clé `user_feature_enabled.<feature>` DOIT être interprétée comme `true`

Gouvernance des `feature_flags` runtime (opposable) :

* lecture (`GET /app/policy`) : `USER_INTERACTIVE` et `TECHNICAL_ACTORS`
* modification (`POST /app/policy`) : admin uniquement (`UserBearerAuth` + policy admin)
* portée : flags runtime globaux pilotés par Core
* précondition d'écriture : applicable uniquement aux flags stockés en DB ou via un backend mutable équivalent
* un flag encore `code-backed` DOIT être refusé en écriture avec `409 STATE_CONFLICT`
* effet runtime obligatoire : un changement accepté DOIT être observable par les clients au prochain polling de `GET /app/policy`

Catalogue de dépendances et escalade (opposable) :

* Core DOIT exposer la liste normative via `feature_governance[]` (dans `GET /app/features` et `GET /auth/me/features`)
* chaque entrée DOIT inclure : `key`, `tier`, `user_can_disable`, `dependencies[]`, `disable_escalation[]`
* règle de dépendance : si une dépendance est OFF, la feature dépendante devient OFF dans `effective_feature_enabled`
* règle d’escalade : désactiver une feature parent DOIT désactiver toutes les features listées dans `disable_escalation[]`
* règle de sûreté v1 globale : les features socle v1 (`CORE_V1_GLOBAL`) restent disponibles et ne sont pas impactées par des opt-out utilisateur
* registre explicite obligatoire : Core DOIT exposer `core_v1_global_features[]` (liste canonique des clés non désactivables)
* toute entrée `feature_governance` dont `key` appartient à `core_v1_global_features[]` DOIT avoir `tier=CORE_V1_GLOBAL` et `user_can_disable=false`

Registre canonique `CORE_V1_GLOBAL` (v1) :

* `features.core.auth`
* `features.core.assets.lifecycle`
* `features.core.jobs.runtime`
* `features.core.search.query`
* `features.core.policy.runtime`
* `features.core.derived.access`
* `features.core.clients.bootstrap`

Arbitrage admin/user (opposable) :

* priorité d’évaluation: `feature_flags` -> `app_feature_enabled` -> `user_feature_enabled` -> dépendances/escalade
* `app_feature_enabled=false` domine toujours (feature OFF pour tous les utilisateurs)
* `app_feature_enabled=true` n’annule pas un opt-out utilisateur (`user_feature_enabled=false`)
* `CORE_V1_GLOBAL` : toujours ON dans `effective_feature_enabled` (hors indisponibilité technique majeure hors scope flags/user)
* l’algorithme opposable complet est défini dans [`FEATURE-RESOLUTION-ENGINE.md`](../policies/FEATURE-RESOLUTION-ENGINE.md)
* observabilité/audit obligatoire défini dans [`FEATURE-GOVERNANCE-OBSERVABILITY.md`](../policies/FEATURE-GOVERNANCE-OBSERVABILITY.md)

### Idempotence (règles strictes)

Endpoints avec `Idempotency-Key` obligatoire :

* `POST /assets/{uuid}/reprocess`
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

### Confidentialité des données sensibles (normatif)

* modèle "assume leak": DB/logs/backups peuvent être exfiltrés
* les champs `adresse`, `gps` et `transcription` DOIVENT être protégés par chiffrement applicatif (envelope/field-level) en plus du chiffrement au repos
* ces champs NE DOIVENT PAS être exposés en clair dans logs, traces, dumps et backups
* toute implémentation Core/UI/Agent/MCP DOIT rester conforme aux policies crypto et RGPD associées

### États (doit matcher [STATE-MACHINE.md](../state-machine/STATE-MACHINE.md))

`DISCOVERED, READY, PROCESSING_REVIEW, PROCESSED, DECISION_PENDING, DECIDED_KEEP, DECIDED_REJECT, ARCHIVED, REJECTED, PURGED`

Dans `openapi/v1.yaml`, les états sont typés via un enum strict (`AssetState`).


## 1) Auth

### Typologie des acteurs (normatif)

* `USER_INTERACTIVE` : utilisateur humain connecté via client `UI_WEB` (web app) ou via `AGENT_UI` (`client_kind=AGENT`, surfaces CLI ou GUI) pour bootstrap, administration ou diagnostic
* `AGENT_TECHNICAL` : agent daemon non-interactif (service) authentifié via bearer technique obtenu par `client_id + secret_key`
* `MCP_TECHNICAL` : client MCP non-humain authentifié via challenge/réponse asymétrique standard, après enrôlement de sa clé publique depuis l'UI par un utilisateur autorisé
* `TECHNICAL_ACTORS` : alias générique couvrant `AGENT_TECHNICAL | MCP_TECHNICAL`
* `client_kind` interactif est borné à `UI_WEB` ou `AGENT`; le mode technique autorise `AGENT` et `MCP`
* rollout projet global actif : `UI_WEB`, `AGENT_UI` et `MCP` sont intégrés à partir de la v1.1 globale

### UI (humain)

* `UI_WEB` DOIT utiliser `WebAuthn` comme mécanisme primaire d'authentification utilisateur
* l'API reste bearer-only/stateless côté runtime :
  * `WebAuthn` sert à obtenir ou renouveler des tokens
  * les appels API métiers continuent via `Authorization: Bearer ...`
  * aucun retour à `SessionCookieAuth` n'est autorisé
* `refresh_token` est autorisé pour les clients interactifs humains (`UI_WEB`, `AGENT_UI`)
* le mot de passe utilisateur reste un mécanisme de bootstrap, recovery et opérations sensibles, pas un mécanisme d'usage quotidien obligatoire sur chaque navigateur
* `client_kind=UI_WEB` couvre uniquement l'UI web servie par Core
* `AGENT_UI` relève du `client_kind=AGENT`, avec parité fonctionnelle obligatoire entre surfaces CLI et GUI
* `AGENT_UI` PEUT, à terme, devenir une surface applicative comparable à `UI_WEB` pour les fonctionnalités humaines, tout en restant distincte du daemon `AGENT_TECHNICAL`
* le token UI est non exportable dans l'interface (jamais affiché en clair)
* un utilisateur ne peut pas invalider son token UI depuis l'UI (anti lock-out)
* l'UI DOIT supporter l'enrôlement 2FA TOTP via app externe (Authy, Google Authenticator, etc.)
* un même compte utilisateur PEUT enregistrer plusieurs navigateurs/appareils de confiance
* l'enregistrement d'un nouveau browser ou d'une nouvelle machine NE DOIT PAS créer un nouveau compte utilisateur

Modèle multi-device (obligatoire) :

* le compte utilisateur reste unique
* chaque device/browser interactif PEUT avoir :
  * un `client_id`
  * un `device_id`
  * un credential `WebAuthn`
* plusieurs devices PEUVENT être rattachés au même compte utilisateur
* la révocation DOIT pouvoir se faire device par device, sans impacter les autres devices du même compte

### Agents / MCP

* modes non interactifs : bearer technique (`TechnicalBearerAuth`)
* mode `AGENT` interactif : `AGENT_UI` opéré par un humain (CLI ou GUI), avec bearer utilisateur via `POST /auth/login` aujourd'hui
* `AGENT_UI` PEUT utiliser `WebAuthn` quand la surface le permet (GUI desktop, shell natif ou environnement capable), sans changer le modèle de compte utilisateur ni le contrat bearer
* mode `AGENT_TECHNICAL` : `client_id + secret_key` pour obtenir un bearer token via `POST /auth/clients/token`
* `AGENT_TECHNICAL` N'UTILISE JAMAIS `WebAuthn` au runtime
* mode `MCP_TECHNICAL` : identité asymétrique standard avec clé publique enregistrée côté Core, clé privée locale côté client et signatures obligatoires sur les écritures sensibles
* seul `AGENT_TECHNICAL` exécute les jobs de processing; un `AGENT` interactif ne claim pas de job et ne traite pas de média
* `AGENT_UI` PEUT gérer des fonctionnalités humaines comparables à `UI_WEB` (review, préférences, profil utilisateur, pilotage daemon), mais ces mutations restent des actions `USER_INTERACTIVE`
* toute action `USER_INTERACTIVE` depuis `AGENT_UI` DOIT rester portée par une identité humaine authentifiée; le daemon `AGENT_TECHNICAL` NE DOIT PAS hériter implicitement de cette identité
* une éventuelle délégation future de droits user-scoped vers `AGENT_TECHNICAL` DOIT être explicite, bornée dans le temps, liée à un `agent_id` et documentée comme un contrat séparé
* `MCP` PEUT piloter/orchestrer l'agent (configuration, déclenchement, supervision) mais NE DOIT JAMAIS exécuter de traitement média
* `MCP` est interdit sur les endpoints de processing `/jobs/*` (`claim`, `heartbeat`, `submit`) avec refus `403 FORBIDDEN_ACTOR`
* `MCP_TECHNICAL` DOIT suivre les mêmes principes que l'agent :
  * pas d'implémentation crypto maison
  * standard existant
  * clé publique enregistrée côté Core
  * clé privée uniquement côté client
* les capacités IA (providers, modèles, transcription, suggestions) sont planifiées en v1.1+
* l’agent reste propriétaire du runtime provider/model (découverte locale, disponibilité, installation) dans le paquet normatif v1.1
* Core NE DOIT PAS exposer de catalogue runtime global de modèles
* `UI_WEB`, `AGENT` et `MCP` NE DOIVENT PAS hardcoder providers/modèles

Règles 2FA par client (obligatoire) :

* la 2FA est optionnelle au niveau compte utilisateur
* `UI_WEB` : `WebAuthn` + bearer + refresh token comme mécanisme primaire; `POST /auth/login` reste un fallback de bootstrap/recovery
* `AGENT_UI` PEUT utiliser `WebAuthn` quand la surface le permet; sinon `POST /auth/login` reste le fallback interactif
* `AGENT_TECHNICAL` au runtime : jamais de `WebAuthn`, pas de 2FA directe
* `MCP_TECHNICAL` au runtime : pas de 2FA directe
* création d’un `secret_key` pour `AGENT_TECHNICAL` : DOIT passer par une validation utilisateur via UI
* l’enregistrement initial de la clé publique `MCP_TECHNICAL` DOIT passer par l’UI et une action explicite d’un utilisateur autorisé
* si 2FA est activée sur ce compte utilisateur, la validation UI de création `secret_key` `AGENT` ou d’enregistrement de clé `MCP` DOIT exiger la 2FA
* flow cible `AGENT_TECHNICAL` : type GitHub device authorization (ouverture URL navigateur, auth UI, validation 2FA optionnelle, approval explicite)
* `MCP_TECHNICAL` NE DOIT PAS pouvoir initier de login utilisateur ni de device flow en autonomie

Règle de cardinalité des tokens (obligatoire) :

* `USER_INTERACTIVE` : un même utilisateur PEUT avoir plusieurs tokens actifs simultanément sur des clients différents, avec contrainte stricte **1 token actif par `(user_id, client_id)`**
* `AGENT_TECHNICAL` : contrainte stricte **1 token actif par `client_id`**
* `MCP_TECHNICAL` : le credential technique, la clé publique enregistrée et le bearer technique minté DOIVENT être révocables/rotatables; Core DOIT tracer quel utilisateur a autorisé l’enregistrement du client
* émission d'un nouveau token pour la même clé de cardinalité => révocation immédiate du token précédent
* les refresh tokens interactifs DOIVENT être rotatables et révocables par device/browser

#### Scopes (base)

* `assets:read`
* `assets:write` (**humain uniquement**) — tags/fields/notes humains
* `decisions:write` (**humain uniquement**)
* `jobs:claim` (**agents uniquement**)
* `jobs:heartbeat` (**agents uniquement**)
* `jobs:submit` (**agents uniquement**)
* `suggestions:write` (**v1.1+**, agents/MCP)
* `purge:execute` (**humain uniquement**)

La matrice normative endpoint x scope x état est définie dans [`AUTHZ-MATRIX.md`](../policies/AUTHZ-MATRIX.md).
`openapi/v1.yaml` déclare explicitement les schémas de sécurité (`UserBearerAuth`, `TechnicalBearerAuth`) et les exigences de sécurité par endpoint.

Migration obligatoire (anti dette technique) :

* `SessionCookieAuth` est retiré du contrat et est interdit pour toute nouvelle implémentation.
* Core DOIT supprimer le code runtime lié au cookie session auth (`SessionCookieAuth`).
* UI, Agent et MCP DOIVENT migrer vers Bearer-only et supprimer toute dépendance cookie.

Baseline sécurité/fuite (normatif) :

* la baseline security "assume breach" est définie dans [`SECURITY-BASELINE.md`](../policies/SECURITY-BASELINE.md)
* toute implémentation Core/UI/Agent/MCP DOIT appliquer les exigences MUST de cette baseline
* en cas de conflit d'interprétation, le modèle le plus restrictif s'applique

Normalisation HTTP (normatif) :

* `400` = requête sémantiquement invalide sur un identifiant/ticket déjà parsé (ex: `INVALID_TOKEN`, `INVALID_DEVICE_CODE`)
* `401` = authentification absente/invalide (`UNAUTHORIZED`) uniquement
* `403` = authentification valide mais action interdite (`FORBIDDEN_ACTOR`, `FORBIDDEN_SCOPE`)
* `404` = ressource métier introuvable (`USER_NOT_FOUND`)
* `409` = conflit d’état métier (`MFA_ALREADY_ENABLED`, `MFA_NOT_ENABLED`, `STATE_CONFLICT`)
* `422` = validation de payload échouée (`VALIDATION_FAILED`)
* `429` = anti-abus/rate-limit (`TOO_MANY_ATTEMPTS`, `SLOW_DOWN`)

Règle `VALIDATION_FAILED` (normatif) :

* `400 VALIDATION_FAILED` : paramètres `path/query/header` invalides (enum, format date-heure, format identifiant)
* `422 VALIDATION_FAILED` : body JSON valide mais non conforme au contrat métier attendu

Normalisation des timestamps (normatif) :

* tous les champs `*_at` exposés par l'API DOIVENT être ISO-8601 (`date-time`) en UTC
* les filtres temporels (ex: `since`) DOIVENT accepter ISO-8601; les valeurs invalides renvoient `400 VALIDATION_FAILED`
* les clients DEVRAIENT envoyer des timestamps explicites UTC (suffixe `Z` ou offset `+00:00`)

### Endpoints auth applicatifs (normatif)

`POST /auth/login`

* security: aucune (`security: []`)
* body requis: `{ email, password }`
* body optionnel: `client_id`, `client_kind`, `otp_code` (`otp_code` obligatoire si 2FA active)
* effet: login utilisateur interactif de bootstrap/recovery
* réponses:
  * `200` succès + bearer token (`access_token`, `token_type=Bearer`, `expires_in?`, `refresh_token?`, `client_id`, `client_kind`)
  * `401 UNAUTHORIZED` (credentials invalides), `MFA_REQUIRED` (2FA active sans OTP), `INVALID_2FA_CODE` (OTP invalide)
  * `403 EMAIL_NOT_VERIFIED`
  * `422 VALIDATION_FAILED`
  * `429 TOO_MANY_ATTEMPTS`

`POST /auth/refresh`

* security: aucune (`security: []`)
* body requis: `{ refresh_token }`
* body optionnel: `client_id`, `client_kind`
* effet: renouvelle un bearer token interactif sans repasser par le mot de passe
* réponses:
  * `200` succès + bearer token (`access_token`, `token_type=Bearer`, `expires_in?`, `refresh_token?`, `client_id`, `client_kind`)
  * `401 UNAUTHORIZED`
  * `422 VALIDATION_FAILED`
  * `429 TOO_MANY_ATTEMPTS`

`POST /auth/webauthn/register/options`

* security: `UserBearerAuth`
* effet: retourne les options d'enregistrement `WebAuthn` pour attacher un nouveau browser/device au compte utilisateur courant
* réponses:
  * `200` options `WebAuthn`
  * `401 UNAUTHORIZED`
  * `409 STATE_CONFLICT`

`POST /auth/webauthn/register/verify`

* security: `UserBearerAuth`
* body requis: attestation `WebAuthn`
* body optionnel: `device_id`, `device_label`
* effet: enregistre un credential `WebAuthn` pour le compte utilisateur courant
* réponses:
  * `200` credential enregistré
  * `401 UNAUTHORIZED`
  * `409 STATE_CONFLICT`
  * `422 VALIDATION_FAILED`

`POST /auth/webauthn/authenticate/options`

* security: aucune (`security: []`)
* body optionnel: `email`, `client_id`, `client_kind`
* effet: retourne les options d'assertion `WebAuthn` pour un browser/device déjà enregistré
* réponses:
  * `200` options `WebAuthn`
  * `401 UNAUTHORIZED`
  * `422 VALIDATION_FAILED`
  * `429 TOO_MANY_ATTEMPTS`

`POST /auth/webauthn/authenticate/verify`

* security: aucune (`security: []`)
* body requis: assertion `WebAuthn`
* body optionnel: `client_id`, `client_kind`
* effet: vérifie l'assertion `WebAuthn` puis émet un bearer token interactif + `refresh_token`
* réponses:
  * `200` succès + bearer token (`access_token`, `token_type=Bearer`, `expires_in?`, `refresh_token?`, `client_id`, `client_kind`)
  * `401 UNAUTHORIZED`
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

`GET /app/features`

* security: `UserBearerAuth`
* effet: retourne les switches applicatifs (`app_feature_enabled`) + métadonnées de gouvernance (`feature_governance`) + registre canonique `core_v1_global_features`
* prérequis authz: acteur admin (contrôlé par la matrice [`AUTHZ-MATRIX.md`](../policies/AUTHZ-MATRIX.md))
* contrat payload stable obligatoire:
  * `app_feature_enabled`
  * `feature_governance`
  * `core_v1_global_features`
* réponses:
  * `200` succès
  * `401 UNAUTHORIZED`
  * `403 FORBIDDEN_ACTOR` ou `FORBIDDEN_SCOPE`

`PATCH /app/features`

* security: `UserBearerAuth`
* prérequis authz: acteur admin (contrôlé par la matrice [`AUTHZ-MATRIX.md`](../policies/AUTHZ-MATRIX.md))
* body requis: `{ app_feature_enabled: { ... } }`
* effet: met à jour les switches applicatifs globaux
* règle: un switch applicatif désactivé DOIT empêcher la planification/exécution des fonctionnalités associées
* réponses:
  * `200` succès
  * `401 UNAUTHORIZED`
  * `403 FORBIDDEN_ACTOR` ou `FORBIDDEN_SCOPE`
  * `422 VALIDATION_FAILED`

`GET /auth/me/features`

* security: `UserBearerAuth`
* effet: retourne les préférences feature de l’utilisateur (`user_feature_enabled`) et l’état effectif (`effective_feature_enabled`)
* inclut `feature_governance` et `core_v1_global_features` pour appliquer localement dépendances, escalade et règles de protection
* contrat payload stable obligatoire:
  * `user_feature_enabled`
  * `effective_feature_enabled`
  * `feature_governance`
  * `core_v1_global_features`
* réponses:
  * `200` succès
  * `401 UNAUTHORIZED`

`PATCH /auth/me/features`

* security: `UserBearerAuth`
* body requis: `{ user_feature_enabled: { ... } }`
* effet: met à jour les préférences feature de l’utilisateur courant
* contrainte: tentative de désactivation d’une feature `CORE_V1_GLOBAL` refusée (`403 FORBIDDEN_SCOPE`)
* réponses:
  * `200` succès
  * `401 UNAUTHORIZED`
  * `403 FORBIDDEN_SCOPE`
  * `422 VALIDATION_FAILED`

`GET /app/policy`

* security: `UserBearerAuth` ou `TechnicalBearerAuth`
* paramètre optionnel: `client_feature_flags_contract_version`
* effet: retourne `server_policy` (incluant `feature_flags`) pour clients interactifs et techniques
* règle: `UI_WEB`, `AGENT` et `MCP` DOIVENT consommer cet endpoint pour la disponibilité runtime des features
* versionnement: Core retourne la version effective servie et le mode `STRICT|COMPAT`
* réponses:
  * `200` succès
  * `401 UNAUTHORIZED`
  * `426 UNSUPPORTED_FEATURE_FLAGS_CONTRACT_VERSION`

`POST /app/policy`

* security: `UserBearerAuth`
* prérequis authz: acteur admin (contrôlé par la matrice [`AUTHZ-MATRIX.md`](../policies/AUTHZ-MATRIX.md))
* body requis: `{ feature_flags: { ... } }`
* effet: met à jour les `feature_flags` runtime globaux quand ils sont persistés dans un backend mutable (DB ou équivalent)
* contrainte: toute tentative de mutation d'un flag encore `code-backed` DOIT échouer avec `409 STATE_CONFLICT`
* réponses:
  * `200` succès
  * `401 UNAUTHORIZED`
  * `403 FORBIDDEN_ACTOR` ou `FORBIDDEN_SCOPE`
  * `409 STATE_CONFLICT`
  * `422 VALIDATION_FAILED`

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
* contrainte: un `client_kind=UI_WEB` est protégé et NE DOIT PAS être révocable via cet endpoint
* réponses:
  * `200` token(s) invalide(s)
  * `401 UNAUTHORIZED`
  * `403 FORBIDDEN_ACTOR` ou `FORBIDDEN_SCOPE` (selon matrice, incluant le cas token UI protégé)
  * `422 VALIDATION_FAILED`

`POST /auth/clients/token`

* security: aucune (`security: []`)
* body requis: `{ client_id, client_kind, secret_key }`
* `client_kind` autorisé: `AGENT` (`UI_WEB` et `MCP` exclus)
* effet: émet un bearer token technique pour `AGENT_TECHNICAL`
* règle stricte: **1 token actif par client_id** (mint d’un nouveau token => révocation de l’ancien token pour ce client)
* réponses:
  * `200` token client (`access_token`, `token_type=Bearer`, `expires_in?`, `client_id`, `client_kind`)
  * `401 UNAUTHORIZED` (credentials client invalides)
  * `403 FORBIDDEN_ACTOR` (`client_kind` interactif ou `MCP` refusé)
  * `422 VALIDATION_FAILED`
  * `429 TOO_MANY_ATTEMPTS`

`POST /auth/clients/device/start`

* security: aucune (`security: []`)
* body requis: `{ client_kind }` avec `client_kind=AGENT`
* effet: démarre un flow d’autorisation device type GitHub pour bootstrap `AGENT_TECHNICAL`
* réponses:
  * `200` (`device_code`, `user_code`, `verification_uri`, `verification_uri_complete`, `expires_in`, `interval`)
  * `403 FORBIDDEN_ACTOR`
  * `422 VALIDATION_FAILED`
  * `429 TOO_MANY_ATTEMPTS`

`POST /auth/clients/device/poll`

* security: aucune (`security: []`)
* body requis: `{ device_code }`
* effet: récupère l’état du flow device
* réponses:
  * `200` avec `status in {PENDING, APPROVED, DENIED, EXPIRED}`
  * `APPROVED` retourne `client_id`, `client_kind=AGENT`, `secret_key` (one-shot)
  * `400 INVALID_DEVICE_CODE`
  * `422 VALIDATION_FAILED`
  * `429 SLOW_DOWN` ou `TOO_MANY_ATTEMPTS` (poll trop fréquent)

`POST /auth/clients/device/cancel`

* security: aucune (`security: []`)
* body requis: `{ device_code }`
* effet: annule un flow device en cours
* réponses:
  * `200` canceled
  * `400 INVALID_DEVICE_CODE` ou `EXPIRED_DEVICE_CODE`
  * `422 VALIDATION_FAILED`

Séquence normative bootstrap `AGENT_TECHNICAL` (obligatoire) :

1. client technique lance `POST /auth/clients/device/start`
2. client ouvre `verification_uri` (ou `verification_uri_complete`) dans le navigateur
3. utilisateur se connecte via UI
4. si 2FA est activée sur le compte, validation OTP obligatoire
5. utilisateur approuve explicitement la création de credential technique
6. client technique poll `POST /auth/clients/device/poll` jusqu’à `APPROVED`/`DENIED`/`EXPIRED`
7. en cas `APPROVED`, `secret_key` est retournée une seule fois, puis utilisée sur `POST /auth/clients/token`

Séquence normative bootstrap `MCP_TECHNICAL` (obligatoire) :

1. un utilisateur autorisé ouvre l'UI Core
2. le client MCP génère localement sa paire de clés asymétriques standard
3. l'utilisateur enregistre la clé publique du client MCP via `POST /auth/mcp/register`
4. si 2FA est activée sur le compte, validation OTP obligatoire
5. Core lie la clé publique MCP au compte/tenant autorisé et au client déclaré
6. le client MCP demande un challenge via `POST /auth/mcp/challenge`
7. le client MCP signe le challenge puis échange la preuve via `POST /auth/mcp/token`
8. le client MCP signe ensuite ses écritures sensibles avec sa clé privée locale
9. le client MCP NE DOIT PAS initier `POST /auth/login` ni `POST /auth/clients/device/*`

Matrice de migration v1 runtime (gelée) :

* `POST /auth/clients/device/poll` :
  * les clients DOIVENT lire l’état depuis le payload `200` (`status`)
  * les clients NE DOIVENT PLUS interpréter `401`/`403` pour piloter le state machine device flow
* `POST /auth/clients/token` :
  * `client_kind in {UI_WEB, MCP}` DOIT retourner `403 FORBIDDEN_ACTOR`
  * `422` n’est plus autorisé pour ce cas de refus

Règle de sécurité :

* création de `secret_key` `AGENT_TECHNICAL` sans validation UI utilisateur est interdite
* enregistrement ou rotation de clé publique `MCP_TECHNICAL` hors validation UI utilisateur est interdit

`POST /auth/mcp/register`

* security: `UserBearerAuth`
* body requis: `{ openpgp_public_key, openpgp_fingerprint }`
* body optionnel: `client_label`
* effet: enregistre un client `MCP_TECHNICAL` et sa clé publique asymétrique standard
* réponses:
  * `200` (`client_id`, `client_kind=MCP`, `openpgp_fingerprint`, `registered_at`)
  * `401 UNAUTHORIZED`
  * `403 FORBIDDEN_ACTOR|FORBIDDEN_SCOPE`
  * `409 STATE_CONFLICT`
  * `422 VALIDATION_FAILED`

`POST /auth/mcp/challenge`

* security: aucune (`security: []`)
* body requis: `{ client_id, openpgp_fingerprint }`
* effet: retourne un challenge court pour authentification technique `MCP_TECHNICAL`
* réponses:
  * `200` (`challenge_id`, `challenge`, `expires_in`)
  * `401 UNAUTHORIZED`
  * `422 VALIDATION_FAILED`
  * `429 TOO_MANY_ATTEMPTS`

`POST /auth/mcp/token`

* security: aucune (`security: []`)
* body requis: `{ client_id, openpgp_fingerprint, challenge_id, signature }`
* effet: vérifie la signature asymétrique du challenge puis émet un bearer token technique pour `MCP_TECHNICAL`
* réponses:
  * `200` token client (`access_token`, `token_type=Bearer`, `expires_in?`, `client_id`, `client_kind=MCP`)
  * `401 UNAUTHORIZED`
  * `403 FORBIDDEN_ACTOR|FORBIDDEN_SCOPE`
  * `422 VALIDATION_FAILED`
  * `429 TOO_MANY_ATTEMPTS`

`POST /auth/mcp/{client_id}/rotate-key`

* security: `UserBearerAuth`
* body requis: `{ openpgp_public_key, openpgp_fingerprint }`
* effet: remplace la clé publique active du client `MCP_TECHNICAL` et invalide les bearers techniques actifs associés
* réponses:
  * `200` (`client_id`, `client_kind=MCP`, `openpgp_fingerprint`, `rotated_at`)
  * `401 UNAUTHORIZED`
  * `403 FORBIDDEN_ACTOR|FORBIDDEN_SCOPE`
  * `409 STATE_CONFLICT`
  * `422 VALIDATION_FAILED`

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

* `UserBearerAuth` DOIT rester commun aux clients interactifs `UI_WEB` et `AGENT`
* `UI_WEB` utilise `WebAuthn` comme auth primaire pour obtenir ce bearer
* `AGENT_UI` utilise `POST /auth/login` dans un premier temps, puis PEUT adopter `WebAuthn` sans changer le contrat bearer
* le fallback `POST /auth/login` reste disponible pour les parcours de bootstrap/recovery interactifs
  * `401 UNAUTHORIZED`
  * `403 FORBIDDEN_ACTOR|FORBIDDEN_SCOPE`
  * `422 VALIDATION_FAILED`


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
* `q=texte` (optionnel, **v1**, recherche full-text sur `filename`, `notes`)
* `location_country=BE` (optionnel, filtre localisation)
* `location_city=Brussels` (optionnel, filtre localisation)
* `geo_bbox=min_lon,min_lat,max_lon,max_lat` (optionnel, filtre géospatial bbox)
* `sort=name|-name|created_at|-created_at|updated_at|-updated_at|captured_at|-captured_at|duration|-duration|media_type|-media_type|state|-state`
* `captured_at_from=2026-01-01T00:00:00Z` (optionnel, borne basse incluse sur `captured_at`)
* `captured_at_to=2026-01-31T23:59:59Z` (optionnel, borne haute incluse sur `captured_at`)
* `limit=50&cursor=...`

Règles `q=` :

* matching case-insensitive
* `q` ne modifie pas la sémantique des filtres (`state`, `media_type`, etc.)
* tri par défaut conservé (`sort`) ; pas de score implicite exposé en v1
* `q` DOIT utiliser un index de recherche dérivé compatible chiffrement (pas de plaintext de transcription en index)
* filtres localisation DOIVENT reposer sur index spatial dérivé; les valeurs GPS source restent chiffrées

Response :

* `items: AssetSummary[]`
* `next_cursor`

Règle :

* `AssetSummary.revision_etag` est le jeton canonique de précondition d'écriture sur l'asset
* `AssetSummary.updated_at` reste informatif pour l'affichage et l'audit

### GET `/assets/{uuid}`

Fiche détaillée d’un asset.

Response : `AssetDetail`

Header :

* `ETag: <revision_etag>` (même valeur que `summary.revision_etag`)

### PATCH `/assets/{uuid}` (humain)

Modifications humaines : tags/notes/custom fields + transitions d'état métier autorisées.

Précondition HTTP obligatoire :

* header `If-Match: <revision_etag>`

Body (exemple) :

* `tags: string[]`
* `notes: string`
* `fields: Record<string, any>`
* `state: DECISION_PENDING | DECIDED_KEEP | DECIDED_REJECT | ARCHIVED | REJECTED` (transition explicite)

Règles :

* refuse si `state == PURGED`
* `If-Match` DOIT reprendre exactement le `revision_etag` lu précédemment par le client sur l'asset
* la mutation exprime donc explicitement : "je me base sur cette révision" (`If-Match`) et "je veux arriver à cet état" (`state` et/ou metadata)
* si `If-Match` est absent, Core DOIT refuser avec `428 PRECONDITION_REQUIRED`
* si `If-Match` ne correspond plus au `revision_etag` courant de l'asset, Core DOIT refuser avec `412 PRECONDITION_FAILED`
* la réponse d'erreur `412 PRECONDITION_FAILED` DOIT inclure au minimum `details.current_revision_etag` et `details.current_state` pour permettre un rechargement propre côté client
* la multi-sélection UI (ex: ajout d'un keyword) DOIT envoyer des appels unitaires `PATCH /assets/{uuid}` (un par asset)
* transitions via `state` :
  * `DECISION_PENDING -> DECIDED_KEEP | DECIDED_REJECT`
  * `DECIDED_KEEP -> DECISION_PENDING | DECIDED_REJECT | ARCHIVED`
  * `DECIDED_REJECT -> DECISION_PENDING | DECIDED_KEEP | REJECTED`
* toute transition non listée DOIT être refusée (`409 STATE_CONFLICT`)
* mise à jour metadata (`tags/notes/fields`) et transition `state` peuvent être combinées dans un même `PATCH`
* toute mutation validée DOIT mettre à jour `updated_at` et `revision_etag`
* toute mutation validée DOIT être tracée dans l'historique de révisions de l'asset

### POST `/assets/{uuid}/reprocess` (humain)

Déclenche un reprocess explicite.

Précondition HTTP obligatoire :

* header `If-Match: <revision_etag>`

Effet (normatif) :

* autorisé uniquement si `state in {PROCESSED, ARCHIVED, REJECTED}`
* `If-Match` DOIT reprendre exactement le `revision_etag` lu précédemment par le client sur l'asset
* si `If-Match` est absent, Core DOIT refuser avec `428 PRECONDITION_REQUIRED`
* si `If-Match` ne correspond plus au `revision_etag` courant de l'asset, Core DOIT refuser avec `412 PRECONDITION_FAILED`
* la réponse d'erreur `412 PRECONDITION_FAILED` DOIT inclure au minimum `details.current_revision_etag` et `details.current_state`
* invalide les données de processing (facts, dérivés, transcript, suggestions) via version bump
* transition vers `READY`
* force la revue : retour à `DECISION_PENDING` après nouveau `PROCESSED`


## 3) Decisions (humain)

Les décisions humaines passent par `PATCH /assets/{uuid}` via le champ `state`.

Règles (strictes) :

* `state=DECIDED_KEEP|DECIDED_REJECT` pour poser une décision
* `state=DECISION_PENDING` pour annuler/clear une décision
* la multi-sélection UI (KEEP/REJECT) DOIT envoyer des appels unitaires `PATCH /assets/{uuid}` (un par asset)

### POST `/assets/{uuid}/reopen`

Précondition HTTP obligatoire :

* header `If-Match: <revision_etag>`

Effet :

* `ARCHIVED|REJECTED → DECISION_PENDING`
* `If-Match` DOIT reprendre exactement le `revision_etag` lu précédemment par le client sur l'asset
* si `If-Match` est absent, Core DOIT refuser avec `428 PRECONDITION_REQUIRED`
* si `If-Match` ne correspond plus au `revision_etag` courant de l'asset, Core DOIT refuser avec `412 PRECONDITION_FAILED`
* la réponse d'erreur `412 PRECONDITION_FAILED` DOIT inclure au minimum `details.current_revision_etag` et `details.current_state`


## 4) Agents

### POST `/agents/register`

Enregistre un agent (obligatoire avant claim de jobs).

Body :

* `agent_id`
* `agent_name`
* `agent_version`
* `openpgp_public_key` (clé publique OpenPGP armurée ASCII)
* `openpgp_fingerprint` (fingerprint OpenPGP canonique de la clé active)
* `os_name` (`linux|macos|windows`)
* `os_version`
* `arch` (`x86_64|arm64|armv7|other`)
* `capabilities: string[]` (voir [`CAPABILITIES.md`](../definitions/CAPABILITIES.md))
* `client_feature_flags_contract_version` (optionnel)
* `max_parallel_jobs` (suggestion)

Règles :

* `agent_id` identifie de manière stable une instance/install d'agent
* `agent_id` DOIT être un `UUIDv4` généré aléatoirement lors de la première initialisation de l'agent
* l'agent DOIT le générer une fois puis le persister localement
* l'agent DOIT le réutiliser à chaque register/reconnexion
* `client_id` identifie le client technique autorisé, généralement lié à l'utilisateur qui a connecté l'agent; plusieurs agents sur plusieurs machines PEUVENT partager le même `client_id`
* `agent_id` identifie l'instance réelle d'agent; deux machines distinctes ne DOIVENT PAS partager le même identifiant
* `agent_id` est l'identifiant public d'agent exposé par l'API
* Core PEUT maintenir un identifiant DB interne distinct, mais celui-ci DOIT rester interne et NE DOIT JAMAIS être exposé par l'API
* une réinstallation explicite ou une rotation volontaire d'identité agent PEUT générer un nouveau `agent_id`
* `agent_id` NE DOIT PAS être dérivé du hostname, d'une MAC address, d'un serial disque, d'un `machine-id` OS ni d'une caractéristique matérielle/réseau
* si deux agents actifs se présentent avec le même `agent_id`, Core DOIT autoriser la connexion/register, journaliser un conflit d'identité et exposer ce conflit dans les diagnostics ops; Core NE DOIT PAS invalider automatiquement l'une des deux sessions en v1
* l'agent DOIT générer une identité de clé `OpenPGP` lors de sa première initialisation et persister la clé privée localement
* la clé privée agent NE DOIT JAMAIS quitter l'agent ni être exposée par l'API
* `openpgp_public_key` et `openpgp_fingerprint` représentent la clé OpenPGP active enregistrée côté Core
* la clé OpenPGP agent DOIT utiliser des algorithmes conformes à [`GPG-OPENPGP-STANDARD.md`](../policies/GPG-OPENPGP-STANDARD.md)
* la rotation de clé DOIT être explicite; l'agent NE DOIT PAS régénérer silencieusement sa clé de signature
* `POST /agents/register` DOIT prouver la possession de la clé privée correspondant à la clé publique OpenPGP déclarée

Signature agent (normative) :

* les écritures agent -> Core DOIVENT être signées avec une signature **OpenPGP détachée** produite par une librairie standard
* endpoints concernés :
  * `POST /agents/register`
  * `POST /jobs/{job_id}/claim`
  * `POST /jobs/{job_id}/heartbeat`
  * `POST /jobs/{job_id}/submit`
  * `POST /jobs/{job_id}/fail`
  * `POST /assets/{uuid}/derived/upload/init`
  * `POST /assets/{uuid}/derived/upload/part`
  * `POST /assets/{uuid}/derived/upload/complete`
* chaque requête signée DOIT porter :
  * `X-Retaia-Agent-Id`
  * `X-Retaia-OpenPGP-Fingerprint`
  * `X-Retaia-Signature`
  * `X-Retaia-Signature-Timestamp`
  * `X-Retaia-Signature-Nonce`
* `X-Retaia-Agent-Id` DOIT correspondre au `agent_id` du bearer technique
* `X-Retaia-OpenPGP-Fingerprint` DOIT référencer la clé publique OpenPGP active enregistrée pour cet agent
* `X-Retaia-Signature` DOIT être une signature **OpenPGP détachée** valide de la chaîne canonique suivante :
  * méthode HTTP
  * path HTTP exact
  * `agent_id`
  * timestamp de signature
  * nonce unique
  * SHA-256 hexadécimal du body HTTP brut
* la chaîne canonique DOIT utiliser `\\n` comme séparateur de lignes et rester stable entre implémentations
* Core DOIT vérifier la signature via une librairie OpenPGP standard maintenue; aucune implémentation crypto maison n'est autorisée
* Core DOIT rejeter toute écriture signée si la signature est absente, invalide, expirée, rejouée ou si la clé active est révoquée/inconnue
* Core DOIT contrôler une fenêtre de fraîcheur bornée pour `X-Retaia-Signature-Timestamp` et empêcher le rejeu via `X-Retaia-Signature-Nonce`
* Core DOIT journaliser les échecs de vérification de signature comme événements sécurité

Response :

* `agent_id`
* `effective_capabilities: string[]` (capabilities retenues après policy Core)
* `capability_warnings[]` (raisons d’invalidation capability, ex: provider/modèle indisponible ou non autorisé)
* `server_policy` (quotas et règles serveur), incluant au minimum :

  * `min_poll_interval_seconds`
  * `max_parallel_jobs_allowed`
  * `allowed_job_types[]`
  * `feature_flags` (map runtime `flag_name -> boolean`, source de vérité Core)
  * `feature_flags_contract_version`
  * `accepted_feature_flags_contract_versions[]`
  * `effective_feature_flags_contract_version`
  * `feature_flags_compatibility_mode` (`STRICT|COMPAT`)
  * (optionnel) `quiet_hours`

Normes d’exécution agent (obligatoires) :

* un agent DOIT fournir `AGENT_UI` en mode `CLI` (mode headless Linux obligatoire)
* un agent PEUT aussi fournir `AGENT_UI` en mode `GUI` pour usage desktop
* si une `GUI` existe, elle DOIT offrir les mêmes fonctionnalités opérateur que la `CLI`
* la `CLI` DOIT réciproquement permettre les mêmes actions opérateur que la `GUI`
* les surfaces `CLI` et `GUI` DOIVENT déléguer au même moteur (mêmes capabilities, mêmes contraintes protocole)
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

* ne jamais retourner un asset avec `asset_move_lock` actif
* le serveur peut limiter la liste (pagination, quotas)

### POST `/jobs/{job_id}/claim`

Claim atomique d’un job.

Headers obligatoires :

* `X-Retaia-Agent-Id`
* `X-Retaia-OpenPGP-Fingerprint`
* `X-Retaia-Signature`
* `X-Retaia-Signature-Timestamp`
* `X-Retaia-Signature-Nonce`

Response :

* `200` + `Job` (avec `lock_token`, `locked_until`) si claim accepté
* `409 STATE_CONFLICT` si job déjà claimé, non compatible ou non claimable

Règles :

* lock + TTL obligatoires
* pour un `claim` accepté (`200`), la réponse DOIT inclure un `source` locator :
  * `storage_id` (identifiant logique du storage, stable côté Core)
  * `original_relative` (chemin relatif du média principal)
  * `sidecars_relative[]` (chemins relatifs des sidecars)
* `source.*` DOIT rester relatif (jamais de chemin absolu NAS/hôte/conteneur)
* `source.*` NE DOIT PAS contenir de parent traversal (`..`) ni de null byte
* l’agent DOIT résoudre `source` via sa configuration locale de montages, jamais via une inférence locale sur le path Core

### POST `/jobs/{job_id}/heartbeat`

Body :

* `lock_token`

Headers obligatoires :

* `X-Retaia-Agent-Id`
* `X-Retaia-OpenPGP-Fingerprint`
* `X-Retaia-Signature`
* `X-Retaia-Signature-Timestamp`
* `X-Retaia-Signature-Nonce`

Response :

* `locked_until`

### POST `/jobs/{job_id}/submit`

Body :

* `lock_token`
* `job_type`
* `result: ProcessingResultPatch`

Headers obligatoires :

* `X-Retaia-Agent-Id`
* `X-Retaia-OpenPGP-Fingerprint`
* `X-Retaia-Signature`
* `X-Retaia-Signature-Timestamp`
* `X-Retaia-Signature-Nonce`

Effets :

* `extract_facts | generate_proxy | generate_thumbnails | generate_audio_waveform` :
  mise à jour des domaines `facts/derived`, puis `PROCESSING_REVIEW → PROCESSED → DECISION_PENDING` quand le profil est complet

Note v1 (important) :

* `ProcessingResultPatch` ne transporte pas les binaires.
* Les binaires (proxies/thumbs/waveforms) sont uploadés via l’API Derived.
* `submit` référence les dérivés déjà uploadés.
* Le serveur applique un merge partiel par domaine ; un job ne peut pas écraser les domaines qu'il ne possède pas.
* `generate_audio_waveform` est obligatoire pour les profils audio qui l'exigent ; l’absence de `waveform` dérivée rend le résultat de processing incomplet.
* ownership de patch par `job_type` :
  * `extract_facts` -> `facts_patch`
  * `generate_proxy|generate_thumbnails|generate_audio_waveform` -> `derived_patch`

Règle d'extension:

* les `job_type` IA (`transcribe_audio`, `suggest_tags`) et leurs patch domains sont hors périmètre v1 et documentés dans le paquet normatif v1.1.

### POST `/jobs/{job_id}/fail`

Body :

* `lock_token`
* `error_code`
* `message`
* `retryable: boolean`

Headers obligatoires :

* `X-Retaia-Agent-Id`
* `X-Retaia-OpenPGP-Fingerprint`
* `X-Retaia-Signature`
* `X-Retaia-Signature-Timestamp`
* `X-Retaia-Signature-Nonce`


## 6) Derived (proxies/dérivés)

Principe v1 :

* les dérivés sont **uploadés via HTTP** par les agents
* l’UI y accède via HTTP (URLs stables), pas via SMB
* pour tout asset avec piste audio exploitable, `waveform_url` DOIT être présent pour tout état métier au-delà de `READY`
* un asset audio NE DOIT PAS dépasser `READY` si la waveform dérivée obligatoire n’est pas disponible
* un rendu local waveform côté client PEUT exister comme dégradation UX de lecture, mais NE REMPLACE PAS l’obligation de dérivé serveur/agent
* toutes les écritures agent -> Core sur `/assets/{uuid}/derived/upload/*` DOIVENT porter les headers de signature agent

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

### Profils de formats dérivés (normatif)

Objectif :

* tous les dérivés consommés par l'UI DOIVENT être lisibles par un navigateur moderne (desktop/mobile)
* les proxies DOIVENT privilégier la compatibilité de lecture plutôt que l'optimisation codec agressive

`proxy_video` (obligatoire pour vidéo) :

* conteneur : `MP4` (`video/mp4`)
* codec vidéo : `H.264/AVC` (`yuv420p`, progressif, non interlacé)
* codec audio (si piste audio présente) : `AAC-LC` (`audio/mp4`, 44.1kHz ou 48kHz)
* finalité : proxy de review navigateur, pas master intermédiaire
* framerate : DOIT conserver le framerate source (tolérance max ±0.01 fps)
* cadence : DOIT rester en `CFR` (constant frame rate) pour stabilité seek/timeline
* dimensions :
  * ratio d'aspect conservé, upscale interdit
  * hauteur cible recommandée `720px`
  * si la source est plus petite, conserver la hauteur source
* bitrate vidéo :
  * cible recommandée `2.5 Mbps`
  * plage tolérée `1.5 Mbps` à `4 Mbps`
* keyframe interval : maximum 2 secondes
* fichier MP4 : `moov` atom placé en tête (fast start)
* audio :
  * stéréo maximum
  * downmix multicanal autorisé pour compatibilité navigateur
  * bitrate audio recommandé `128 kbps`

`proxy_audio` (obligatoire pour audio) :

* conteneur : `M4A` (`audio/mp4`) ou `MP3` (`audio/mpeg`)
* codec recommandé : `AAC-LC` (fallback `MP3` autorisé)
* sample rate : conserver la source si standard navigateur, sinon normaliser en 44.1kHz ou 48kHz
* canaux : conserver mono/stéréo source (downmix explicite autorisé si documenté)

`proxy_photo` (obligatoire pour image) :

* format : `JPEG` (`image/jpeg`) ou `WEBP` (`image/webp`)
* espace couleur : `sRGB`
* orientation EXIF : normalisée (image visuellement orientée, pas de dépendance EXIF runtime)
* dimensions : ratio d'aspect conservé, upscale interdit

`thumb` :

* format : `JPEG` (`image/jpeg`) ou `WEBP` (`image/webp`)
* espace couleur : `sRGB`
* taille preview par défaut : largeur `480px`
* taille preview secondaire optionnelle : largeur `320px`
* ratio d'aspect conservé, upscale interdit
* qualité cible :
  * `JPEG` qualité recommandée `80`
  * `WEBP` qualité recommandée `75`
* pour une vidéo, le thumb principal DOIT provenir d'une frame représentative déterminée par `thumbnail_profile`
  * vidéo courte = durée `< 120s` ; thumb principal à `max(1s, 10% de la durée)`
  * vidéo longue = durée `>= 120s` ; thumb principal à `5% de la durée`, avec fallback à `20s` si `5% > 20s`
* si une heuristique légère détecte une frame noire ou de fondu au point cible, le moteur DOIT sélectionner une frame voisine plus représentative
* un mode `storyboard` PEUT exiger `10` thumbs répartis régulièrement sur la durée utile, incluant le thumb principal
* en mode `storyboard`, les thumbs DOIVENT être ordonnés chronologiquement

`waveform` :

* format : `JSON` (`application/json`) ou binaire léger documenté (`application/octet-stream`)
* si JSON :
  * amplitudes normalisées (0..1)
  * séquence ordonnée
  * métadonnées min (`duration_ms`, `bucket_count`)
  * structure recommandée : `{"duration_ms": ..., "bucket_count": ..., "samples": [...] }`
* génération :
  * bucketisation régulière sur toute la durée
  * `bucket_count` recommandé : `1000`
  * `bucket_count` minimum : `100`
  * chaque bucket DOIT être calculé avec une méthode stable pour toute l'implémentation (ex: pic absolu ou RMS)
* absence de `waveform` NE DOIT PAS bloquer l'UI (fallback waveform locale déjà normative)

Règle de cohérence source/dérivé (obligatoire) :

* un dérivé ne DOIT PAS modifier le sens temporel du média (pas d'inversion/cut implicite)
* les métadonnées techniques exposées (`duration`, `fps`, dimensions) DOIVENT être cohérentes avec le fichier livré


## 7) Apply decision (move unitaire)

Le Core n'expose pas de concept/ressource "bulk" ou "batch".
Le bulk est un concept UI : une sélection multiple sur laquelle l'UI prépare une même action.
Le Core suit uniquement l'état de chaque asset.
Pour KEEP/REJECT, la liste des décisions posées mais non appliquées correspond aux assets en `DECIDED_KEEP|DECIDED_REJECT`.
Pour les mutations metadata (ex: keywords), après confirmation UI et `PATCH`, le changement est déjà appliqué côté Core.
L'exécution Core est toujours par asset.
Toute action groupée DOIT être validée explicitement dans l'UI avant l'envoi des appels unitaires Core.

### PATCH `/assets/{uuid}` avec `state=ARCHIVED|REJECTED`

Applique la décision humaine déjà posée sur un asset.

Body :

* `state: ARCHIVED | REJECTED`

Effet :

* `DECIDED_KEEP -> ARCHIVED`
* `DECIDED_REJECT -> REJECTED`

Règles d'exécution :

* seuls les assets `DECIDED_KEEP` et `DECIDED_REJECT` sont éligibles
* côté UI, la sélection de décisions à appliquer correspond exactement aux assets `DECIDED_KEEP|DECIDED_REJECT` non encore appliqués
* lock exclusif par asset (fichier/rush) pendant l'opération filesystem
* release du lock asset après opération filesystem et avant transition d'état
* suffixe de collision obligatoire : `__{short_nonce}`
* un asset locké pour move n'est pas claimable pour processing
* `short_nonce` suit la spec [`NAMING-AND-NONCE.md`](../policies/NAMING-AND-NONCE.md)


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

* un asset sous `asset_move_lock` interdit : claim job, reprocess, reopen, decision write, purge
* `PURGED` interdit toute mutation
* `reprocess` est refusé si un lock move est actif sur l'asset
* `purge` est refusé si un job est `claimed` pour l'asset
* claim job : atomique, lease TTL obligatoire, heartbeat obligatoire pour jobs longs
* cycle de vie détaillé des verrous défini dans [`LOCK-LIFECYCLE.md`](../policies/LOCK-LIFECYCLE.md)

## 8.2) Diagnostic ingest (ops)

### GET `/ops/ingest/diagnostics`

Objectif :

* exposer les compteurs ingest sans dépendre des logs CLI
* fournir les derniers sidecars/proxies non rattachés pour debug ops

Response :

* `queued` (integer)
* `missing` (integer)
* `unmatched_sidecars` (integer)
* `latest_unmatched[]` :
  * `path` (relative path)
  * `reason` (`missing_parent | ambiguous_parent | disabled_by_policy`)
  * `detected_at` (UTC ISO-8601)

Règles :

* endpoint read-only
* aucune donnée sensible (pas de secret/token)
* exposition réservée aux rôles/scopes ops admin (`UserBearerAuth` + statut admin)

## 8.3) Readiness ops

### GET `/ops/readiness`

Objectif :

* exposer l'état de disponibilité opérationnelle côté API

Response :

* `status` (`ok|degraded|down`)
* `self_healing` :
  * `active` (`boolean`)
  * `deadline_at` (`ISO-8601 UTC` ou `null`)
  * `max_self_healing_seconds` (`300`)
* `checks[]` :
  * `name` (ex: `database`, `ingest_watch_path`, `storage_writable`, `migrations`)
  * `status` (`ok|fail`)
  * `message`

Règles de calcul (normatif) :

* `down` : le check `database` est `fail`
* `degraded` : `database=ok`, au moins un check critique (`ingest_watch_path`, `storage_writable`) est `fail`, `self_healing.active=true`, et `now < self_healing.deadline_at`
* `down` : `database=ok`, au moins un check critique est `fail`, et aucune auto-réparation active ne permet le retour à `ok` dans le délai borné
* `ok` : tous les checks critiques sont `ok`
* borne normative unique : `self_healing.max_self_healing_seconds = 300`

## 8.4) Locks ops

### GET `/ops/locks`

Objectif :

* lister les verrous actifs pour diagnostic concurrence

Query params :

* `asset_uuid?`
* `lock_type?`
* `limit?` (default `50`, max `200`)
* `offset?` (default `0`)

Response :

* `items[]` :
  * `id`
  * `asset_uuid`
  * `lock_type`
  * `actor_id`
  * `acquired_at`
  * `released_at?`
* `total`

Règles pagination :

* `items[]` correspond à la page demandée (`limit`/`offset`)
* `total` représente le total filtré avant pagination (pas seulement la taille de page)
* tri par défaut recommandé : `acquired_at DESC`
* authentification HTTP via `UserBearerAuth`, puis vérification du statut admin obligatoire

### POST `/ops/locks/recover`

Objectif :

* forcer la récupération des verrous stale via endpoint ops

Body :

* `stale_lock_minutes?` (default `30`)
* `dry_run?` (default `false`)

Validation attendue :

* les clients DOIVENT envoyer `stale_lock_minutes` en entier >= 1
* les implémentations peuvent coerce les types en v1; un durcissement explicite `400 VALIDATION_FAILED` est recommandé

Response :

* `stale_examined`
* `recovered`
* `dry_run`

Règle :

* authentification HTTP via `UserBearerAuth`, puis vérification du statut admin obligatoire

## 8.5) Job queue ops

### GET `/ops/jobs/queue`

Objectif :

* exposer backlog jobs pour diagnostic saturation agents

Response :

* `summary` :
  * `pending_total`
  * `claimed_total`
  * `failed_total`
* `by_type[]` :
  * `job_type`
  * `pending`
  * `claimed`
  * `failed`
  * `oldest_pending_age_seconds?`

Règle :

* authentification HTTP via `UserBearerAuth`, puis vérification du statut admin obligatoire

## 8.6) Agents ops

### GET `/ops/agents`

Objectif :

* lister les agents connus avec leur état runtime, leur job en cours, leur dernier job réussi et les éléments utiles au debug

Query params :

* `status?` (`online_idle|online_busy|stale`)
* `limit?` (default `50`, max `200`)
* `offset?` (default `0`)

Response :

* `items[]` :
  * `agent_id`
  * `client_id`
  * `agent_name`
  * `agent_version`
  * `os_name?`
  * `os_version?`
  * `arch?`
  * `status` (`online_idle|online_busy|stale`)
  * `identity_conflict` (`boolean`)
  * `last_seen_at`
  * `last_register_at`
  * `last_heartbeat_at?`
  * `effective_capabilities[]`
  * `capability_warnings[]`
  * `current_job?` :
    * `job_id`
    * `job_type`
    * `asset_uuid`
    * `claimed_at`
    * `locked_until`
  * `last_successful_job?` :
    * `job_id`
    * `job_type`
    * `asset_uuid`
    * `completed_at`
  * `last_failed_job?` :
    * `job_id`
    * `job_type`
    * `asset_uuid`
    * `failed_at`
    * `error_code`
  * `debug` :
    * `max_parallel_jobs`
    * `feature_flags_contract_version?`
    * `effective_feature_flags_contract_version?`
    * `server_time_skew_seconds?`
* `total`

Règles :

* endpoint read-only
* réservé aux rôles/scopes ops admin
* ne DOIT exposer aucun secret (`secret_key`, token, refresh token, credentials, path absolu local)
* `status=online_busy` si au moins une lease job active est détenue par l'agent
* `status=online_idle` si l'agent est vu comme actif sans job claimé
* `status=stale` si l'agent n'est plus vu actif au-delà de la fenêtre runtime serveur
* `last_successful_job` représente le dernier job soumis avec succès et accepté par Core
* `identity_conflict=true` si plusieurs agents actifs partagent le même `agent_id`
* tri par défaut recommandé : `last_seen_at DESC`
* l'authentification HTTP utilise `UserBearerAuth`, puis l'autorisation DOIT vérifier le statut admin de l'utilisateur

## 8.7) Ingest unmatched listing (ops)

### GET `/ops/ingest/unmatched`

Objectif :

* exposer la liste paginée des sidecars/proxies non rattachés

Query params :

* `reason?` (`missing_parent|ambiguous_parent|disabled_by_policy`)
* `since?` (UTC ISO-8601)
* `limit?` (default `50`, max `200`)

Validation :

* `reason` invalide -> `400 VALIDATION_FAILED`
* `since` invalide -> `400 VALIDATION_FAILED`

Règle :

* authentification HTTP via `UserBearerAuth`, puis vérification du statut admin obligatoire

Response :

* `items[]` :
  * `path`
  * `reason`
  * `detected_at` (UTC ISO-8601)
* `total`

## 8.7) Ingest targeted requeue (ops)

### POST `/ops/ingest/requeue`

Objectif :

* relancer l’enqueue ingest pour une cible précise sans relancer un scan global
* fournir une primitive ops pour recovery ciblé (asset unique ou path unique)

Request body :

* `asset_uuid?` (UUID)
* `path?` (relative path ingest)
* `include_sidecars?` (default `true`)
* `include_derived?` (default `true`)
* `reason` (string non vide)

Validation :

* au moins un de `asset_uuid` ou `path` DOIT être fourni
* `asset_uuid` invalide -> `400 VALIDATION_FAILED`
* `path` absolu ou unsafe (`..`) -> `400 VALIDATION_FAILED`
* `reason` vide -> `400 VALIDATION_FAILED`

Response (`202 Accepted`) :

* `accepted` (`true`)
* `target` :
  * `asset_uuid?`
  * `path?`
* `requeued_assets` (integer >= 0)
* `requeued_jobs` (integer >= 0)
* `deduplicated_jobs` (integer >= 0)


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
* `paths: { storage_id, original_relative, sidecars_relative[] }`
* `processing: { facts_done, thumbs_done, proxy_done, waveform_done, review_processing_version }`
* `derived: { proxy_video_url?, proxy_audio_url?, waveform_url?, thumbs[] }`
* `transcript: { status, text_preview?, updated_at? }`
* `decisions: { current?, history[] }`
* `audit: { path_history[], revision_history[] }`

`revision_history[]` (normatif) :

* `revision` (int >= 1)
* `is_current` (bool)
* `published_at` (UTC ISO-8601, nullable)
* `validation_status` (`VALIDATED | PENDING_VALIDATION | REJECTED`)

Règle :

* une révision peut être `VALIDATED` et publiée alors qu'une révision suivante est `PENDING_VALIDATION`

### Job

* `job_id`
* `job_type` (`extract_facts | generate_proxy | generate_thumbnails | generate_audio_waveform`)
* `asset_uuid`
* `lock_token`
* `locked_until`
* `source: { storage_id, original_relative, sidecars_relative[] }`

### ProcessingResultPatch

* `facts_patch?` (JSON partiel)
* `derived_patch?` (`derived_manifest` partiel)
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
* `426 UNSUPPORTED_FEATURE_FLAGS_CONTRACT_VERSION`
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
* Move apply : endpoint unitaire `PATCH /assets/{uuid}` avec `state=ARCHIVED|REJECTED`, lock par asset (multi-sélection gérée UI)
* Purge : purge unitaire v1 (+ multi-sélection UI possible plus tard, sans entité batch Core)
* Scopes : agents strictement limités aux scopes jobs (jamais décisions/moves/purge)
* Filtres `tags=` : tags humains uniquement
* Recherche full-text `q=` disponible
* Changement de décision KEEP/REJECT autorisé de façon directe
* Reprocess autorisé depuis `PROCESSED|ARCHIVED|REJECTED`

## 12) Décisions actées (v1.1)

* Introduction des capacités AI-powered (`transcribe_audio`, `suggest_tags`, patch domains IA, enrichissements `AssetDetail`)
* Introduction de `suggested_tags=` et `suggested_tags_mode=`
* Scope `suggestions:write` pour les flux AI dédiés
* Multi-sélection UI : envoi d'appels unitaires `PATCH /assets/{uuid}`

## 13) Points en suspens

* Purge multi-sélection UI : si nécessaire plus tard (toujours par appels unitaires Core)

## 14) Contrat snapshot local (`contracts/`) pour détecter le drift OpenAPI

Objectif :

* détecter tout changement de `api/openapi/v1.yaml` même sans version bump (`info.version` inchangé)

Règles normatives (tous les repos consommateurs : UI, core, agents, MCP, tooling CI) :

* chaque repo consommateur DOIT versionner un snapshot de contrat dans `contracts/`
* fichier minimum requis : `contracts/openapi-v1.sha256`
* la valeur DOIT être le hash SHA-256 calculé depuis `api/openapi/v1.yaml` de `retaia-docs`
* la CI DOIT échouer si le hash versionné localement ne correspond plus au hash de la spec courante (drift détecté)
* la mise à jour du hash DOIT être explicite dans une PR, via une commande dédiée (pas d’update implicite en pipeline)
* la CI DOIT aussi échouer si un endpoint/champ documenté dans `API-CONTRACTS.md` n'existe plus dans `openapi/v1.yaml` (gate de cohérence contrat/docs)

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

## 16) Workflow Git normatif (repos consommateurs)

Règles opposables (UI, core, agents, MCP, tooling) :

* toute branche de travail DOIT être synchronisée via `rebase` sur `master`
* les merge commits de synchronisation (`Merge branch 'master' into ...`) sont interdits
* l'historique PR DOIT rester linéaire avant merge
* en cas de conflit, la résolution DOIT être faite pendant le rebase
* gate CI obligatoire: job `branch-up-to-date` vert sur la PR avant merge
* la CI DOIT pouvoir bloquer une PR contenant un commit de merge de synchronisation

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
* [SECURITY-BASELINE.md](../policies/SECURITY-BASELINE.md)
* [CRYPTO-SECURITY-MODEL.md](../policies/CRYPTO-SECURITY-MODEL.md)
* [SEARCH-PRIVACY-INDEX.md](../policies/SEARCH-PRIVACY-INDEX.md)
* [RGPD-DATA-PROTECTION.md](../policies/RGPD-DATA-PROTECTION.md)
* [HOOKS-CONTRACT.md](../policies/HOOKS-CONTRACT.md)
* [ERROR-MODEL.md](ERROR-MODEL.md)
* [CODE-QUALITY.md](../change-management/CODE-QUALITY.md)
