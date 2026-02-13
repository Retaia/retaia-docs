# Search Privacy Index — Full-Text And Location Filters

Ce document definit le modele normatif de recherche quand les donnees sensibles sont chiffrees.

Objectif: conserver `full-text search` et filtres de localisation sans exposer les valeurs sensibles en clair.

## 1) Principes

* les donnees sources sensibles restent chiffrees (adresse, GPS, transcription)
* la recherche s'appuie sur un index derive dedie
* l'index derive ne doit pas permettre une relecture directe des valeurs source
* aucune donnee sensible en clair dans logs, traces, dumps et backups

## 2) Index full-text (MUST)

* `q=` doit interroger un index tokenize/normalise derive
* les tokens d'index DOIVENT etre proteges (blind index / keyed hash ou equivalent)
* aucune colonne d'index ne DOIT contenir le texte brut de transcription
* la recherche reste case-insensitive et compatible pagination/tri existants

## 3) Filtres localisation (MUST)

* filtres supportes:
  * `location_country`
  * `location_city`
  * `geo_bbox` (min_lon,min_lat,max_lon,max_lat)
* les coordonnees GPS source restent chiffrees
* les filtres geo reposent sur index spatial derive (geocell/geohash/H3 ou equivalent)
* precision geographique configurable pour limiter le risque de re-identification

## 4) Invariants anti-fuite

* dump DB sans cles: pas de texte transcription lisible
* dump DB sans cles: pas de coordonnees GPS brutes lisibles
* dump DB sans cles: pas d'adresse brute lisible
* index seul insuffisant pour reconstituer les donnees source a grande echelle

## 5) Tests obligatoires

* `q=` retourne des resultats pertinents sans acces au plaintext des champs sensibles
* filtres `location_country`, `location_city`, `geo_bbox` fonctionnent sur index derive
* aucun plaintext sensible dans index, logs, traces, dumps
* rotation/reindex ne casse pas la recherche ni la confidentialite

## References associees

* [CRYPTO-SECURITY-MODEL.md](CRYPTO-SECURITY-MODEL.md)
* [DATA-CLASSIFICATION.md](DATA-CLASSIFICATION.md)
* [API-CONTRACTS.md](../api/API-CONTRACTS.md)
* [TEST-PLAN.md](../tests/TEST-PLAN.md)
