# RGPD Data Protection — Normative Policy

Ce document definit les exigences RGPD minimales pour Retaia.

## 1) Principes RGPD

* minimisation des donnees
* limitation de finalite
* exactitude et mise a jour
* limitation de conservation
* integrite et confidentialite
* accountability

## 2) Registre de traitements (MUST)

* chaque categorie de donnees personnelles DOIT etre documentee
* finalite, base legale, retention, destinataires DOIVENT etre explicites
* categories sensibles (adresse, GPS, transcription) DOIVENT etre marquees

## 3) Base legale et consentement

* base legale explicite par traitement (contrat, interet legitime, consentement, etc.)
* consentement requis quand necessaire, avec preuve horodatee
* retrait du consentement DOIT etre appliquable et trace

## 4) Droits des personnes (MUST)

* droit d'acces
* droit de rectification
* droit a l'effacement (dans limites legales)
* droit a la limitation/opposition selon base legale
* portabilite quand applicable

Delais cibles:

* accusé de reception demande: <= 72h
* resolution standard: <= 30 jours

## 5) Notification de violation de donnees

* qualification incident RGPD obligatoire si donnees personnelles impactees
* notification autorite de controle <= 72h quand requis
* notification personnes concernees selon niveau de risque
* traces de decision et d'impact obligatoires

## 6) Exigences techniques liees

* chiffrement applicatif pour adresse/GPS/transcription
* pseudonymisation en environnements non-prod
* acces aux donnees personnelles selon moindre privilege
* audit des acces et des exports de donnees personnelles

## 7) Tests et preuves obligatoires

* test workflow export donnees personnelles
* test workflow effacement/purge conforme retention
* test registre de traitements complet pour nouvelles donnees perso
* test notification incident RGPD (tabletop/exercice)

## References associees

* [DATA-CLASSIFICATION.md](DATA-CLASSIFICATION.md)
* [PRIVACY-RETENTION.md](PRIVACY-RETENTION.md)
* [SECURITY-BASELINE.md](SECURITY-BASELINE.md)
* [INCIDENT-RESPONSE.md](INCIDENT-RESPONSE.md)
