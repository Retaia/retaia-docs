# Secure SDLC — Normative Baseline

Ce document definit les exigences minimales Secure SDLC pour tous les repos Retaia.

## 1) Gates obligatoires

* SAST bloqueur sur PR
* scans secrets bloqueurs sur PR et default branch
* dependabot/security advisories actives
* tests de non-regression securite executes avant merge
* aucune PR critique securite merge sans review humaine

## 2) Revues de code

* minimum 1 approbation pour changement standard
* minimum 2 approbations pour changements authn/authz/crypto
* checklist securite obligatoire dans template PR
* preuves de tests jointes pour changements critiques

## 3) Gestion des secrets en dev

* secrets interdits dans git history
* `.env` locaux non versionnes
* usage de secret manager pour CI/CD
* rotation immediate de tout secret expose

## 4) CI/CD securise

* runners limites en privileges
* tokens CI scopes minimaux
* artefacts CI a retention bornee
* provenance build tracee

## 5) Exceptions

* exception securite DOIT etre documentee avec owner + date d'expiration
* exception expiree sans renewal => gate bloqueur
* aucune exception sans mitigation compensatoire

## 6) Tests minimaux

* SAST detecte et bloque un payload test vulnerable
* scan secrets bloque une fake key committee
* rules branch protection refusent merge sans checks requis
* workflow CI refuse permissions excesives

## References associees

* [SECURITY-BASELINE.md](SECURITY-BASELINE.md)
* [VULNERABILITY-MANAGEMENT.md](VULNERABILITY-MANAGEMENT.md)
* [CODE-QUALITY.md](../change-management/CODE-QUALITY.md)
