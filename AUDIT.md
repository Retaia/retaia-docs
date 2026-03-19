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

### 5.8 Contrat i18n partiellement hors transport OpenAPI

Références :

* [policies/I18N-LOCALIZATION.md](policies/I18N-LOCALIZATION.md)
* [api/API-CONTRACTS.md](api/API-CONTRACTS.md)
* [api/openapi/v1.yaml](api/openapi/v1.yaml)

Constat :

* la policy i18n indique que le client envoie `Accept-Language`
* OpenAPI ne déclare pas ce header
* le contrat API ne le ferme pas non plus au niveau transport

Impact :

* le comportement de localisation des messages reste implicite
* `UI_WEB` peut l'implémenter
* `Core` peut l'ignorer
* les tests contractuels n'ont pas de surface formelle à vérifier

Décision à prendre avant `v1.0.0` :

* ajouter `Accept-Language` au contrat OpenAPI des endpoints concernés
* ou retirer cette exigence du champ normatif v1 si elle n'est pas opposable

### 5.10 Révocation interactive par device/browser exigée, mais non contractuellement exposée

Références :

* [api/API-CONTRACTS.md](api/API-CONTRACTS.md)
* [policies/SECURITY-BASELINE.md](policies/SECURITY-BASELINE.md)
* [api/openapi/v1.yaml](api/openapi/v1.yaml)

Constat :

* le contrat prose dit que la révocation des tokens interactifs DOIT pouvoir se faire device/browser par device/browser sans impacter les autres
* la baseline sécurité dit que les refresh tokens interactifs doivent être tracés par device/browser
* aucun endpoint normatif visible ne permet :
  * de lister les sessions interactives
  * d'identifier les devices/browsers connus
  * de révoquer une session interactive autre que la session courante

Impact :

* une exigence partagée importante existe
* mais aucune surface API opposable ne permet de l'implémenter de façon homogène

Décision à prendre avant `v1.0.0` :

* soit ajouter un contrat explicite de gestion des sessions interactives
* soit réduire l'exigence normative actuelle
* mais l'état actuel laisse un trou de spécification cross-project

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

* format exact du header `ETag` :
  * valeur brute
  * ou valeur HTTP quotée
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

Reste à normer :

* registre canonique complet des clés de feature attendues en `v1.0.0`
* statut de chaque clé :
  * `CORE_V1_GLOBAL`
  * mutable admin
  * mutable user
  * dépendances
  * kill-switch autorisé ou non
* payload d'audit expliquant pourquoi une feature est `OFF`

Sans cela :

* `Core` peut calculer correctement l'effectif
* `UI_WEB` et `Agent` peuvent néanmoins diverger sur l'explication utilisateur et les surfaces masquées

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

### 6.4.c Session interactive et identité device/browser encore insuffisamment normées

Couverture existante :

* [api/API-CONTRACTS.md](api/API-CONTRACTS.md)
* [policies/SECURITY-BASELINE.md](policies/SECURITY-BASELINE.md)

Reste à normer :

* identité canonique d'un device/browser interactif
* relation entre `client_id` UI et session réelle utilisateur
* métadonnées minimales d'une session interactive :
  * nom device
  * user agent
  * dernière activité
  * créée le
  * révocable ou non
* endpoints normatifs :
  * lister les sessions
  * révoquer une session ciblée
  * révoquer toutes les autres sessions

Sans cela :

* la règle "révocable par device/browser" reste une intention, pas un contrat partagé

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

Reste à normer :

* où et comment `fencing_token` est exposé dans les payloads API concernés
* quels endpoints doivent le renvoyer / le consommer explicitement
* relation exacte entre `lock_token` métier et `fencing_token`
* règles de recovery détaillées après crash entre FS et DB

Sans cela :

* la policy de verrouillage est définie, mais son transport contractuel reste partiellement implicite

Constat additionnel :

* `LOCK-LIFECYCLE.md` rend `fencing_token` obligatoire
* ni `API-CONTRACTS`, ni `OpenAPI v1` ne l'exposent comme élément transporté

Conclusion :

* `fencing_token` est aujourd'hui une norme sans contrat d'échange
* il ne peut donc pas être implémenté de manière interopérable sans règle implicite dans les repos enfants

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

### 6.7.b Upload des dérivés encore partiellement laissé à l'implémentation

Références :

* [api/API-CONTRACTS.md](api/API-CONTRACTS.md)
* [api/openapi/v1.yaml](api/openapi/v1.yaml)

Constat :

* `derived/upload/part` dit explicitement "payload binaire (transport à préciser côté implémentation)"
* OpenAPI déclare seulement `upload_id` et `part_number`
* le protocole multipart réel n'est donc pas normé

Impact :

* un `Agent` et un `Core` peuvent chacun être "conformes" à des docs prose, tout en étant incompatibles au runtime

À normer avant `v1.0.0` :

* transport exact :
  * JSON + base64
  * `multipart/form-data`
  * body binaire brut
* format de `parts[]` au `complete`
* rôle exact de `etag` / checksum de part
* stratégie de reprise et d'idempotence des parts

### 6.7.c Contrat des hooks trop ouvert pour rester cross-project sûr

Références :

* [policies/HOOKS-CONTRACT.md](policies/HOOKS-CONTRACT.md)
* [api/API-CONTRACTS.md](api/API-CONTRACTS.md)

Constat :

* le contrat hook autorise `patches?`
* les "domaines autorisés non destructifs" ne sont pas listés
* la politique v1 est `fail-open`, sauf `blocking=true`
* mais le corpus ne définit pas :
  * qui peut marquer un hook `blocking`
  * quels hooks peuvent être bloquants
  * quel code d'erreur ou quel effet runtime est attendu si un hook bloquant échoue

Impact :

* un mécanisme serveur partagé influence le lifecycle métier
* mais ses règles de comportement restent partielles

À normer avant `v1.0.0` :

* registre canonique des patch domains autorisés
* statut exact des hooks bloquants autorisés en v1
* effet runtime exact d'un hook bloquant en échec
* exposition observabilité/audit correspondante

### 6.8.b Recherche, filtres et pagination assets encore insuffisamment fermés

Couverture existante :

* [api/API-CONTRACTS.md](api/API-CONTRACTS.md)
* [api/openapi/v1.yaml](api/openapi/v1.yaml)
* [policies/SEARCH-PRIVACY-INDEX.md](policies/SEARCH-PRIVACY-INDEX.md)
* [tests/TEST-PLAN.md](tests/TEST-PLAN.md)

Constats :

* le contrat prose dit `state=DECISION_PENDING (multi)`, mais OpenAPI déclare un unique paramètre `state` scalaire
* `tags=foo,bar` est décrit en prose, mais le mode d'encodage n'est pas normé :
  * CSV unique
  * répétition du paramètre
  * ordre significatif ou non
* `cursor` existe, mais sa sémantique n'est pas fermée :
  * opaque ou décodable
  * stable ou non en cas de mutations concurrentes
  * couplé ou non au tri courant
* le contrat mentionne que le tri par défaut est "conservé", mais sa valeur canonique n'est pas définie pour `GET /assets`
* `geo_bbox` est décrit comme string `min_lon,min_lat,max_lon,max_lat`, mais sans contrat de validation exact :
  * bornes numériques
  * ordre invalide
  * bbox traversant l'antiméridien

Impact :

* `Core` et `UI_WEB` peuvent diverger sur la construction des URLs, la pagination et la reprise de navigation
* deux implémentations peuvent être chacune "raisonnables" mais incompatibles

À normer avant `v1.0.0` :

* encodage canonique de chaque filtre multi-valeur
* valeur par défaut exacte de `sort`
* contrat formel de `cursor`
* validation exacte de `geo_bbox`
* relation normative entre pagination et stabilité d'ordre

### 6.8.c Delivery des dérivés encore trop peu contractuel

Couverture existante :

* [api/API-CONTRACTS.md](api/API-CONTRACTS.md)
* [api/openapi/v1.yaml](api/openapi/v1.yaml)
* [tests/TEST-PLAN.md](tests/TEST-PLAN.md)

Constats :

* le contrat prose dit que `GET /assets/{uuid}/derived` retourne les dérivés disponibles et leurs URLs
* OpenAPI déclare pour cette route un objet à `additionalProperties: true`, sans schéma stable
* `GET /assets/{uuid}/derived/{kind}` est normé en prose avec support Range requests pour audio/vidéo
* OpenAPI ne ferme pas :
  * les headers de réponse
  * le `content-type`
  * le comportement Range/206
  * les métadonnées de cache éventuelles

Impact :

* le contrat de delivery visible par `UI_WEB` reste partiellement laissé à l'implémentation
* les intégrations navigateur risquent de dépendre de comportements non spécifiés

À normer avant `v1.0.0` :

* schéma stable de `GET /assets/{uuid}/derived`
* headers de réponse minimaux par type de dérivé
* contrat Range pour preview audio/vidéo
* politique de `404` / `410` / `401` sur dérivés absents, purgés ou non autorisés

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
* en revanche le contrat observable `audit.revision_history[]` reste minimal au point d'être ambigu
* aujourd'hui la spec ferme seulement :
  * `revision`
  * `is_current`
  * `published_at`
  * `validation_status`
* elle ne ferme pas clairement :
  * l'ordre canonique de `revision_history[]`
  * si l'historique est strictement append-only
  * le lien exact entre `revision_history`, `ETag` courant et transition métier
  * la présence ou non d'un horodatage de création de révision distinct de `published_at`
  * la visibilité normative d'un acteur, d'une raison ou d'un type d'événement associé à une révision

Impact :

* deux implémentations peuvent conserver le même historique en base mais exposer des vues différentes au runtime
* `UI_WEB` peut afficher une chronologie, un badge "courant" ou un statut de publication différemment selon la forme retournée
* `Agent` ou outils ops ne peuvent pas déduire de façon portable la sémantique exacte d'une révision

À normer avant `v1.0.0` :

* laisser la persistance libre, mais fermer le contrat observable :
  * ordre de retour
  * champs minimaux
  * invariants append-only ou non
  * relation à `revision_etag`
  * relation entre `is_current`, `published_at` et `validation_status`
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

### 6.8.h.b `AssetSummary` et `AssetDetail` divergent déjà champ par champ

Références :

* [api/API-CONTRACTS.md](api/API-CONTRACTS.md)
* [api/openapi/v1.yaml](api/openapi/v1.yaml)
* [tests/TEST-PLAN.md](tests/TEST-PLAN.md)
* [definitions/PROCESSING-PROFILES.md](definitions/PROCESSING-PROFILES.md)

Constats :

* `AssetSummary` n'est pas identique entre prose et OpenAPI :
  * la prose liste `uuid`, `media_type`, `state`, `created_at`, `captured_at?`, `duration?`, `tags[]`, `has_preview`, `thumb_url?`
  * OpenAPI exige aussi `updated_at` et `revision_etag`, et expose `name`
* `AssetDetail.processing` diverge :
  * la prose liste `facts_done`, `thumbs_done`, `preview_done`, `waveform_done`, `review_processing_version`
  * OpenAPI ajoute `processing_profile`
* `AssetTranscript` diverge fortement :
  * la prose décrit `transcript: { status, text_preview?, updated_at? }`
  * OpenAPI ajoute `revision_etag`
  * OpenAPI le marque en plus "Pre-release field only. Outside v1 conformance scope"
* `AssetDecisions.history[]` reste trop vague :
  * OpenAPI ne requiert aucun champ dans chaque entrée
  * la prose ne ferme ni l'ordre, ni la forme minimale
* `AssetProcessing.processing_profile` est exposé sans enum ni lien machine direct avec la table canonique des profils

Impact :

* `Core`, `UI_WEB` et `Agent` ne partent pas du même objet métier exact
* un client qui suit la prose et un client qui génère ses types depuis OpenAPI n'obtiendront pas la même forme
* même sans blocage métier `v1`, `transcript` reste encore partiellement divergent entre prose et OpenAPI

À normer avant `v1.0.0` :

* aligner strictement `AssetSummary` prose / OpenAPI / tests
* décider explicitement si `name`, `updated_at` et `revision_etag` appartiennent au contrat minimal toujours présent
* typer `processing_profile` par enum partagée et le relier sans ambiguïté à `PROCESSING-PROFILES.md`
* fermer la structure minimale de chaque entrée `decisions.history[]`

### 6.8.j Contrat HTTP réellement opposable encore incomplet dans OpenAPI

Références :

* [api/API-CONTRACTS.md](api/API-CONTRACTS.md)
* [api/openapi/v1.yaml](api/openapi/v1.yaml)
* [policies/I18N-LOCALIZATION.md](policies/I18N-LOCALIZATION.md)
* [tests/TEST-PLAN.md](tests/TEST-PLAN.md)

Constats :

* la prose pose plusieurs règles HTTP partagées fortes
* OpenAPI n'en ferme qu'une partie
* écarts avérés :
  * `Accept-Language` est normé en policy, mais absent d'OpenAPI
  * `If-Match` est défini comme simple string, sans règle machine sur format quoted/unquoted
  * aucune règle OpenAPI n'indique si les URLs de dérivés peuvent être redirigées, signées, éphémères ou si la route Core doit toujours servir le contenu directement
  * les politiques de cache HTTP ne sont pas fermées sur les ressources dérivées ou l'asset detail

Impact :

* la prose décrit un contrat plus strict que le contrat machine réellement versionné
* un client peut implémenter `ETag`, `Range` ou localisation selon la prose, puis échouer face à une implémentation Core pourtant "conforme" à OpenAPI
* le risque de divergence est particulièrement fort sur navigateur, cache, streaming et rechargement optimiste

À normer avant `v1.0.0` :

 * déclarer les headers cross-project normatifs :
  * `Accept-Language`
  * `If-Match`
  * `ETag`
* fermer la politique de cache et de redirection des dérivés
* décider si les URLs de dérivés sont :
  * des URLs Core stables
  * des URLs signées temporaires
  * ou un autre modèle unique

### 6.8 Error model partagé

Couverture existante :

* [api/ERROR-MODEL.md](api/ERROR-MODEL.md)
* [api/API-CONTRACTS.md](api/API-CONTRACTS.md)
* [api/openapi/v1.yaml](api/openapi/v1.yaml)

Points forts :

* shape d'erreur commun bien cadré
* distinction `400` vs `422` déjà écrite

Reste à normer ou corriger :

* le mapping est présenté comme "recommandé" alors que plusieurs usages sont déjà traités comme normatifs ailleurs
* `RATE_LIMITED` apparaît dans le modèle d'erreur, mais le reste du corpus repose surtout sur `TOO_MANY_ATTEMPTS` et `SLOW_DOWN`
* `423 LOCK_REQUIRED|LOCK_INVALID` existe ici, mais le corpus partagé utilise majoritairement `409` pour les conflits de lock
* plusieurs réponses OpenAPI restent décrites de façon générique (`State conflict`, `Job not claimable`, `Invalid or missing lock`) sans fermer le `ErrorResponse.code` attendu par scénario
* le corpus mélange au moins trois familles proches sans table canonique exhaustive :
  * conflit d'état métier (`STATE_CONFLICT`)
  * lock manquant/invalide (`LOCK_REQUIRED`, `LOCK_INVALID`)
  * token de lock stale (`STALE_LOCK_TOKEN`)

Décision à prendre avant `v1.0.0` :

* soit fermer une table canonique de tous les `ErrorResponse.code`
* soit assumer un niveau de flexibilité, mais alors il faut l'annoncer clairement
* fermer explicitement la répartition `409` vs `423` par endpoint et par cause, notamment pour :
  * `jobs/{job_id}/submit`
  * `jobs/{job_id}/fail`
  * `jobs/{job_id}/heartbeat`
  * mutations asset avec concurrence ou lock

### 6.9 Observabilité partagée

Couverture existante :

* [api/OBSERVABILITY-CONTRACT.md](api/OBSERVABILITY-CONTRACT.md)
* [policies/FEATURE-GOVERNANCE-OBSERVABILITY.md](policies/FEATURE-GOVERNANCE-OBSERVABILITY.md)
* [ops/OBSERVABILITY-TRIAGE.md](ops/OBSERVABILITY-TRIAGE.md)

Points forts :

* bonnes règles de redaction
* bon schéma minimal d'événement sécurité

Reste à normer :

* événements non sécurité mais cross-app indispensables :
  * transition d'état asset
  * claim/release/fail job
  * reprocess
  * reopen
  * change `processing_profile`
  * purge
  * incompatibilité feature flags contract version
* taxonomie stable des `event_name` hors sécurité
* niveaux de sévérité et payload minimaux pour les événements opératoires

Sans cela :

* Core, UI et Agent partageront l'API, mais pas la lecture commune des incidents runtime

### 6.9.b Observabilité de gouvernance de feature encore partiellement implicite

Références :

* [policies/FEATURE-GOVERNANCE-OBSERVABILITY.md](policies/FEATURE-GOVERNANCE-OBSERVABILITY.md)

Constat :

* le document impose des alertes sur "augmentation brutale", "façon anormale", "budget cible"
* aucun seuil normatif n'est défini
* `actor_id` peut être "pseudonymisé si nécessaire" sans règle de pseudonymisation partagée

Impact :

* les métriques sont listées
* mais leur interprétation reste locale
* donc les applications et ops enfants devront réinventer une partie du contrat

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
* Fermer le contrat de transport des locks et `fencing_token`.
* Fermer la table canonique des `ErrorResponse.code`.
* Fermer le registre canonique des feature keys `v1.0.0`.
* Fermer le registre canonique des événements observabilité cross-app.
* Fermer la gestion normative des sessions interactives par device/browser.
* Fermer l'encodage, la pagination et le tri de `GET /assets`.
* Fermer le schéma et le transport de delivery des dérivés.
* Fermer le contrat observable de `revision_history` et son lien avec `revision_etag`.
* Rendre stricts les endpoints ops partagés : tri, validation, contraintes de payload.
* Fermer les règles de visibilité ou de redaction des sous-sections sensibles de `AssetDetail`.
* Corriger le contrat OpenAPI de `GET /assets/{uuid}` et fermer tous les headers HTTP réellement normatifs.
* Fermer la lecture partagée de `notes` / `fields` et le registre typé des champs métier partagés.
* Fermer la table canonique `HTTP status -> ErrorResponse.code -> endpoint/scénario`.

### Priorité P2

* Ajouter un lint docs pour les liens relatifs et le statut normatif.
* Remplacer les liens absolus locaux.
* Ajouter des checks de cohérence inter-docs simples.
* Uniformiser le vocabulaire `v1`, `v1.1+`, `phase validée`, `pre-release`.
* Fermer le protocole d'upload des dérivés.
* Déclarer dans OpenAPI les headers cross-project normatifs manquants comme `Accept-Language`.

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
