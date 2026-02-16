# Retaia Docs

Source of truth for Retaia specifications.

## Overview

`retaia-docs` defines the normative contracts and policies for the Retaia platform:

- API contracts (OpenAPI v1)
- security/authz policies
- workflows and state machine
- testing and release gates

When runtime behavior diverges from this repository, this repository is authoritative.

## Scope

The following consumer repositories must align with these specs:

- `retaia-core` (backend/API runtime)
- `retaia-ui` (user interface client)
- `retaia-agent` (CLI-first processing client)
- `retaia-mcp` (MCP orchestration client, no media processing)

## Quick links

- Product vision: [`vision/PROJECT-BRIEF.md`](vision/PROJECT-BRIEF.md)
- API contract: [`api/API-CONTRACTS.md`](api/API-CONTRACTS.md)
- OpenAPI source: [`api/openapi/v1.yaml`](api/openapi/v1.yaml)
- Authz matrix: [`policies/AUTHZ-MATRIX.md`](policies/AUTHZ-MATRIX.md)
- Agent protocol: [`workflows/AGENT-PROTOCOL.md`](workflows/AGENT-PROTOCOL.md)
- Test plan: [`tests/TEST-PLAN.md`](tests/TEST-PLAN.md)
- Change management: [`change-management/CHANGE-MANAGEMENT.md`](change-management/CHANGE-MANAGEMENT.md)
- Contributing: [`CONTRIBUTING.md`](CONTRIBUTING.md)

## Documentation map

- Architecture: [`architecture/CONCEPTUAL-ARCHITECTURE.md`](architecture/CONCEPTUAL-ARCHITECTURE.md)
- State machine: [`state-machine/STATE-MACHINE.md`](state-machine/STATE-MACHINE.md)
- Domain definitions: [`definitions/DEFINITIONS.md`](definitions/DEFINITIONS.md)
- Job types: [`definitions/JOB-TYPES.md`](definitions/JOB-TYPES.md)
- Capabilities: [`definitions/CAPABILITIES.md`](definitions/CAPABILITIES.md)
- Security baseline: [`policies/SECURITY-BASELINE.md`](policies/SECURITY-BASELINE.md)
- RGPD: [`policies/RGPD-DATA-PROTECTION.md`](policies/RGPD-DATA-PROTECTION.md)

## Spec-first workflow

Changes must follow this order:

1. Update specs in `retaia-docs`.
2. Review and approve spec changes.
3. Implement in consumer repos (`core`, `ui`, `agent`, `mcp`).
4. Validate contract/runtime alignment through tests and CI gates.

## Versioning and governance

- v1 is contract-first and Bearer-only.
- No legacy behavior before v1 publication.
- Feature lifecycle and compatibility are governed by specs/policies.
- Branch policy: rebase on `master`, linear history, PR-only integration.

## License

Licensed under the GNU Affero General Public License v3.0 or later (AGPL-3.0-or-later).
See [`LICENSE`](LICENSE).
