# Crypto Security Model — Assume Leak (Signal-Inspired)

Ce document definit le modele cryptographique cible pour rendre les fuites de donnees inutiles.

Objectif: meme si DB/logs/backups sont exfiltres, un attaquant ne peut pas lire les donnees metier sensibles sans materiel cryptographique separe.

## 1) Hypothese d'attaque

* fuite partielle ou totale de DB
* fuite partielle de logs/traces
* fuite de backups
* compromission d'un token client

Le modele DOIT rester defendable dans ces scenarios.

## 2) Principes (Signal-inspired)

* separation stricte entre donnees chiffrees et cles
* sessions et cles a duree de vie bornee
* forward secrecy sur canaux interactifs (quand applicable)
* post-compromise safety via rotation/rekey
* minimisation des metadonnees sensibles

## 3) Chiffrement des donnees stockees (MUST)

* chiffrement applicatif obligatoire pour donnees hautement sensibles
* algorithmes AEAD obligatoires: `AES-256-GCM` ou `XChaCha20-Poly1305`
* envelope encryption:
  * DEK (data encryption key) unique par objet/champ sensible
  * KEK geree par KMS/HSM pour encrypter/wrap les DEK
* AAD obligatoire (au minimum: `asset_uuid`, `field_name`, `schema_version`)

Champs explicitement obligatoires a chiffrer (MUST):

* adresses postales
* coordonnees GPS
* textes de transcription

## 4) Clefs et cycle de vie (MUST)

* aucune cle privee/KEK en dur dans le code
* generation de cles via source cryptographique sure
* rotation periodique des KEK et re-wrapping des DEK
* rotation d'urgence en cas de suspicion de fuite
* destruction controlee des cles obsoletes selon retention

## 5) Canaux et sessions (MUST/SHOULD)

* TLS obligatoire pour toutes communications runtime
* tokens courts + `jti` unique + revocation server-side
* SHOULD: canaux interactifs avec handshake ephemeral et rekey regulier (inspire du Double Ratchet)

## 6) Backups, logs, exports (MUST)

* backups contenant donnees sensibles: chiffrés
* logs/traces/crash reports: zero secret en clair
* exports de donnees sensibles: chiffrés et audites
* dumps non chiffrés interdits

## 7) Invariants de non-utilite en cas de fuite

Une fuite est consideree "utile" pour l'attaquant si un des cas suivants est possible sans KMS/cles:

* lecture d'une adresse en clair
* lecture d'un point GPS en clair
* lecture d'une transcription en clair

Ces cas DOIVENT etre impossibles.

## 8) Tests obligatoires

* test DB dump: champs adresse/GPS/transcript non lisibles en clair
* test backup dump: idem
* test rekey/rotation: donnees re-dechiffrables uniquement via cles actives autorisees
* test logs: aucune presence de plaintext sensible

## References associees

* [SECURITY-BASELINE.md](SECURITY-BASELINE.md)
* [DATA-CLASSIFICATION.md](DATA-CLASSIFICATION.md)
* [KEY-MANAGEMENT.md](KEY-MANAGEMENT.md)
* [INCIDENT-RESPONSE.md](INCIDENT-RESPONSE.md)
