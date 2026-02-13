# Feature Resolution Engine (Normatif)

Ce document définit l'algorithme opposable de calcul `effective_feature_enabled`.

## 1) Entrées

* `feature_flags` (Core runtime)
* `app_feature_enabled` (admin global)
* `user_feature_enabled` (préférence utilisateur)
* `feature_governance[]` (`dependencies[]`, `disable_escalation[]`, `tier`, `user_can_disable`)
* `core_v1_global_features[]`

## 2) Ordre strict d'évaluation

1. `feature_flags`
2. `app_feature_enabled`
3. `user_feature_enabled` (clé absente => `true`)
4. dépendances (`dependencies[]`)
5. escalade de désactivation (`disable_escalation[]`)
6. garde finale `CORE_V1_GLOBAL`

## 3) Règles opposables

* une feature est ON uniquement si toutes les gates précédentes sont ON
* `app_feature_enabled=false` domine toujours le scope utilisateur
* `user_feature_enabled=false` impacte uniquement l'utilisateur courant
* si une dépendance est OFF, la feature dépendante est OFF
* si une feature parent est OFF, toute feature listée dans `disable_escalation[]` est OFF
* toute clé dans `core_v1_global_features[]` DOIT rester ON dans `effective_feature_enabled`
* tentative d'opt-out utilisateur d'une clé `CORE_V1_GLOBAL` => `403 FORBIDDEN_SCOPE`

## 4) Pseudo-code de référence

```text
for each feature_key:
  f = feature_flags.get(feature_key, false)
  a = app_feature_enabled.get(feature_key, true)
  u = user_feature_enabled.get(feature_key, true)
  effective[feature_key] = f && a && u

for each feature_key:
  for dep in dependencies(feature_key):
    if effective[dep] == false:
      effective[feature_key] = false

for each feature_key:
  if effective[feature_key] == false:
    for child in disable_escalation(feature_key):
      effective[child] = false

for each core_key in core_v1_global_features:
  effective[core_key] = true
```

## 5) Notes d'implémentation Core

* calcul déterministe (même input => même output)
* sans état caché côté serveur
* stable pour UI/Agent/MCP (pas de heuristique client)
* auditable (trace de la gate qui force OFF)
