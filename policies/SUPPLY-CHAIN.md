# Supply Chain Security — Dependencies And Build Provenance

Ce document definit les exigences supply chain pour les composants logiciels et artefacts de build.

## 1) Dependances

* lockfiles obligatoires et versionnes
* pinning strict des dependances critiques
* dependances abandonnees/interdites bannies
* update reguliere avec revues de securite

## 2) SBOM

* SBOM generee pour chaque release candidate
* SBOM archivee avec artefacts
* format standard (CycloneDX ou SPDX)

## 3) Provenance et integrite

* builds reproductibles autant que possible
* provenance attestee des artefacts
* hash de release publie et verifie
* aucun artefact non signe en production

## 4) Source policy

* sources externes autorisees listees explicitement
* telechargements dynamiques non verifies interdits
* mirroring/cache controle pour dependances critiques

## 5) Tests obligatoires

* CI echoue si dependance critique vulnerable non exemptee
* generation SBOM verifiee en pipeline release
* verification signature/hash effectuee avant promotion artefact

## References associees

* [RELEASE-SIGNING.md](RELEASE-SIGNING.md)
* [SECURE-SDLC.md](SECURE-SDLC.md)
* [VULNERABILITY-MANAGEMENT.md](VULNERABILITY-MANAGEMENT.md)
