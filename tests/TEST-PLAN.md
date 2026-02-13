# Test Plan — Normative Minimum (v1)

Ce document définit le minimum de tests opposables pour valider une implémentation Retaia.

## 1) State machine

Tests obligatoires :

* toutes transitions autorisées passent
* transitions interdites renvoient `409 STATE_CONFLICT`
* `PURGED` est terminal

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
* flag absent dans le payload runtime => traité comme `false`
* flags inconnus côté client => ignorés sans erreur
* flag désactivé => la feature est refusée explicitement avec un code normatif
* activation du flag active la feature sans régression sur les flux `v1`
* `server_policy` expose l’état effectif des flags utiles aux agents
* mapping des flags v1.1 conforme : `features.ai.suggest_tags`, `features.ai.suggested_tags_filters`, `features.decisions.bulk`
* `job_type=suggest_tags` sur `/jobs/{job_id}/submit` exige `jobs:submit` + `suggestions:write`
* client feature OFF => UI/action API de la feature interdite
* client feature ON => disponibilité immédiate sans redéploiement

Cas OFF/ON minimum :

* `features.ai.suggest_tags=OFF` : refus `job_type=suggest_tags`, `suggestions_patch` et actions UI associées
* `features.ai.suggest_tags=ON` : `suggest_tags` opérationnel sans impact sur les flux `v1`
* `features.ai.suggested_tags_filters=OFF` : filtres `suggested_tags*` non exposés/non envoyés
* `features.ai.suggested_tags_filters=ON` : filtres `suggested_tags*` utilisables
* `features.decisions.bulk=OFF` : `/decisions/preview` et `/decisions/apply` non utilisables
* `features.decisions.bulk=ON` : flux preview/apply utilisable

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
