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

Artefacts versionnes minimum attendus dans le repo :

* workflow CI avec `permissions` minimales explicites
* workflow securite separé (SAST + scan secrets)
* configuration Dependabot
* template PR avec checklist securite

Contraintes d'implementation de ces gates pour tous les repos enfants :

* un scan secrets bloqueur NE DOIT PAS dependre implicitement d'une licence payante ou d'un secret d'organisation non garanti ; si un outil necessite une licence, le repo DOIT soit versionner une alternative libre equivalente, soit documenter explicitement le prerequis externe avant de le rendre bloqueur
* la configuration CodeQL DOIT etre limitee aux langages reellement presents dans le repo ; declarer un langage absent et faire echouer la PR pour "no source code seen during build" est non conforme

Controles GitHub externes obligatoires (hors repo, mais requis) :

* branch protection sur `master`
* checks requis avant merge
* revue(s) minimales selon la criticite
* CODEOWNERS avec owners reels du depot ou de l'organisation

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
