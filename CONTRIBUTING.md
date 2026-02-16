# Contributing (retaia-docs)

## Scope
Ce repo est la source de vérité normative de Retaia.
Toute implémentation Core/UI/Agent/MCP doit suivre ces specs.

## Workflow Git
- Créer une branche depuis `master` (préfixe recommandé: `codex/`).
- Travailler en commits atomiques et intentionnels.
- Rebase sur `master` avant merge (pas de merge commit de synchronisation).
- PR atomique (un objectif clair par PR).
- Activer les hooks Husky (obligatoire en local):
  - `npm install`
  - `npm run prepare`
  - le hook `pre-commit` régénère automatiquement les snapshots OpenAPI **uniquement pour les specs modifiées**:
    - `contracts/openapi-v1.sha256`
    - `contracts/openapi-v1.1.sha256`
    - `contracts/openapi-v1.2.sha256`

## Exigences de PR
- Mettre à jour les documents normatifs impactés ensemble:
  - `api/openapi/v1.yaml`
  - `api/API-CONTRACTS.md`
  - `tests/TEST-PLAN.md`
  - policies/workflows associés si nécessaire
- Si un fichier `api/openapi/v*.yaml` change: mettre à jour les snapshots `contracts/openapi-*.sha256` (automatique via hook).
- Vérifier les gates CI obligatoires:
  - `branch-up-to-date`
  - `contract-drift`

## Règles de qualité
- Ne pas introduire de legacy non nécessaire avant publication v1.
- Maintenir la cohérence: authz, error model, feature governance, sécurité.
- Les règles MUST/SHOULD de la spec sont opposables.
- Approche préférée pour les implémentations: DDD, avec TDD + BDD.

## Licence des contributions
- Toute contribution est publiée sous `AGPL-3.0-or-later`.
- En soumettant une PR, vous acceptez que votre code et votre documentation soient distribués sous cette licence.
