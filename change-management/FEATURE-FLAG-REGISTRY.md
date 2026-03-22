# Feature Flag Registry (Normatif)

Objectif : fournir le registre canonique des clés de feature partagées attendues en `v1.0.0`.

Ce registre est la source de vérité pour :

* `feature_flags`
* `app_feature_enabled`
* `user_feature_enabled`
* `feature_governance`

## 1) Règles générales

* toute clé partagée DOIT être déclarée ici avant implémentation
* le nom canonique suit `features.<domaine>.<fonction>`
* une clé absente de ce registre n'appartient pas au contrat canonique `v1.0.0`
* seules les clés encore réellement variables au runtime restent dans le registre canonique actif
* une clé assimilée au comportement nominal NE DOIT PLUS être implémentée comme switch runtime ni réémise dans les payloads partagés
* un kill-switch permanent n'est autorisé que s'il apparaît aussi dans [`FEATURE-FLAG-KILLSWITCH-REGISTRY.md`](./FEATURE-FLAG-KILLSWITCH-REGISTRY.md)

## 2) Registre canonique `v1.0.0`

| Feature key | Tier | Admin mutable | User mutable | Dependencies | Disable escalation | Kill-switch permanent autorisé |
| --- | --- | --- | --- | --- | --- | --- |
| `features.ai.transcribe_audio` | `ROLLOUT_MUTABLE` | Oui | Oui | - | - | Non |
| `features.ai.suggest_tags` | `ROLLOUT_MUTABLE` | Oui | Oui | `features.ai.transcribe_audio` | - | Non |
| `features.mcp.runtime` | `ROLLOUT_MUTABLE` | Oui | Non | - | `features.mcp.ai.assistance` | Non |
| `features.mcp.ai.assistance` | `ROLLOUT_MUTABLE` | Oui | Oui | `features.mcp.runtime`, `features.ai.transcribe_audio` | - | Non |

## 3) Contraintes opposables

* `ROLLOUT_MUTABLE` signifie :
  * clé présente dans `feature_flags`
  * mutation admin autorisée seulement si `Admin mutable = Oui`
  * opt-out utilisateur autorisé seulement si `User mutable = Oui`
* `Dependencies` et `Disable escalation` DOIVENT rester alignées avec `feature_governance`
* aucune dépendance active NE DOIT pointer vers une clé `deprecated` assimilée au nominal
* aucune clé `v1.1+` ou pré-release n'est implicite : si elle n'est pas listée ici, elle n'existe pas pour le contrat partagé

## 4) Clés assimilées au nominal (`deprecated`, hors runtime)

Les clés suivantes ont servi d'étape de transition, mais sont désormais assimilées au comportement nominal `v1`. Elles ne font plus partie du registre canonique actif.

* `features.core.auth`
* `features.core.assets.lifecycle`
* `features.core.jobs.runtime`
* `features.core.search.query`
* `features.core.policy.runtime`
* `features.core.derived.access`
* `features.core.clients.bootstrap`

Contraintes :

* ces clés NE DOIVENT PLUS être émises dans `feature_flags`, `app_feature_enabled`, `user_feature_enabled`, `effective_feature_enabled` ni `feature_governance`
* `core_v1_global_features` ne fait plus partie du contrat runtime partagé
* toute tentative de mutation explicite de l'une de ces clés DOIT être refusée avec `422 VALIDATION_FAILED`

## Références associées

* [FEATURE-RESOLUTION-ENGINE.md](../policies/FEATURE-RESOLUTION-ENGINE.md)
* [FEATURE-FLAG-LIFECYCLE.md](./FEATURE-FLAG-LIFECYCLE.md)
* [FEATURE-FLAG-KILLSWITCH-REGISTRY.md](./FEATURE-FLAG-KILLSWITCH-REGISTRY.md)
* [API-CONTRACTS.md](../api/API-CONTRACTS.md)
