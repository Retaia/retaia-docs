# AUDIT — retaia-docs

Audit documentaire et contractuel du repo `retaia-docs`, focalisé sur tout ce qui doit rester strictement aligné entre `Core`, `UI_WEB` et `Agent`.

Date d'audit : `2026-03-19`

## 1. Position de l'audit

Ce repo se présente comme la source de vérité normative du projet.

Références racines :

* [README.md](README.md)
* [GOLDEN-RULES.md](GOLDEN-RULES.md)
* [api/API-CONTRACTS.md](api/API-CONTRACTS.md)
* [tests/TEST-PLAN.md](tests/TEST-PLAN.md)

Conséquence :

* tout ce qui est partagé entre `Core`, `UI_WEB` et `Agent` doit être soit normé explicitement, soit interdit explicitement
* aucun comportement critique ne doit dépendre d'une interprétation locale de repo consommateur
* toute divergence de wording entre documents normatifs est un risque d'implémentation

## 2. Vérifications effectuées

Vérifications locales faites pendant l'audit :

* lecture du `README.md` racine et des docs normatives principales
* cartographie de la structure du repo
* lecture croisée des contrats partagés :
  * API
  * OpenAPI
  * machine à états
  * workflows
  * protocole agent
  * matrice authz
  * modèle d'erreur
  * observabilité
  * verrous
  * feature flags
  * profils de processing
  * capabilities
* vérification des liens internes markdown : pas de lien interne cassé détecté
* vérification des snapshots OpenAPI : `scripts/check-contract-drift.sh` passe

Limite :

* la validation OpenAPI via `docker run openapitools/openapi-generator-cli validate` n'a pas pu être rejouée localement faute d'accès au daemon Docker

## 3. Synthèse exécutive

Le corpus est déjà riche et couvre bien les domaines critiques partagés :

* auth et séparation identités humaines / techniques
* machine à états métier
* processing profiles, jobs et capabilities
* feature flags et gouvernance runtime
* lock lifecycle et idempotence
* contrats UI et protocole agent

En revanche, le repo n'est pas encore assez fermé pour une release `v1.0.0` sans ambiguïté.

Principaux constats :

* plusieurs règles normatives ne sont pas réellement enforceables par l'outillage du repo
* certains domaines partagés sont normés, mais pas jusqu'au niveau nécessaire pour empêcher deux implémentations compatibles "sur le papier" de diverger au runtime
* quelques contradictions documentaires existent déjà
* le statut normatif des documents n'est pas uniformisé
* la frontière entre contrat `v1` exécutable et futures extensions reste encore à clarifier sur certains domaines, même si seul `v1` est désormais publié en OpenAPI

## 4. Findings critiques

### 4.2 Secure SDLC encore partiellement matérialisé dans le repo

Le baseline Secure SDLC impose :

* SAST bloquant
* secret scanning bloquant
* Dependabot
* branch protection
* revue renforcée sur authn/authz/crypto
* PR template / checklist sécurité

Références :

* [policies/SECURE-SDLC.md](policies/SECURE-SDLC.md)
* [\.github/workflows/ci.yml](.github/workflows/ci.yml)

Constat :

* le repo versionne désormais un workflow sécurité, un template PR, une config Dependabot, un `CODEOWNERS` et des permissions CI minimales explicites
* la branch protection effective reste un contrôle GitHub externe non prouvé par le repo

Risque :

* une partie significative des exigences Secure SDLC est maintenant matérialisée
* le reliquat le plus important concerne les contrôles GitHub externes et les owners réels du dépôt

À normer / fermer avant `v1.0.0` :

* activer/prouver la branch protection et les checks requis côté GitHub
* garder la distinction explicite entre contrôles versionnés et contrôles GitHub externes

## 5. Domaines partagés bien couverts, mais encore insuffisamment fermés

### 5.1 Machine à états et transitions

Couverture existante :

* [state-machine/STATE-MACHINE.md](state-machine/STATE-MACHINE.md)
* [api/API-CONTRACTS.md](api/API-CONTRACTS.md)
* [api/openapi/v1.yaml](api/openapi/v1.yaml)
* [tests/TEST-PLAN.md](tests/TEST-PLAN.md)

Points forts :

* `REVIEW_PENDING_PROFILE` est bien intégré au contrat API
* `audio_undefined` est bien cadré comme profil transitoire
* les transitions interdites principales sont explicites

Points forts :

* matrice canonique `transition -> endpoint -> préconditions -> refus` désormais publiée
* `PROCESSED -> DECISION_PENDING` est explicitement réservé à Core
* visibilité UI minimale par état désormais fermée

### 5.2 Contrat de précondition optimiste (`ETag` / `If-Match`)

Couverture existante :

* [api/API-CONTRACTS.md](api/API-CONTRACTS.md)
* [api/openapi/v1.yaml](api/openapi/v1.yaml)
* [tests/TEST-PLAN.md](tests/TEST-PLAN.md)

Points forts :

* `revision_etag` est bien identifié comme jeton canonique
* `GET /assets/{uuid}` doit renvoyer `ETag`
* `PATCH /assets/{uuid}`, `POST /assets/{uuid}/reprocess`, `POST /assets/{uuid}/reopen` exigent `If-Match`

Points forts :

* transport `ETag` / `If-Match` désormais fermé côté liste et détail
* primauté du détail pour les préconditions d'écriture explicitement normée

### 5.3 Feature flags et résolution d'effectivité

Couverture existante :

* [api/API-CONTRACTS.md](api/API-CONTRACTS.md)
* [policies/FEATURE-RESOLUTION-ENGINE.md](policies/FEATURE-RESOLUTION-ENGINE.md)
* [tests/TEST-PLAN.md](tests/TEST-PLAN.md)

Points forts :

* distinction `feature_flags` / `app_feature_enabled` / `user_feature_enabled` / `capabilities`
* ordre d'évaluation explicite
* contrat de version du feature flags payload déjà posé
* registre canonique des clés partagées `v1.0.0` désormais publié

Points forts :

* payload canonique d'explication d'un `OFF` désormais exposé via `app_feature_explanations` / `effective_feature_explanations`

### 5.4 Auth technique et signature OpenPGP

Couverture existante :

* [api/API-CONTRACTS.md](api/API-CONTRACTS.md)
* [workflows/AGENT-PROTOCOL.md](workflows/AGENT-PROTOCOL.md)
* [api/openapi/v1.yaml](api/openapi/v1.yaml)
* [tests/TEST-PLAN.md](tests/TEST-PLAN.md)

Points forts :

* chaîne canonique signée bien décrite
* headers de signature bien nommés
* séparation `client_id` / `agent_id` / clé OpenPGP claire

Points forts :

* fenêtre de fraîcheur désormais fermée à `60s`
* rétention anti-rejeu des nonces fermée à `15 minutes`
* rejet canonique `401 UNAUTHORIZED` pour skew/rejeu
* règle explicite : la signature porte toujours sur les octets HTTP bruts réellement envoyés

### 5.4.b Claims, rotation et vérification des tokens encore insuffisamment fermées

Couverture existante :

* [policies/SECURITY-BASELINE.md](policies/SECURITY-BASELINE.md)
* [policies/KEY-MANAGEMENT.md](policies/KEY-MANAGEMENT.md)
* [api/openapi/v1.yaml](api/openapi/v1.yaml)
* [tests/TEST-PLAN.md](tests/TEST-PLAN.md)

Points forts :

* seul `UserBearerAuth` porte des claims JWT vérifiables et un `kid`
* `TechnicalBearerAuth` reste explicitement opaque
* le mécanisme `JWKS` est désormais classé comme exigence interne/Core, hors surface partagée REST `v1`
* durées de vie nominales désormais fermées :
  * `UserBearerAuth.access_token` = `15 minutes`
  * `UI_WEB.refresh_token` = `30 jours`
  * `TechnicalBearerAuth.access_token` = `24 heures`

### 5.5 Polling, retry, backoff, jitter

Couverture existante :

* [api/API-CONTRACTS.md](api/API-CONTRACTS.md)
* [workflows/AGENT-PROTOCOL.md](workflows/AGENT-PROTOCOL.md)
* [tests/TEST-PLAN.md](tests/TEST-PLAN.md)

Points forts :

* le modèle status-driven par polling est bien posé
* `429` implique backoff + jitter
* `POST /agents/register` renvoie `min_poll_interval_seconds`

Points forts :

* cadence canonique `GET /app/policy` = `30s`
* cadence canonique `GET /jobs` = `5s`, bornée par `server_policy.min_poll_interval_seconds`
* stratégie de `429` fermée : base `2s`, facteur `x2`, plafond `60s`, full jitter, reset après succès

### 5.6 Verrous, TTL, fencing token

Couverture existante :

* [policies/LOCK-LIFECYCLE.md](policies/LOCK-LIFECYCLE.md)
* [policies/LOCKING-MATRIX.md](policies/LOCKING-MATRIX.md)
* [api/API-CONTRACTS.md](api/API-CONTRACTS.md)
* [tests/TEST-PLAN.md](tests/TEST-PLAN.md)

Points forts :

* types de lock identifiés
* TTLs documentés
* `fencing_token` documenté
* transport `job_lease` désormais explicite avec `lock_token` + `fencing_token`

Points forts :

* matrice de recovery crash FS/DB désormais définie
* invariants de reprise idempotente désormais fermés

### 5.7 Jobs, capabilities et processing profiles

Couverture existante :

* [definitions/JOB-TYPES.md](definitions/JOB-TYPES.md)
* [definitions/CAPABILITIES.md](definitions/CAPABILITIES.md)
* [definitions/PROCESSING-PROFILES.md](definitions/PROCESSING-PROFILES.md)
* [state-machine/STATE-MACHINE.md](state-machine/STATE-MACHINE.md)

Points forts :

* articulation job/profile/capability globalement bonne
* `audio_undefined` très bien cadré
* AI bien repoussée en `v1.1+`

Points forts :

* registre canonique `job_type -> required_capabilities -> outputs` désormais publié
* outputs structurants rattachés explicitement à leur job canonique
* projections runtime `facts`, `thumbnails`, `waveform`, `transcript` explicitées

### 5.7.c Contrat des hooks trop ouvert pour rester cross-project sûr

Références :

* [policies/HOOKS-CONTRACT.md](policies/HOOKS-CONTRACT.md)
* [api/API-CONTRACTS.md](api/API-CONTRACTS.md)

Constat :

* le contrat hook autorise `patches?`, mais il est désormais fermé en `v1` :
  * domaines autorisés limités à `fields` et `notes`
  * `blocking=true` limité à `after_processed_before_decision_pending`
  * échec d'un hook bloquant => `409 STATE_CONFLICT` + transition interrompue
* le risque principal n'est plus la sémantique runtime des hooks v1, mais l'extension future de ce mécanisme hors de ce périmètre fermé

Impact :

* le mécanisme v1 est maintenant suffisamment borné pour éviter des divergences majeures entre implémentations

Points forts :

* timeout max hook v1 désormais fermé à `2s`

### 5.8.d Contrats visibles UI encore décrits en prose, mais pas toujours reflétés dans OpenAPI

Constats :

* le contrat prose de `GET /assets` et des routes `derived` est plus précis qu'OpenAPI sur plusieurs points visibles côté client
* dès qu'OpenAPI est moins fermé que la prose sur une surface runtime, le repo laisse une marge d'interprétation aux implémentations

Règle à poser :

* toute surface HTTP consommée par `UI_WEB` ou `Agent` doit être fermée d'abord dans OpenAPI
* la prose peut expliquer, jamais porter seule le détail de transport

### 5.8.e Historique observable et révisions encore trop peu normés

Références :

* [api/API-CONTRACTS.md](api/API-CONTRACTS.md)
* [api/openapi/v1.yaml](api/openapi/v1.yaml)
* [definitions/DEFINITIONS.md](definitions/DEFINITIONS.md)
* [workflows/WORKFLOWS.md](workflows/WORKFLOWS.md)
* [tests/TEST-PLAN.md](tests/TEST-PLAN.md)

Constats :

* le mécanisme de persistance de l'historique peut rester un détail d'implémentation interne, y compris via des traits Doctrine ou `StofDoctrineExtensionsBundle`
* le contrat observable `audit.revision_history[]` est désormais fermé pour le runtime partagé :
  * ordre croissant de `revision`
  * append-only observable
  * `created_at` distinct de `published_at`
  * unicité de l'entrée `is_current=true`
  * lien explicite entre l'entrée courante et `summary.revision_etag`

Impact :

* la persistance interne reste libre, mais la vue runtime partagée ne devrait plus diverger sur les invariants principaux

Points forts :

* distinction entre historique métier exposé et traces techniques internes désormais explicite

### 5.8.f Endpoints ops/admin encore partiellement ouverts alors qu'ils sont partagés

Références :

* [api/API-CONTRACTS.md](api/API-CONTRACTS.md)
* [api/openapi/v1.yaml](api/openapi/v1.yaml)
* [policies/AUTHZ-MATRIX.md](policies/AUTHZ-MATRIX.md)
* [tests/TEST-PLAN.md](tests/TEST-PLAN.md)

Constats :

* plusieurs endpoints ops sont déjà consumables par une UI admin, donc ils font partie du contrat partagé et pas d'un simple détail backend
* les points les plus ambigus sont désormais fermés :
  * tri implicite canonique de `GET /ops/locks`
  * tri implicite canonique de `GET /ops/agents`
  * validation stricte de `stale_lock_minutes`
  * contrainte formelle `asset_uuid` ou `path` sur `POST /ops/ingest/requeue`

Impact :

* le contrat ops partagé est beaucoup moins sujet à divergence sur tri et validation
* le reliquat principal concerne maintenant surtout l'évolution future des payloads riches, pas leurs invariants actuels

À normer avant `v1.0.0` :

* garder ces invariants dans les payloads ops futurs et éviter toute réouverture implicite

### 5.9 Observabilité partagée

Couverture existante :

* [api/OBSERVABILITY-CONTRACT.md](api/OBSERVABILITY-CONTRACT.md)
* [policies/FEATURE-GOVERNANCE-OBSERVABILITY.md](policies/FEATURE-GOVERNANCE-OBSERVABILITY.md)
* [ops/OBSERVABILITY-TRIAGE.md](ops/OBSERVABILITY-TRIAGE.md)

Points forts :

* bonnes règles de redaction
* bon schéma minimal d'événement sécurité
* taxonomie minimale des événements opératoires cross-app désormais publiée

Points forts :

* présentation UI/Ops classée non normative en `v1`
* surface minimale obligatoire des événements affichés désormais fermée

### 5.9.b Observabilité de gouvernance de feature encore partiellement implicite

Références :

* [policies/FEATURE-GOVERNANCE-OBSERVABILITY.md](policies/FEATURE-GOVERNANCE-OBSERVABILITY.md)

Constat :

* le document impose des alertes sur "augmentation brutale", "façon anormale", "budget cible"
* aucun seuil normatif n'est défini
* la taxonomie des `reason_code` OFF est désormais fermée
* `actor_id` peut encore être "pseudonymisé si nécessaire" sans règle de pseudonymisation partagée

Points forts :

* seuils d'alerte minimaux désormais fermés
* règle commune de pseudonymisation désormais définie
* couplage obligatoire entre audit log et métriques désormais explicite

## 7. Zones de flou qui peuvent produire des divergences réelles

## 8. Backlog de normalisation avant `v1.0.0`

### Priorité P0

* Matérialiser ou requalifier les exigences Secure SDLC.

## 9. Ce qui est déjà suffisamment bien normé

Les points suivants sont globalement solides et réutilisables tels quels comme socle `v1` :

* séparation identité humaine / identité technique
* principe stateless/sessionless
* machine à états métier principale
* `audio_undefined` et `REVIEW_PENDING_PROFILE`
* bulk UI comme concept UI-only
* move/purge unitaires côté Core
* principe capability AND feature flag
* séparation `Core` source de vérité / push comme simple signal

## 10. Conclusion

Le repo est désormais proche d'un état `v1.0.0` fermable sur le plan documentaire partagé.

Les reliquats principaux ne sont plus nombreux, mais il en reste encore deux à fermer avant `v1.0.0` :

* branch protection effective
* preuve des checks requis côté dépôt GitHub

Le point central à retenir avant `v1.0.0` est désormais simple :

* le comportement partagé est documenté ici
* le repo outille désormais une partie significative de sa propre cohérence
* le dernier verrou critique restant est hors repo, côté configuration GitHub

## 11. Findings additionnels verbatim

### Findings

* `P1` Le Secure SDLC normatif reste partiellement non prouvé. Le repo versionne désormais un workflow sécurité, une config Dependabot, un template PR, un `CODEOWNERS` et des permissions CI minimales explicites, mais la branch protection effective reste à fermer côté GitHub. Tant qu’elle n’est pas établie, la chaîne Secure SDLC reste incomplète avant `v1.0.0`.


### Ce qui reste à normer avant `v1.0.0`

* Transformer les exigences Secure SDLC en contrôles réellement versionnés ou expliciter ce qui relève d’un réglage GitHub externe obligatoire.

### Vérifications faites

* `check-contract-drift` passe.
* Les liens internes du repo sont globalement résolus.
* Je n’ai pas pu valider OpenAPI via Docker localement car le daemon Docker n’était pas accessible, malgré un client Docker installé.
