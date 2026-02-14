# Contributing (retaia-docs)

## Scope
Ce repo est la source de vérité normative de Retaia.
Toute implémentation Core/UI/Agent/MCP doit suivre ces specs.

## Workflow Git
- Créer une branche depuis `master` (préfixe recommandé: `codex/`).
- Travailler en commits atomiques et intentionnels.
- Rebase sur `master` avant merge (pas de merge commit de synchronisation).
- PR atomique (un objectif clair par PR).

## Exigences de PR
- Mettre à jour les documents normatifs impactés ensemble:
  - `api/openapi/v1.yaml`
  - `api/API-CONTRACTS.md`
  - `tests/TEST-PLAN.md`
  - policies/workflows associés si nécessaire
- Si `api/openapi/v1.yaml` change: mettre à jour `contracts/openapi-v1.sha256`.
- Vérifier les gates CI obligatoires:
  - `branch-up-to-date`
  - `contract-drift`

## Règles de qualité
- Ne pas introduire de legacy non nécessaire avant publication v1.
- Maintenir la cohérence: authz, error model, feature governance, sécurité.
- Les règles MUST/SHOULD de la spec sont opposables.
- Approche préférée pour les implémentations: DDD, avec TDD + BDD.
