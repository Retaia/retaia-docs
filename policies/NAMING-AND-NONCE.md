# Naming And Nonce — Retaia Core + Retaia Agent

Ce document définit la stratégie de nommage déterministe et le format `short_nonce`.

## 1) Collision sur move

Format obligatoire :

`<filename_without_ext>__<short_nonce><ext>`

Exemple :

`A001_C001.mov` -> `A001_C001__k3m9q2.mov`

## 2) Format `short_nonce`

* alphabet : `a-z0-9`
* longueur : 6 caractères
* minuscule uniquement
* pas de caractères spéciaux

## 3) Génération

Règle v1 :

* source = `asset_uuid + target_dir + attempt_index`
* hash stable (sha256)
* encodage base36
* tronqué à 6 caractères

Objectif : reproductible pour un même contexte/attempt.

## 4) Retry borné

* maximum 10 tentatives de nonce par collision
* si collision persistante : échec explicite `409 NAME_COLLISION_EXHAUSTED`
* aucun fallback implicite hors règle de nonce

## 5) Invariants

* pas de renommage "magique"
* pas d'incrément numérique implicite
* toute collision est traçable dans l'audit

## Références associées

* [WORKFLOWS.md](../workflows/WORKFLOWS.md)
* [API-CONTRACTS.md](../api/API-CONTRACTS.md)
