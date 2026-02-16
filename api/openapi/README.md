# OpenAPI Version Files

This directory keeps one OpenAPI file per planned API version.

## Files

* `v1.yaml`: current runtime contract used by CI gates (`contract-drift` and `contracts/openapi-v1.sha256`)
* `v1.1.yaml`: planned minor version track
* `v1.2.yaml`: planned minor version track

## Governance

* Until v1 publication and gate switch, `v1.yaml` remains the executable source of truth.
* `v1.1.yaml` and `v1.2.yaml` are split files to prepare upcoming versions without modifying the v1 CI anchor.
* Any intentional runtime contract change must still update `contracts/openapi-v1.sha256` when `v1.yaml` changes.
