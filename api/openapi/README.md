# OpenAPI Version Files

This directory keeps one OpenAPI file per active or reserved API version track.

## Files

* `v1.yaml`: current runtime contract used by CI gates (`contract-drift` and `contracts/openapi-v1.sha256`)
* `v1.1.yaml`: `v1.1+` track for MCP and AI-related capabilities when this phase is active
* `v1.2.yaml`: reserved non-planned track

## Governance

* `v1.yaml` est la référence exécutable opposable tant que les gates CI pointent vers ce fichier.
* `v1.1.yaml` is the `v1.1+` executable track for MCP and AI-related capabilities once this phase is opened.
* `v1.2.yaml` is kept as a reserved non-planned track without implying active product commitment.
* Any intentional runtime contract change must still update `contracts/openapi-v1.sha256` when `v1.yaml` changes.
