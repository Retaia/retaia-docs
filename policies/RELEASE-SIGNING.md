# Release Signing Policy

Ce document definit la signature obligatoire des artefacts de release.

## 1) Portee

* binaire UI_RUST
* binaire AGENT CLI/GUI
* packages et archives de distribution

## 2) Exigences MUST

* chaque artefact release DOIT etre signe
* hash SHA-256 publie pour chaque artefact
* verification signature/hash avant installation ou update
* cle de signature stockee en secret manager ou HSM

## 3) Rotation et revocation

* cles de signature versionnees (`key_id`)
* procedure de rotation documentee et testee
* artefact signe avec cle revoquee => rejet

## 4) Pipeline release

* signature effectuee en CI securisee
* provenance build associee a l'artefact signe
* publication bloquee si verification post-signature echoue

## 5) Tests obligatoires

* artefact non signe => rejet d'installation
* signature invalide => rejet
* hash mismatch => rejet
* verification fonctionne sur macOS/Windows/Linux

## References associees

* [SUPPLY-CHAIN.md](SUPPLY-CHAIN.md)
* [CLIENT-HARDENING.md](CLIENT-HARDENING.md)
* [KEY-MANAGEMENT.md](KEY-MANAGEMENT.md)
