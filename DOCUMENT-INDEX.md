# Document Index

Ce document est l'index canonique de tous les documents Markdown versionnés dans `retaia-docs`.

Il est **normatif** pour :

* le statut de chaque document
* son domaine principal
* les consommateurs qu'il contraint
* la version produit/API concernée

Statuts autorisés :

* `NORMATIVE`
* `NON_NORMATIVE`
* `PREPARATORY`
* `ROADMAP`
* `AUDIT`

| Path | Status | Domain | Consumers | Version |
| --- | --- | --- | --- | --- |
| `.github/pull_request_template.md` | `NON_NORMATIVE` | Repo governance | `CONTRIBUTORS` | `repo` |
| `AUDIT.md` | `AUDIT` | Audit | `CORE,UI_WEB,AGENT,OPS` | `2026-03-19` |
| `CONTRIBUTING.md` | `NORMATIVE` | Repo governance | `CONTRIBUTORS` | `repo` |
| `DOCUMENT-INDEX.md` | `NORMATIVE` | Repo governance | `CONTRIBUTORS,OPS` | `repo` |
| `GOLDEN-RULES.md` | `NORMATIVE` | Constitutional | `CORE,UI_WEB,AGENT,MCP,OPS` | `cross-version` |
| `README.md` | `NON_NORMATIVE` | Repo overview | `CONTRIBUTORS` | `repo` |
| `agent/CONFIGURATION-UX.md` | `NON_NORMATIVE` | Agent UX | `AGENT,AGENT_UI` | `v1` |
| `agent/DAEMON-OPERATIONS.md` | `NON_NORMATIVE` | Agent ops | `AGENT,AGENT_UI,OPS` | `v1` |
| `agent/DESKTOP-SHELL.md` | `NON_NORMATIVE` | Agent UX | `AGENT_UI` | `v1` |
| `agent/NOTIFICATIONS-UX.md` | `NON_NORMATIVE` | Agent UX | `AGENT_UI` | `v1` |
| `agent/README.md` | `NON_NORMATIVE` | Agent overview | `AGENT,AGENT_UI` | `v1` |
| `anti-patterns/ANTI-PATTERNS.md` | `NORMATIVE` | Governance | `CORE,UI_WEB,AGENT,MCP` | `cross-version` |
| `api/API-CONTRACTS.md` | `NORMATIVE` | API contract | `CORE,UI_WEB,AGENT,MCP` | `v1` |
| `api/ERROR-MODEL.md` | `NORMATIVE` | API contract | `CORE,UI_WEB,AGENT,MCP` | `v1` |
| `api/OBSERVABILITY-CONTRACT.md` | `NORMATIVE` | Observability | `CORE,UI_WEB,AGENT,MCP,OPS` | `v1` |
| `api/openapi/README.md` | `NON_NORMATIVE` | API overview | `CONTRIBUTORS` | `repo` |
| `architecture/CONCEPTUAL-ARCHITECTURE.md` | `NORMATIVE` | Architecture | `CORE,UI_WEB,AGENT,MCP,OPS` | `cross-version` |
| `architecture/DEPLOYMENT-TOPOLOGY.md` | `NORMATIVE` | Deployment | `CORE,UI_WEB,AGENT,OPS` | `v1` |
| `change-management/AI-ASSISTED-DEVELOPMENT.md` | `NORMATIVE` | Engineering process | `CONTRIBUTORS` | `repo` |
| `change-management/CHANGE-MANAGEMENT.md` | `NORMATIVE` | Engineering process | `CONTRIBUTORS,OPS` | `repo` |
| `change-management/CODE-QUALITY.md` | `NORMATIVE` | Engineering process | `CONTRIBUTORS` | `repo` |
| `change-management/FEATURE-FLAG-KILLSWITCH-REGISTRY.md` | `NORMATIVE` | Feature governance | `CORE,UI_WEB,AGENT,MCP,OPS` | `v1` |
| `change-management/FEATURE-FLAG-LIFECYCLE.md` | `NORMATIVE` | Feature governance | `CORE,UI_WEB,AGENT,MCP,OPS` | `v1` |
| `change-management/FEATURE-FLAG-REGISTRY.md` | `NORMATIVE` | Feature governance | `CORE,UI_WEB,AGENT,MCP,OPS` | `v1` |
| `change-management/HTTP-STATUS-IMPLEMENTATION-TICKETS.md` | `PREPARATORY` | Migration planning | `CORE,UI_WEB,AGENT` | `v1` |
| `change-management/ROLLOUT-PLAN-HTTP-STATUS-V1.md` | `PREPARATORY` | Migration planning | `CORE,UI_WEB,AGENT` | `v1` |
| `definitions/CAPABILITIES.md` | `NORMATIVE` | Domain definitions | `CORE,AGENT,MCP` | `v1.1+` |
| `definitions/DEFINITIONS.md` | `NORMATIVE` | Domain definitions | `CORE,UI_WEB,AGENT,MCP` | `v1` |
| `definitions/JOB-TYPES.md` | `NORMATIVE` | Domain definitions | `CORE,AGENT` | `v1` |
| `definitions/PROCESSING-PROFILES.md` | `NORMATIVE` | Domain definitions | `CORE,UI_WEB,AGENT` | `v1` |
| `definitions/SIDECAR-RULES.md` | `NORMATIVE` | Domain definitions | `CORE,AGENT` | `v1` |
| `ops/AUTH-INCIDENT-RUNBOOK.md` | `NON_NORMATIVE` | Operations | `OPS` | `v1` |
| `ops/OBSERVABILITY-TRIAGE.md` | `NON_NORMATIVE` | Operations | `OPS` | `v1` |
| `ops/READINESS-CHECKLIST.md` | `NON_NORMATIVE` | Operations | `OPS` | `v1` |
| `ops/README.md` | `NON_NORMATIVE` | Operations | `OPS` | `v1` |
| `ops/RELEASE-GATES.md` | `NORMATIVE` | Release governance | `CORE,UI_WEB,AGENT,OPS` | `v1` |
| `ops/RELEASE-OPERATIONS.md` | `NON_NORMATIVE` | Operations | `OPS` | `v1` |
| `policies/AUTHZ-MATRIX.md` | `NORMATIVE` | Security policy | `CORE,UI_WEB,AGENT,MCP` | `v1` |
| `policies/BACKUP-RESTORE-SECURITY.md` | `NORMATIVE` | Security policy | `CORE,OPS` | `v1` |
| `policies/CLIENT-HARDENING.md` | `NORMATIVE` | Security policy | `UI_WEB,AGENT,MCP` | `v1` |
| `policies/CRYPTO-SECURITY-MODEL.md` | `NORMATIVE` | Security policy | `CORE,UI_WEB,AGENT,MCP` | `v1` |
| `policies/DATA-CLASSIFICATION.md` | `NORMATIVE` | Security policy | `CORE,UI_WEB,AGENT,MCP,OPS` | `cross-version` |
| `policies/FEATURE-GOVERNANCE-OBSERVABILITY.md` | `NORMATIVE` | Observability | `CORE,UI_WEB,AGENT,MCP,OPS` | `v1` |
| `policies/FEATURE-RESOLUTION-ENGINE.md` | `NORMATIVE` | Feature governance | `CORE,UI_WEB,AGENT,MCP` | `v1` |
| `policies/GPG-OPENPGP-STANDARD.md` | `NORMATIVE` | Security policy | `CORE,AGENT,MCP` | `cross-version` |
| `policies/HOOKS-CONTRACT.md` | `NORMATIVE` | Extension contract | `CORE,UI_WEB,AGENT` | `v1` |
| `policies/I18N-LOCALIZATION.md` | `NORMATIVE` | Localization | `CORE,UI_WEB,AGENT,MCP` | `v1` |
| `policies/INCIDENT-RESPONSE.md` | `NORMATIVE` | Security policy | `OPS` | `cross-version` |
| `policies/KEY-MANAGEMENT.md` | `NORMATIVE` | Security policy | `CORE,OPS` | `v1` |
| `policies/LOCK-LIFECYCLE.md` | `NORMATIVE` | Concurrency | `CORE,AGENT,OPS` | `v1` |
| `policies/LOCKING-MATRIX.md` | `NORMATIVE` | Concurrency | `CORE,AGENT,OPS` | `v1` |
| `policies/NAMING-AND-NONCE.md` | `NORMATIVE` | Naming | `CORE,AGENT,MCP` | `v1` |
| `policies/PRIVACY-RETENTION.md` | `NORMATIVE` | Privacy | `CORE,UI_WEB,AGENT,MCP,OPS` | `v1` |
| `policies/RELEASE-SIGNING.md` | `NORMATIVE` | Release governance | `OPS,CONTRIBUTORS` | `repo` |
| `policies/RGPD-DATA-PROTECTION.md` | `NORMATIVE` | Privacy | `CORE,UI_WEB,AGENT,MCP,OPS` | `cross-version` |
| `policies/SEARCH-PRIVACY-INDEX.md` | `NORMATIVE` | Privacy | `CORE,UI_WEB` | `v1` |
| `policies/SECURE-SDLC.md` | `NORMATIVE` | Engineering process | `CONTRIBUTORS,OPS` | `repo` |
| `policies/SECURITY-BASELINE.md` | `NORMATIVE` | Security policy | `CORE,UI_WEB,AGENT,MCP,OPS` | `v1` |
| `policies/SUPPLY-CHAIN.md` | `NORMATIVE` | Engineering process | `CONTRIBUTORS,OPS` | `repo` |
| `policies/THREAT-MODEL.md` | `NORMATIVE` | Security policy | `CORE,UI_WEB,AGENT,MCP,OPS` | `cross-version` |
| `policies/VULNERABILITY-MANAGEMENT.md` | `NORMATIVE` | Engineering process | `CONTRIBUTORS,OPS` | `repo` |
| `state-machine/STATE-MACHINE.md` | `NORMATIVE` | State machine | `CORE,UI_WEB,AGENT` | `v1` |
| `success-criteria/SUCCESS-CRITERIA.md` | `NON_NORMATIVE` | Product acceptance | `CONTRIBUTORS,OPS` | `v1` |
| `tests/SECURITY-CHAOS-PLAN.md` | `NON_NORMATIVE` | Testing | `CORE,OPS` | `v1` |
| `tests/TEST-PLAN.md` | `NORMATIVE` | Testing | `CORE,UI_WEB,AGENT,MCP` | `v1` |
| `ui/KEYBOARD-SHORTCUTS-REGISTRY.md` | `NORMATIVE` | UI contract | `UI_WEB` | `v1` |
| `ui/README.md` | `NON_NORMATIVE` | UI overview | `UI_WEB,CONTRIBUTORS` | `v1` |
| `ui/UI-GLOBAL-SPEC.md` | `NORMATIVE` | UI contract | `UI_WEB` | `v1` |
| `ui/UI-REFONTE-RECOMMANDATION.md` | `NON_NORMATIVE` | UI design exploration | `UI_WEB` | `v1` |
| `ui/UI-UX-BRIEF-DESIGNER.md` | `NON_NORMATIVE` | UI design exploration | `UI_WEB` | `v1` |
| `ui/UI-WIREFRAMES-TEXTE.md` | `NON_NORMATIVE` | UI design exploration | `UI_WEB` | `v1` |
| `vision/PROJECT-BRIEF.md` | `NON_NORMATIVE` | Product vision | `CONTRIBUTORS` | `cross-version` |
| `vision/ROADMAP.md` | `ROADMAP` | Product planning | `CONTRIBUTORS,OPS` | `cross-version` |
| `workflows/AGENT-PROTOCOL.md` | `NORMATIVE` | Workflow contract | `CORE,AGENT,AGENT_UI,MCP` | `v1` |
| `workflows/SECURITY-DRILLS.md` | `NON_NORMATIVE` | Security operations | `OPS` | `v1` |
| `workflows/WORKFLOWS.md` | `NORMATIVE` | Workflow contract | `CORE,UI_WEB,AGENT` | `v1` |
