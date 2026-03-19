# GPG/OpenPGP Standard — Technical Clients and Sensitive Data Baseline

Ce document definit la standardisation GPG/OpenPGP pour Core, AGENT, MCP et la protection des donnees sensibles.

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

## 5) Experience utilisateur et modes d'integration (MUST)

Mode par defaut (obligatoire):

* setup OpenPGP transparent pour les parcours standards concernes (aucune etape manuelle requise pour demarrer)
* generation, stockage et rotation des cles geres par la plateforme
* l'utilisateur n'a pas besoin de comprendre OpenPGP pour utiliser `UI_WEB` ou les parcours standards de l'application

Mode avance (optionnel):

* l'utilisateur PEUT connecter un agent PGP externe (`gpg-agent`/equivalent) pour des usages documentaires ou d'artefacts quand le parcours applicatif le supporte explicitement
* l'utilisateur PEUT utiliser ses cles existantes pour import/publication/verification de documents ou artefacts OpenPGP
* ce mode NE DOIT PAS etre pre-requis pour les parcours standard
* si necessaire, ce mode peut etre livre en phase ulterieure sans bloquer la securite by default

Contrainte applicative :

* les identites techniques runtime (`AGENT_TECHNICAL`, `MCP_TECHNICAL`) gardent leurs propres cles applicatives locales
* une cle utilisateur personnelle ou un flux mail OpenPGP NE DOIT PAS devenir implicitement l'identite runtime d'un client technique

## 6) Regles d'usage par donnee (MUST)

* adresse, GPS, transcription: chiffrement OpenPGP ou envelope equivalent obligatoire
* export de donnees sensibles: chiffre et signe
* backup sensible: chiffre avant ecriture
* logs/traces/crash reports: jamais de plaintext de ces donnees

## 7) Interoperabilite et libs autorisees (MUST)

Chaque application DOIT utiliser une librairie OpenPGP reconnue et maintenue:

* PHP (`CORE`, services PHP): `php-privacy/openpgp`
* Rust (`AGENT_UI`, `AGENT`, composants Rust): `sequoia-openpgp`
* Node/TypeScript (si applicable): `openpgp` (OpenPGP.js)
* Go (si applicable): `ProtonMail/gopenpgp` ou equivalent maintenu et auditable
* Python (si applicable): `PGPy` ou bindings GnuPG maintenus

Conditions:

* version pinnee et suivie via policy supply-chain
* aucune implementation crypto maison
* toute exception de librairie DOIT etre validee securite

## 8) Cycle de vie et gouvernance (MUST)

* fingerprint de cle reference versionne
* mapping `key_id -> owner -> usage -> expiration` obligatoire
* rotation planifiee max 180 jours pour cles de chiffrement donnees sensibles
* key compromise: rotation immediate + re-encrypt workflow + audit incident

## 9) Tests de conformite (MUST)

* test roundtrip encrypt/decrypt par composant concerne (`CORE`, `AGENT`, `MCP`)
* test signature verify pour payload sensible signe
* test rejet d'algorithmes interdits
* test DB dump/backups: adresse, GPS, transcription non lisibles en clair
* test rekey/re-encrypt sans perte de donnees autorisees
* test mode transparent: premier login/utilisation sans setup PGP manuel
* test mode avance: branchement `gpg-agent`/cles existantes sans regression
* test fallback: indisponibilite du mode avance ne bloque pas le mode transparent

## 10) Critere de non-conformite

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
