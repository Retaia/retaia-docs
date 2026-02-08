# SUCCESS CRITERIA — Retaia Core + Retaia Agent

Ce document définit les **critères de succès mesurables** du projet Retaia Core + Retaia Agent.

Le succès n’est pas défini par la richesse fonctionnelle, mais par la **confiance d’usage**, la **robustesse dans le temps** et la **réduction des erreurs humaines**.


## Succès fondamental (non négociable)

Le projet est considéré comme réussi si :

> **Après plusieurs mois d’usage réel, l’utilisateur fait confiance au système et n’utilise plus de workflows parallèles “par sécurité”.**


## Critères de succès fonctionnels

### 1) Inventaire fiable

* Tous les médias présents sur le NAS sont inventoriés.
* Aucun fichier incomplet n’est traité.
* Aucun doublon logique (UUID) n’est créé.
* Les sidecars sont correctement associés.


### 2) Processing automatique et silencieux

* Le processing démarre automatiquement sans action manuelle.
* Retaia Agent fonctionne comme **agent background**.
* Les crashes ou coupures réseau n’entraînent ni corruption ni état incohérent.
* Les jobs sont repris automatiquement après échec.


### 3) Review fluide via proxies

* La review est possible **uniquement après processing**.
* Les vidéos et audios sont lisibles via l’UI sans accès SMB.
* Le scrub vidéo/audio est fluide.
* Les thumbnails et waveforms sont disponibles.


### 4) Décision humaine respectée

* KEEP / REJECT ne sont jamais automatisés.
* Les suggestions (IA/LLM) sont clairement identifiées comme telles.
* Aucune suggestion n’est appliquée sans validation explicite.
* Les décisions peuvent être annulées ou changées avant move.


### 5) Déplacements sûrs et prévisibles

* Aucun fichier n’est déplacé sans batch explicite.
* Un dry-run précède chaque batch move.
* Les collisions de noms sont gérées de manière déterministe.
* Un rapport de batch est toujours disponible.


### 6) Cycle de vie long terme maîtrisé

* Un asset ARCHIVED peut être re-reviewé et reclassé.
* Un asset REJECTED peut être purgé après délai configurable.
* La purge supprime **originaux, sidecars et dérivés**.
* L’état terminal `PURGED` conserve un audit minimal.


### 7) Robustesse face aux erreurs

* Aucun traitement concurrent sur un même asset.
* Aucun processing pendant un batch move.
* Les locks expirent correctement.
* Les transitions interdites sont refusées par le système.


## Critères de succès techniques

### 8) Séparation des responsabilités

* NAS = inventaire, décisions, moves.
* Clients = compute only.
* UI = client API, aucun accès direct au filesystem.


### 9) API stable et contractuelle

* L’API est versionnée.
* Toute rupture introduit une nouvelle version.
* UI, Retaia Agent et futurs clients consomment la même API.


### 10) Performance maîtrisée

* Le NAS n’exécute aucun traitement lourd.
* Les agents n’épuisent pas le réseau ou le stockage.
* Les dérivés sont stockés hors des originaux.


## Critères de succès humains

### 11) Lisibilité après interruption

* Après plusieurs semaines sans usage, l’utilisateur comprend :

    * l’état d’un asset
    * pourquoi il est dans cet état
    * ce qui peut être fait ensuite


### 12) Réduction du stress et des erreurs

* L’utilisateur n’a pas peur de cliquer sur “Apply moves”.
* Les erreurs sont anticipables et récupérables.
* Aucune action destructive n’est cachée.


## Critères d’échec (signaux d’alerte)

Le projet est en échec si :

* l’utilisateur maintient un second système “au cas où”
* des fichiers sont déplacés sans compréhension claire
* des décisions sont prises automatiquement
* des fichiers disparaissent sans audit
* la purge est perçue comme dangereuse ou imprévisible


## Règle finale

Si une fonctionnalité :

* améliore la vitesse mais réduit la confiance
* automatise une décision humaine
* rend le comportement moins explicable

Alors elle **ne contribue pas au succès du projet**, même si elle semble utile à court terme.
