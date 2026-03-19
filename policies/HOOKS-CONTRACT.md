# Hooks Contract — Retaia multi-apps

Ce document définit le contrat normatif des hooks/plugins côté serveur.

## 1) Points d'extension autorisés v1

* `after_processed_before_decision_pending`
* `on_enter_decision_pending`

Aucun autre point d'extension n'est autorisé en v1.

## 2) Contraintes de sûreté

Un hook/plugin NE DOIT PAS :

* modifier directement l'état principal d'un asset
* prendre une décision KEEP/REJECT
* déclencher move/purge
* écrire sur les originaux NAS

## 3) Contrat d'exécution

* exécution synchrone dans la transaction orchestratrice
* timeout max par hook : 2s (configurable)
* en cas de timeout/erreur :
  * le hook est marqué failed
  * l'état principal continue selon politique définie
  * un événement d'audit est écrit

Politique v1 : fail-open (lifecycle continue), sauf hook explicitement marqué `blocking=true`.

Statut `blocking` autorisé en `v1` :

* `blocking=true` N'EST autorisé que pour le hook point `after_processed_before_decision_pending`
* `on_enter_decision_pending` DOIT toujours rester `blocking=false` en `v1`
* un hook `blocking=true` NE DOIT PAS émettre de `patches`
* un hook `blocking=true` DOIT être déclaré explicitement dans la configuration Core; aucun plugin ne peut s'auto-déclarer bloquant

Effet runtime normatif d'un hook bloquant en échec :

* si un hook `blocking=true` échoue (`status=failed`, exception, timeout), Core DOIT interrompre la transition courante
* l'asset DOIT rester dans son état précédent la transition tentée
* Core DOIT répondre avec `409 STATE_CONFLICT`
* aucun patch partiel du hook bloquant ne DOIT être appliqué
* un événement d'audit/opservabilité DOIT être émis avec au minimum :
  * `asset_uuid`
  * `hook_name`
  * `hook_point`
  * `blocking=true`
  * `status=failed`
  * `event_id`

## 4) Idempotence

Chaque exécution de hook reçoit :

* `asset_uuid`
* `hook_name`
* `event_id` unique

Le plugin DOIT être idempotent sur `(asset_uuid, hook_name, event_id)`.

## 5) Isolation

* pas d'appel réseau bloquant non borné
* pas d'accès direct DB hors interface plugin
* pas d'état partagé mutable global sans verrou explicite

## 6) Contrat d'input/output

Input minimal :

* `asset_uuid`
* `current_state`
* `processing_profile`
* `facts_ref?`
* `transcript_ref?`

Output v1 :

* `status: ok | failed | skipped`
* `notes?`
* `patches?` (uniquement domaines autorisés non destructifs)

Domaines de patch autorisés en `v1` :

* `fields`
* `notes`

Règles de patch :

* `patches` NE DOIT modifier ni `state`, ni `decision`, ni `paths`, ni `derived`, ni `facts`, ni `transcript`, ni `revision_history`
* un hook non bloquant PEUT omettre `patches`
* un hook `blocking=true` DOIT omettre `patches`

## 7) Versioning

* toute rupture du contrat hook => version majeure plugin
* tout nouveau hook point => changement structurel de spec

## Références associées

* [STATE-MACHINE.md](../state-machine/STATE-MACHINE.md)
* [API-CONTRACTS.md](../api/API-CONTRACTS.md)
* [ANTI-PATTERNS.md](../anti-patterns/ANTI-PATTERNS.md)
