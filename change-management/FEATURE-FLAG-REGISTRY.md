# Feature Flag Registry (Normatif)

Objectif : fournir le registre canonique des clés de feature partagées attendues en `v1.0.0`.

Ce registre est la source de vérité pour :

* `feature_flags`
* `app_feature_enabled`
* `user_feature_enabled`
* `feature_governance`
* `core_v1_global_features`

## 1) Règles générales

* toute clé partagée DOIT être déclarée ici avant implémentation
* le nom canonique suit `features.<domaine>.<fonction>`
* une clé absente de ce registre n'appartient pas au contrat canonique `v1.0.0`
* une clé `CORE_V1_GLOBAL` DOIT rester effective à `true`
* une clé non `CORE_V1_GLOBAL` PEUT être pilotée par `feature_flags`, `app_feature_enabled` et, si autorisé, `user_feature_enabled`
* un kill-switch permanent n'est autorisé que s'il apparaît aussi dans [`FEATURE-FLAG-KILLSWITCH-REGISTRY.md`](./FEATURE-FLAG-KILLSWITCH-REGISTRY.md)

## 2) Registre canonique `v1.0.0`

| Feature key | Tier | Admin mutable | User mutable | Dependencies | Disable escalation | Kill-switch permanent autorisé |
| --- | --- | --- | --- | --- | --- | --- |
| `features.core.auth` | `CORE_V1_GLOBAL` | Non | Non | - | - | Non |
| `features.core.assets.lifecycle` | `CORE_V1_GLOBAL` | Non | Non | `features.core.auth` | - | Non |
| `features.core.jobs.runtime` | `CORE_V1_GLOBAL` | Non | Non | `features.core.auth` | - | Non |
| `features.core.search.query` | `CORE_V1_GLOBAL` | Non | Non | `features.core.auth` | - | Non |
| `features.core.policy.runtime` | `CORE_V1_GLOBAL` | Non | Non | `features.core.auth` | - | Non |
| `features.core.derived.access` | `CORE_V1_GLOBAL` | Non | Non | `features.core.auth`, `features.core.assets.lifecycle` | - | Non |
| `features.core.clients.bootstrap` | `CORE_V1_GLOBAL` | Non | Non | `features.core.auth`, `features.core.policy.runtime` | - | Non |
| `features.ai.transcribe_audio` | `ROLLOUT_MUTABLE` | Oui | Oui | `features.core.jobs.runtime`, `features.core.assets.lifecycle` | - | Non |
| `features.ai.suggest_tags` | `ROLLOUT_MUTABLE` | Oui | Oui | `features.ai.transcribe_audio`, `features.core.jobs.runtime`, `features.core.assets.lifecycle` | - | Non |
| `features.mcp.runtime` | `ROLLOUT_MUTABLE` | Oui | Non | `features.core.auth`, `features.core.policy.runtime` | `features.mcp.ai.assistance` | Non |
| `features.mcp.ai.assistance` | `ROLLOUT_MUTABLE` | Oui | Oui | `features.mcp.runtime`, `features.ai.transcribe_audio` | - | Non |

## 3) Contraintes opposables

* `CORE_V1_GLOBAL` signifie :
  * clé présente dans `core_v1_global_features`
  * `feature_flags`, `app_feature_enabled` et `effective_feature_enabled` DOIVENT toutes la présenter à `true`
  * toute tentative de mutation admin/user sur cette clé DOIT être refusée
* `ROLLOUT_MUTABLE` signifie :
  * clé présente dans `feature_flags`
  * clé absente de `core_v1_global_features`
  * mutation admin autorisée seulement si `Admin mutable = Oui`
  * opt-out utilisateur autorisé seulement si `User mutable = Oui`
* `Dependencies` et `Disable escalation` DOIVENT rester alignées avec `feature_governance`
* aucune clé `v1.1+` ou pré-release n'est implicite : si elle n'est pas listée ici, elle n'existe pas pour le contrat partagé

## Références associées

* [FEATURE-RESOLUTION-ENGINE.md](../policies/FEATURE-RESOLUTION-ENGINE.md)
* [FEATURE-FLAG-LIFECYCLE.md](./FEATURE-FLAG-LIFECYCLE.md)
* [FEATURE-FLAG-KILLSWITCH-REGISTRY.md](./FEATURE-FLAG-KILLSWITCH-REGISTRY.md)
* [API-CONTRACTS.md](../api/API-CONTRACTS.md)
