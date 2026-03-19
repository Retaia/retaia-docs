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

## 5. Incohérences documentaires avérées

## 6. Domaines partagés bien couverts, mais encore insuffisamment fermés

### 6.1 Machine à états et transitions

Couverture existante :

* [state-machine/STATE-MACHINE.md](state-machine/STATE-MACHINE.md)
* [api/API-CONTRACTS.md](api/API-CONTRACTS.md)
* [api/openapi/v1.yaml](api/openapi/v1.yaml)
* [tests/TEST-PLAN.md](tests/TEST-PLAN.md)

Points forts :

* `REVIEW_PENDING_PROFILE` est bien intégré au contrat API
* `audio_undefined` est bien cadré comme profil transitoire
* les transitions interdites principales sont explicites

Reste à normer :

* tableau canonique unique "transition x endpoint x code d'erreur x préconditions"
* règle explicite sur qui déclenche `PROCESSED -> DECISION_PENDING` si des hooks existent
* règle explicite sur la visibilité UI minimale par état, pour éviter une UI qui masque un état que Core expose

### 6.2 Contrat de précondition optimiste (`ETag` / `If-Match`)

Couverture existante :

* [api/API-CONTRACTS.md](api/API-CONTRACTS.md)
* [api/openapi/v1.yaml](api/openapi/v1.yaml)
* [tests/TEST-PLAN.md](tests/TEST-PLAN.md)

Points forts :

* `revision_etag` est bien identifié comme jeton canonique
* `GET /assets/{uuid}` doit renvoyer `ETag`
* `PATCH /assets/{uuid}`, `POST /assets/{uuid}/reprocess`, `POST /assets/{uuid}/reopen` exigent `If-Match`

Reste à normer :

* normalisation exacte du transport côté UI/Agent
* stratégie claire pour les clients qui mettent en cache des listes vs détail asset

### 6.3 Feature flags et résolution d'effectivité

Couverture existante :

* [api/API-CONTRACTS.md](api/API-CONTRACTS.md)
* [policies/FEATURE-RESOLUTION-ENGINE.md](policies/FEATURE-RESOLUTION-ENGINE.md)
* [tests/TEST-PLAN.md](tests/TEST-PLAN.md)

Points forts :

* distinction `feature_flags` / `app_feature_enabled` / `user_feature_enabled` / `capabilities`
* ordre d'évaluation explicite
* contrat de version du feature flags payload déjà posé
* registre canonique des clés partagées `v1.0.0` désormais publié

Reste à normer :

* payload d'audit expliquant pourquoi une feature est `OFF`

Sans cela :

* `Core` peut calculer correctement l'effectif
* `UI_WEB` et `Agent` peuvent encore diverger sur l'explication utilisateur d'un `OFF`, mais plus sur le registre canonique des clés partagées

### 6.4 Auth technique et signature OpenPGP

Couverture existante :

* [api/API-CONTRACTS.md](api/API-CONTRACTS.md)
* [workflows/AGENT-PROTOCOL.md](workflows/AGENT-PROTOCOL.md)
* [api/openapi/v1.yaml](api/openapi/v1.yaml)
* [tests/TEST-PLAN.md](tests/TEST-PLAN.md)

Points forts :

* chaîne canonique signée bien décrite
* headers de signature bien nommés
* séparation `client_id` / `agent_id` / clé OpenPGP claire

Reste à normer :

* valeur numérique de la fenêtre de fraîcheur de `X-Retaia-Signature-Timestamp`
* politique exacte de stockage / durée de rétention / portée de rejet des nonces anti-rejeu
* comportement exact en cas de clock skew :
  * tolérance
  * code d'erreur attendu
  * `retryable` attendu
* règle explicite d'encodage/normalisation si le body est sérialisé différemment par deux stacks

Sans cela :

* deux implémentations conformes "au sens large" peuvent diverger sur ce qui est considéré comme signature fraîche ou rejeu

### 6.4.b Claims, rotation et vérification des tokens encore insuffisamment fermées

Couverture existante :

* [policies/SECURITY-BASELINE.md](policies/SECURITY-BASELINE.md)
* [policies/KEY-MANAGEMENT.md](policies/KEY-MANAGEMENT.md)
* [api/openapi/v1.yaml](api/openapi/v1.yaml)
* [tests/TEST-PLAN.md](tests/TEST-PLAN.md)

Reste à normer :

* quels tokens portent réellement des claims JWT vérifiables
* quels tokens portent un `kid`
* si un endpoint `JWKS` public/interne fait partie du contrat v1
* stratégie de vérification pour les tokens techniques opaques
* durée de vie nominale des access tokens et refresh tokens
* politique de révocation par `jti`, par `kid`, ou par cardinalité seulement

Sans cela :

* les règles de rotation et de vérification restent partiellement infra-spécifiées

### 6.5 Polling, retry, backoff, jitter

Couverture existante :

* [api/API-CONTRACTS.md](api/API-CONTRACTS.md)
* [workflows/AGENT-PROTOCOL.md](workflows/AGENT-PROTOCOL.md)
* [tests/TEST-PLAN.md](tests/TEST-PLAN.md)

Points forts :

* le modèle status-driven par polling est bien posé
* `429` implique backoff + jitter
* `POST /agents/register` renvoie `min_poll_interval_seconds`

Reste à normer :

* cadence canonique minimale de refresh `GET /app/policy`
* cadence canonique de `GET /jobs`
* stratégie de backoff exacte :
  * base
  * max
  * jitter plein ou partiel
  * reset après succès
* comportement UI si la policy change entre deux écrans

Sans cela :

* `Agent` et `UI_WEB` peuvent être tous deux "compatibles" mais avoir des comportements runtime très différents

### 6.6 Verrous, TTL, fencing token

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

Reste à normer :

* règles de recovery détaillées après crash entre FS et DB

Sans cela :

* la policy de verrouillage est définie côté transport `job_lease`, mais le recovery inter-sous-systèmes reste encore partiellement implicite

Constat additionnel :

* `LOCK-LIFECYCLE.md` rend `fencing_token` obligatoire
* le transport `job_lease` est désormais fermé, mais pas encore les scénarios détaillés de reprise après crash

Conclusion :

* le trou principal résiduel n'est plus l'échange du `fencing_token`, mais la reprise normative après crash entre DB, locks et filesystem

### 6.7 Jobs, capabilities et processing profiles

Couverture existante :

* [definitions/JOB-TYPES.md](definitions/JOB-TYPES.md)
* [definitions/CAPABILITIES.md](definitions/CAPABILITIES.md)
* [definitions/PROCESSING-PROFILES.md](definitions/PROCESSING-PROFILES.md)
* [state-machine/STATE-MACHINE.md](state-machine/STATE-MACHINE.md)

Points forts :

* articulation job/profile/capability globalement bonne
* `audio_undefined` très bien cadré
* AI bien repoussée en `v1.1+`

Reste à normer :

* registre canonique machine-readable `job_type -> required_capabilities -> outputs`
* statut de version de chaque output structurant
* contrat exact de complétude utilisé par Core pour déclarer un asset "PROCESSED"
* payload minimal des `facts`, `waveform`, `thumbnails`, `transcript` dans OpenAPI de façon totalement isomorphe aux docs prose

Sans cela :

* `Core` peut déclarer un asset complet
* `UI_WEB` peut attendre plus
* `Agent` peut produire moins

### 6.7.c Contrat des hooks trop ouvert pour rester cross-project sûr

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

À normer avant `v1.0.0` :

* exposition observabilité/audit correspondante

### 6.8.d Contrats visibles UI encore décrits en prose, mais pas toujours reflétés dans OpenAPI

Constats :

* le contrat prose de `GET /assets` et des routes `derived` est plus précis qu'OpenAPI sur plusieurs points visibles côté client
* dès qu'OpenAPI est moins fermé que la prose sur une surface runtime, le repo laisse une marge d'interprétation aux implémentations

Règle à poser :

* toute surface HTTP consommée par `UI_WEB` ou `Agent` doit être fermée d'abord dans OpenAPI
* la prose peut expliquer, jamais porter seule le détail de transport

### 6.8.e Historique observable et révisions encore trop peu normés

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

À normer avant `v1.0.0` :

* distinguer explicitement :
  * historique métier partagé et normatif
  * traces techniques internes non exposées

### 6.8.f Endpoints ops/admin encore partiellement ouverts alors qu'ils sont partagés

Références :

* [api/API-CONTRACTS.md](api/API-CONTRACTS.md)
* [api/openapi/v1.yaml](api/openapi/v1.yaml)
* [policies/AUTHZ-MATRIX.md](policies/AUTHZ-MATRIX.md)
* [tests/TEST-PLAN.md](tests/TEST-PLAN.md)

Constats :

* plusieurs endpoints ops sont déjà consumables par une UI admin, donc ils font partie du contrat partagé et pas d'un simple détail backend
* pourtant plusieurs comportements restent ouverts :
  * `GET /ops/locks` : tri par défaut seulement "recommandé", pas normatif
  * `GET /ops/agents` : tri par défaut seulement "recommandé", pas normatif
  * `POST /ops/locks/recover` : la prose autorise encore une coercition de type en v1 alors qu'un schéma integer est déjà exposé
  * `POST /ops/ingest/requeue` : la prose impose "au moins un de `asset_uuid` ou `path`", mais cette contrainte n'est pas fermée formellement dans OpenAPI

Impact :

* deux implémentations Core peuvent être "conformes" tout en produisant des ordres d'affichage différents pour une même UI admin
* la politique de validation réelle peut diverger entre rejet strict et coercition tolérante
* les clients partagés ne savent pas si certaines erreurs relèvent d'un contrat dur ou d'une tolérance locale

À normer avant `v1.0.0` :

* rendre normatifs les tris par défaut des endpoints ops qui exposent des listes
* interdire les règles de coercition implicites sur les payloads partagés si OpenAPI expose déjà des types stricts
* encoder explicitement les contraintes de présence mutuelle ou alternative (`oneOf`, `anyOf`, règle équivalente) dans OpenAPI

### 6.8.g Matrice authz encore trop agrégée pour certaines données visibles

Références :

* [policies/AUTHZ-MATRIX.md](policies/AUTHZ-MATRIX.md)
* [api/API-CONTRACTS.md](api/API-CONTRACTS.md)
* [api/openapi/v1.yaml](api/openapi/v1.yaml)

Constats :

* la matrice authz est bien posée au niveau endpoint, scope et état
* en revanche, pour des payloads riches comme `AssetDetail`, elle ne dit pas explicitement si toutes les sous-sections sont toujours visibles de la même façon
* le contrat ne ferme pas clairement si des champs comme :
  * `paths`
  * `audit.path_history`
  * `audit.revision_history`
  * `decisions.history`
  * certaines URLs de dérivés
  peuvent être masqués, redacts ou filtrés selon l'acteur

Impact :

* un `Core` peut choisir de renvoyer l'objet complet
* un autre peut estimer qu'une partie du payload doit être masquée
* `UI_WEB` et `Agent` n'ont alors plus un contrat unique sur la forme réellement observable

À normer avant `v1.0.0` :

* soit déclarer que `AssetDetail` est intégralement visible dès que l'endpoint est autorisé
* soit fermer des règles de redaction/masquage champ par champ
* mais ne pas laisser cette décision aux repos consommateurs

### 6.8.h `AssetDetail` n'est pas assez fermé pour servir de contrat partagé stable

Références :

* [api/API-CONTRACTS.md](api/API-CONTRACTS.md)
* [api/openapi/v1.yaml](api/openapi/v1.yaml)
* [tests/TEST-PLAN.md](tests/TEST-PLAN.md)
* [ui/UI-UX-BRIEF-DESIGNER.md](ui/UI-UX-BRIEF-DESIGNER.md)

Constats :

* la prose présente `AssetDetail` comme un agrégat structuré de référence pour la review
* pourtant OpenAPI ne requiert que `summary` dans `AssetDetail`; `paths`, `processing`, `derived`, `decisions` et `audit` restent optionnels
* des sous-structures importantes restent elles aussi très ouvertes :
  * `AssetDecisions.history[]` n'impose aucun champ requis
  * `AssetAudit.path_history[]` est un simple tableau de strings, sans sémantique d'ordre ou de forme
  * `AssetDerived` ne ferme ni la présence minimale des URLs, ni leur type de cible, ni leur stabilité

Impact :

* deux implémentations Core peuvent renvoyer des `AssetDetail` très différents tout en restant conformes au schéma
* `UI_WEB` devra deviner quels blocs sont toujours présents, partiellement présents ou absents
* `Agent` et outils admin n'ont pas de vue suffisamment stable sur l'objet métier principal partagé

À normer avant `v1.0.0` :

* fermer quels sous-objets de `AssetDetail` sont obligatoires en lecture
* fermer la structure minimale de `decisions.history[]`
* fermer la sémantique et l'ordre de `path_history[]`
* fermer le statut des URLs de dérivés :
  * URL absolue ou relative
  * stable ou éphémère
  * servie directement ou via route Core

### 6.9 Observabilité partagée

Couverture existante :

* [api/OBSERVABILITY-CONTRACT.md](api/OBSERVABILITY-CONTRACT.md)
* [policies/FEATURE-GOVERNANCE-OBSERVABILITY.md](policies/FEATURE-GOVERNANCE-OBSERVABILITY.md)
* [ops/OBSERVABILITY-TRIAGE.md](ops/OBSERVABILITY-TRIAGE.md)

Points forts :

* bonnes règles de redaction
* bon schéma minimal d'événement sécurité
* taxonomie minimale des événements opératoires cross-app désormais publiée

Reste à normer :

* articulation explicite avec les écrans ops/UI si certains événements deviennent des surfaces utilisateur obligatoires

Sans cela :

* Core, UI et Agent partagent désormais le vocabulaire runtime minimal, mais pas encore forcément sa présentation UX finale

### 6.9.b Observabilité de gouvernance de feature encore partiellement implicite

Références :

* [policies/FEATURE-GOVERNANCE-OBSERVABILITY.md](policies/FEATURE-GOVERNANCE-OBSERVABILITY.md)

Constat :

* le document impose des alertes sur "augmentation brutale", "façon anormale", "budget cible"
* aucun seuil normatif n'est défini
* la taxonomie des `reason_code` OFF est désormais fermée
* `actor_id` peut encore être "pseudonymisé si nécessaire" sans règle de pseudonymisation partagée

Impact :

* les métriques et raisons canoniques existent
* mais les seuils d'alerte et la pseudonymisation restent locaux
* donc les applications et ops enfants devront encore interpréter une partie du contrat

À normer avant `v1.0.0` :

* seuils minimaux ou statut explicitement non normatif des alertes
* règle commune de pseudonymisation
* niveau d'obligation exact entre audit log et métriques

## 7. Zones de flou qui peuvent produire des divergences réelles

### 7.1 Fenêtres temporelles partiellement non chiffrées

Exemples :

* fraîcheur des signatures OpenPGP
* stratégie de rejeu des nonces
* cadence de certains pollings
* comportement de retry/backoff hors `device flow`

Constat :

* plusieurs règles sont qualitatives
* elles ne sont pas toujours chiffrées dans le contrat partagé

Risque :

* deux clients peuvent implémenter des marges différentes et rester "apparemment conformes"

### 7.2 Statuts normatifs mélangés avec des documents de cadrage

Constat :

* le repo alterne documents explicitement normatifs, non normatifs, et "préparation technique" sans index global unique

Risque :

* un repo consommateur peut s'aligner sur le mauvais document

Action :

* produire un index canonique de tous les documents avec :
  * statut
  * domaine
  * consommateur concerné
  * version concernée (`v1`, `v1.1+`, `reserved`)

### 7.3 Outillage de cohérence inter-docs insuffisant

Constat :

* il existe un drift check OpenAPI
* il n'existe pas de check similaire pour :
  * statut normatif des docs
  * registres de states
  * registres d'error codes
  * registres de feature keys
  * registres de routes UI

Risque :

* la cohérence repose sur revue humaine seule

### 7.4 Trop de "configurable" sur des comportements cross-project

Constat :

* plusieurs comportements visibles et partagés restent définis comme "configurables" ou "selon policy" sans valeur canonique ici
* exemples :
  * timeout max de hook
  * fraîcheur de signature
  * budget cible observabilité
  * stratégie de fallback provider
  * rétention de certaines clés/idempotency

Risque :

* les repos enfants seront forcés de définir eux-mêmes une partie du comportement partagé
* exactement ce que le golden rule 3 est censé empêcher

Action :

* distinguer explicitement :
  * `configurable mais borné par spec`
  * `local implementation detail`
  * `non normatif`
* tout paramètre cross-project doit avoir au minimum :
  * unité
  * valeur par défaut
  * borne min/max si mutable
  * surface d'exposition runtime si le client doit s'y adapter

## 8. Backlog de normalisation avant `v1.0.0`

### Priorité P0

* Dédupliquer [tests/TEST-PLAN.md](tests/TEST-PLAN.md).
* Matérialiser ou requalifier les exigences Secure SDLC.
* Ajouter un index canonique des documents avec statut normatif.

### Priorité P1

* Fermer numériquement les fenêtres temporelles partagées :
  * signature freshness
  * nonce anti-rejeu
  * polling
  * backoff
* Rendre stricts les endpoints ops partagés : tri, validation, contraintes de payload.
* Fermer les règles de visibilité ou de redaction des sous-sections sensibles de `AssetDetail`.
* Fermer la lecture partagée de `notes` / `fields` et le registre typé des champs métier partagés.

### Priorité P2

* Ajouter un lint docs pour les liens relatifs et le statut normatif.
* Remplacer les liens absolus locaux.
* Ajouter des checks de cohérence inter-docs simples.
* Uniformiser le vocabulaire `v1`, `v1.1+`, `phase validée`, `pre-release`.
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

Le repo est déjà un bon socle de spécification produit et runtime.

Il n'est pas en échec de conception.

En revanche, il lui manque encore plusieurs fermetures de contrat pour qu'aucune implémentation `Core`, `UI_WEB` ou `Agent` ne puisse dériver tout en se croyant conforme.

Le point central à retenir avant `v1.0.0` est simple :

* tout comportement partagé doit avoir une source unique
* toute source unique doit être explicitement normative
* toute règle normative critique doit être soit testée, soit outillée, soit impossible à interpréter autrement

Tant que ces trois conditions ne sont pas remplies sur les domaines listés ci-dessus, la promesse "single source of truth" reste partiellement déclarative.

## 11. Findings additionnels verbatim

### Findings

* `P1` Le Secure SDLC normatif reste partiellement non prouvé. Le repo versionne désormais un workflow sécurité, une config Dependabot, un template PR, un `CODEOWNERS` et des permissions CI minimales explicites, mais la branch protection effective reste à fermer côté GitHub. Tant qu’elle n’est pas établie, la chaîne Secure SDLC reste incomplète avant `v1.0.0`.


### Ce qui reste à normer avant `v1.0.0`

* Transformer les exigences Secure SDLC en contrôles réellement versionnés ou expliciter ce qui relève d’un réglage GitHub externe obligatoire.
* Clarifier la taxonomie de versions: `v1` runtime actuel, `v1.1+` extensions futures et pré-release sous feature flags.
* Ajouter des checks docs minimums pour une release de spec: liens relatifs, lint Markdown, et éventuellement drift entre documents normatifs majeurs.

### Vérifications faites

* `check-contract-drift` passe.
* Les liens internes du repo sont globalement résolus.
* Je n’ai pas pu valider OpenAPI via Docker localement car le daemon Docker n’était pas accessible, malgré un client Docker installé.
