# OpenAPI Version Files

This directory keeps the executable OpenAPI contract(s) that are currently normative.

## Files

* `v1.yaml`: current runtime contract used by CI gates (`contract-drift` and `contracts/openapi-v1.sha256`)

## Governance

* `v1.yaml` est la référence exécutable opposable tant que les gates CI pointent vers ce fichier.
* Les pistes futures (`v1.1+`, MCP, AI, autres extensions) peuvent être décrites dans les documents de vision, politiques et workflows, mais ne DOIVENT PAS être publiées ici comme contrat OpenAPI tant qu'elles ne sont pas stabilisées.
* Any intentional runtime contract change must still update `contracts/openapi-v1.sha256` when `v1.yaml` changes.
