# OpenAPI Version Files

This directory keeps one OpenAPI file per active or reserved API version track.

## Files

* `v1.yaml`: current runtime contract used by CI gates (`contract-drift` and `contracts/openapi-v1.sha256`)
* `v1.1.yaml`: planned minor version track
* `v1.2.yaml`: reserved non-planned track

## Governance

* Until v1 publication and gate switch, `v1.yaml` remains the executable source of truth.
* `v1.1.yaml` is the planned minor version track.
* `v1.2.yaml` is kept as a reserved non-planned track without implying active product commitment.
* Any intentional runtime contract change must still update `contracts/openapi-v1.sha256` when `v1.yaml` changes.
