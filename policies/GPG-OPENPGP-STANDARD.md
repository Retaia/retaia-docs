# GPG/OpenPGP Standard — Cross-Client Security Baseline

Ce document definit la standardisation GPG/OpenPGP pour Core, UI_RUST, AGENT et MCP.

Objectif: en cas de fuite DB/logs/backups, les donnees sensibles restent inutilisables sans cles.

## 1) Portee

* donnees sensibles stockees (adresse, GPS, transcription, exports)
* echanges de payload sensibles entre composants
* signatures de documents/artefacts quand OpenPGP est utilise

## 2) Standard impose (MUST)

* standard: OpenPGP (RFC 4880 + evolutions compatibles)
* outils de reference: GnuPG (`gpg`) pour operations CLI/ops
* format armure ASCII (`.asc`) autorise pour transport humain
* format binaire OpenPGP recommande pour runtime/performance
* chiffrement sans authenticite (pas de signature/MDC/AEAD) interdit

## 3) Algorithmes et profils crypto (MUST)

* cles asymetriques: `ed25519` (signature) + `cv25519` (chiffrement) preferes
* fallback legacy accepte uniquement avec derogation explicite
* hash: `SHA-256` minimum
* derive/interne: courbes et primitives modernes uniquement
* cles faibles (RSA < 3072, SHA-1, DSA legacy) interdites

## 4) Modele de cles (MUST)

* separation stricte:
  * cle primaire (certification/signature)
  * sous-cle chiffrement dediee
* aucune cle privee en clair en base
* cles privees protegees par secret store/KMS/HSM
* rotation reguliere et rotation d'urgence documentees
* revocation certificate genere pour chaque identite de cle

## 5) Regles d'usage par donnee (MUST)

* adresse, GPS, transcription: chiffrement OpenPGP ou envelope equivalent obligatoire
* export de donnees sensibles: chiffre et signe
* backup sensible: chiffre avant ecriture
* logs/traces/crash reports: jamais de plaintext de ces donnees

## 6) Interoperabilite et libs autorisees (MUST)

Chaque application DOIT utiliser une librairie OpenPGP reconnue et maintenue:

* Rust (`UI_RUST`, `AGENT`, composants Rust): `sequoia-openpgp`
* Node/TypeScript (si applicable): `openpgp` (OpenPGP.js)
* Go (si applicable): `ProtonMail/gopenpgp` ou equivalent maintenu et auditable
* Python (si applicable): `PGPy` ou bindings GnuPG maintenus

Conditions:

* version pinnee et suivie via policy supply-chain
* aucune implementation crypto maison
* toute exception de librairie DOIT etre validee securite

## 7) Cycle de vie et gouvernance (MUST)

* fingerprint de cle reference versionne
* mapping `key_id -> owner -> usage -> expiration` obligatoire
* rotation planifiee max 180 jours pour cles de chiffrement donnees sensibles
* key compromise: rotation immediate + re-encrypt workflow + audit incident

## 8) Tests de conformite (MUST)

* test roundtrip encrypt/decrypt par client type (`UI_RUST`, `AGENT`, `MCP`)
* test signature verify pour payload sensible signe
* test rejet d'algorithmes interdits
* test DB dump/backups: adresse, GPS, transcription non lisibles en clair
* test rekey/re-encrypt sans perte de donnees autorisees

## 9) Critere de non-conformite

Non conforme si un des cas suivants est observe:

* plaintext adresse/GPS/transcription en DB, logs ou backup
* cle privee exportee/stockee en clair
* librairie crypto non standardisee ou non maintenue
* algorithme interdit accepte en production

## References associees

* [SECURITY-BASELINE.md](SECURITY-BASELINE.md)
* [KEY-MANAGEMENT.md](KEY-MANAGEMENT.md)
* [DATA-CLASSIFICATION.md](DATA-CLASSIFICATION.md)
* [SUPPLY-CHAIN.md](SUPPLY-CHAIN.md)
* [TEST-PLAN.md](../tests/TEST-PLAN.md)
