# Sidecar Rules — Retaia Core + Retaia Agent

Ce document définit les règles déterministes d'association sidecar <-> MediaAsset.

## 0) Base de travail par défaut (normative)

Sauf mention explicite contraire, les règles de ce document sont calibrées pour la base matérielle suivante :

* caméras principales : Panasonic, Canon
* drone : DJI Air 3
* audio/micro : Rode Wireless Pro

Conséquence :

* toute extension sidecar hors de cette base doit être ajoutée explicitement avant implémentation
* aucune heuristique “best-effort” n'est autorisée pour des formats non listés

## 1) Principe

Un sidecar est associé par règles explicites, jamais par heuristique implicite non documentée.

Invariants :

* association déterministe et rejouable
* aucun sidecar ambigu attaché automatiquement
* tout sidecar non résolu reste `UNMATCHED_SIDECAR`

## 2) Matching canonique

Clé de base :

* même dossier
* même `basename` (sans extension)

Ordre de résolution :

1. match exact `basename`
2. match normalisé (case-insensitive) si filesystem non case-sensitive
3. rejet en ambigu si plusieurs candidats valides

## 3) Extensions supportées v1

PHOTO :

* `.xmp`

VIDEO (DJI Air 3 et famille DJI compatible) :

* `.srt` (metadata/telemetry)
* `.lrf` (proxy sidecar constructeur)

VIDEO (legacy / non canonique de base) :

* `.lrv`, `.thm` uniquement si activés explicitement par politique locale/documentée

AUDIO :

* sidecars audio spécifiques explicitement listés par politique locale (pas de wildcard implicite)

## 4) Conflits et ambiguïtés

Cas ambigus :

* plusieurs sidecars d'une même famille pour un même parent
* plusieurs parents possibles pour un sidecar

Règle :

* aucun attach automatique
* état `UNMATCHED_SIDECAR`
* résolution humaine explicite requise

## 5) Moves et purge

* un sidecar attaché suit toujours son parent pour move/rename/purge
* un sidecar `UNMATCHED_SIDECAR` n'est jamais supprimé implicitement

## 6) Observabilité minimale

Pour chaque décision d'association :

* `asset_uuid`
* `sidecar_path`
* règle appliquée
* résultat (`attached|unmatched|ambiguous`)

## 7) Évolution

* ajout d'une extension supportée : changement compatible
* changement d'ordre de matching : changement structurel

## Références associées

* [DEFINITIONS.md](DEFINITIONS.md)
* [WORKFLOWS.md](../workflows/WORKFLOWS.md)
* [LOCKING-MATRIX.md](../policies/LOCKING-MATRIX.md)
