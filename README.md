# Retaia Docs

Source of truth for Retaia specifications.

## Golden Rules

These rules are the constitutional layer of the project. If a local implementation, a secondary document, or a convenience shortcut conflicts with them, the golden rules win.

Some of them are naturally more technical than others. That is intentional: they must stay understandable by a broad audience, but also precise enough to constrain architecture, security and runtime behavior.

1. Leak by design
2. Privacy by design
3. `retaia-docs` is the single source of truth for the whole project
4. Core is the single source of truth for business logic
5. NAS is storage only
6. The API must stay stateless and sessionless
7. Recognized concepts must use recognized libraries
8. Human and technical identities must stay separate
9. Runtime truth must always be re-read from Core; push only signals change
10. Feature flags govern runtime
11. The system must be safe by default
12. Sensitive actions must be authenticated, authorized and audited
13. Bulk belongs to the UI; Core stays unitary
14. Sensitive technical identity must be asymmetric

Canonical reference: [`GOLDEN-RULES.md`](GOLDEN-RULES.md)

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
- `retaia-agent` (processing client with local `AGENT_UI` for setup/control/debug, plus technical daemon)
- `retaia-mcp` (MCP orchestration client, no media processing)

## Quick links

- Product vision: [`vision/PROJECT-BRIEF.md`](vision/PROJECT-BRIEF.md)
- Golden rules: [`GOLDEN-RULES.md`](GOLDEN-RULES.md)
- Product roadmap: [`vision/ROADMAP.md`](vision/ROADMAP.md)
- Document index: [`DOCUMENT-INDEX.md`](DOCUMENT-INDEX.md)
- UI recommendations: [`ui/README.md`](ui/README.md)
- Agent client docs: [`agent/README.md`](agent/README.md)
- Operations runbooks: [`ops/README.md`](ops/README.md)
- Release gates: [`ops/RELEASE-GATES.md`](ops/RELEASE-GATES.md)
- UI global spec: [`ui/UI-GLOBAL-SPEC.md`](ui/UI-GLOBAL-SPEC.md)
- Deployment topology (NAS + workstations): [`architecture/DEPLOYMENT-TOPOLOGY.md`](architecture/DEPLOYMENT-TOPOLOGY.md)
- API contract: [`api/API-CONTRACTS.md`](api/API-CONTRACTS.md)
- OpenAPI sources:
  - [`api/openapi/v1.yaml`](api/openapi/v1.yaml) (runtime contract gate)
- Authz matrix: [`policies/AUTHZ-MATRIX.md`](policies/AUTHZ-MATRIX.md)
- Agent protocol: [`workflows/AGENT-PROTOCOL.md`](workflows/AGENT-PROTOCOL.md)
- Test plan: [`tests/TEST-PLAN.md`](tests/TEST-PLAN.md)
- Change management: [`change-management/CHANGE-MANAGEMENT.md`](change-management/CHANGE-MANAGEMENT.md)
- Contributing: [`CONTRIBUTING.md`](CONTRIBUTING.md)

## Documentation map

- Vision: [`vision/PROJECT-BRIEF.md`](vision/PROJECT-BRIEF.md)
- Roadmap: [`vision/ROADMAP.md`](vision/ROADMAP.md)
- Architecture: [`architecture/CONCEPTUAL-ARCHITECTURE.md`](architecture/CONCEPTUAL-ARCHITECTURE.md)
- Deployment profile: [`architecture/DEPLOYMENT-TOPOLOGY.md`](architecture/DEPLOYMENT-TOPOLOGY.md)
- State machine: [`state-machine/STATE-MACHINE.md`](state-machine/STATE-MACHINE.md)
- Domain definitions: [`definitions/DEFINITIONS.md`](definitions/DEFINITIONS.md)
- Job types: [`definitions/JOB-TYPES.md`](definitions/JOB-TYPES.md)
- Capabilities: [`definitions/CAPABILITIES.md`](definitions/CAPABILITIES.md)
- Security baseline: [`policies/SECURITY-BASELINE.md`](policies/SECURITY-BASELINE.md)
- RGPD: [`policies/RGPD-DATA-PROTECTION.md`](policies/RGPD-DATA-PROTECTION.md)
- UI docs: [`ui/README.md`](ui/README.md)
- Agent docs: [`agent/README.md`](agent/README.md)
- Operations docs: [`ops/README.md`](ops/README.md)

## Spec-first workflow

Changes must follow this order:

1. Update specs in `retaia-docs`.
2. Review and approve spec changes.
3. Implement in consumer repos (`core`, `ui`, `agent`, `mcp`).
4. Validate contract/runtime alignment through tests and CI gates.

## Versioning and governance

- v1 is contract-first and API stateless/sessionless.
- No legacy behavior before v1 publication.
- Feature lifecycle and compatibility are governed by specs/policies.
- Branch policy: rebase on `master`, linear history, PR-only integration.

## License

Licensed under the GNU Affero General Public License v3.0 or later (AGPL-3.0-or-later).
See [`LICENSE`](LICENSE).
