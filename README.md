# Retaia – Specifications

Ce repository est la source de vérité (Single Source of Truth) du projet Retaia.

Tout comportement du système (serveur, agent, CLI, UI, infrastructure)
doit être conforme à ces spécifications.

En cas de divergence entre le code et ce repository :
les spécifications font foi.

Aucune logique métier ne doit être définie ailleurs.

## Navigation

* [Vision](vision/PROJECT-BRIEF.md)
* [Architecture](architecture/CONCEPTUAL-ARCHITECTURE.md)
* [Machine à états](state-machine/STATE-MACHINE.md)
* [Workflows](workflows/WORKFLOWS.md)
* [Protocole agent](workflows/AGENT-PROTOCOL.md)
* [Définitions](definitions/DEFINITIONS.md)
* [Job types](definitions/JOB-TYPES.md)
* [Processing profiles](definitions/PROCESSING-PROFILES.md)
* [Sidecar rules](definitions/SIDECAR-RULES.md)
* [Capabilities](definitions/CAPABILITIES.md)
* [Locking matrix](policies/LOCKING-MATRIX.md)
* [Hooks contract](policies/HOOKS-CONTRACT.md)
* [Lock lifecycle](policies/LOCK-LIFECYCLE.md)
* [Authz matrix](policies/AUTHZ-MATRIX.md)
* [Test plan](tests/TEST-PLAN.md)
* [Anti-patterns](anti-patterns/ANTI-PATTERNS.md)
* [Success criteria](success-criteria/SUCCESS-CRITERIA.md)
* [Change management](change-management/CHANGE-MANAGEMENT.md)
* [AI-assisted development](change-management/AI-ASSISTED-DEVELOPMENT.md)
* [Code quality](change-management/CODE-QUALITY.md)
* [API contracts](api/API-CONTRACTS.md)
* [Error model](api/ERROR-MODEL.md)
