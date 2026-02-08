# ANTI-PATTERNS — Retaia Core + Retaia Agent

Ce document liste les **anti-patterns explicitement interdits** dans le projet Retaia Core + Retaia Agent.

Toute proposition, implémentation ou évolution qui enfreint ces règles est **considérée invalide par design**, même si elle semble "pratique" à court terme.


## Anti-patterns fondamentaux

### 1) Décision automatisée

❌ Laisser un système automatique (IA, règle, script, agent) décider :

* KEEP / ARCHIVE
* REJECT

Les décisions de conservation sont **humaines uniquement**.

Les systèmes automatiques peuvent produire des **suggestions**, jamais des décisions.


### 2) NAS utilisé comme moteur de calcul

❌ Exécuter sur le NAS :

* ffmpeg
* génération de proxies
* transcription
* analyse ML / LLM

Le NAS est un **centre logistique**, pas un moteur de calcul.


### 3) Review UI basée sur les originaux

❌ Lire les fichiers originaux via SMB/NFS dans une UI web.

La review se fait **exclusivement via proxies/dérivés** exposés par l’API.


### 4) Move automatique au fil de l’eau

❌ Déplacer des fichiers dès qu’un état est atteint (ex: PROCESSED, DECIDED).

Tous les déplacements sont :

* explicites
* batchés
* précédés d’un dry-run


### 5) Confondre PROCESSED et DECIDED

❌ Considérer qu’un asset PROCESSED est validé.

* PROCESSED = technique
* DECIDED = humain


### 6) Utiliser le path comme identité

❌ Identifier un média par son chemin.

Le **UUID est l’identité**.
Le path est mutable et secondaire.


### 7) Supprimer ou modifier des fichiers sans traçabilité

❌ Rename, move ou suppression :

* sans historique
* sans audit
* sans action explicite

Toute action filesystem doit être journalisée.


## Anti-patterns de workflow

### 8) Processing déclenché manuellement

❌ Un bouton "lancer le processing" côté utilisateur.

Le processing est effectué par des **agents en arrière-plan**.


### 9) Processing concurrent non contrôlé

❌ Plusieurs agents traitant le même asset simultanément.

Les jobs doivent être réservés avec :

* lock
* TTL
* heartbeat


### 10) Processing pendant un batch move

❌ Laisser un agent traiter un asset en cours de déplacement.

Les assets `MOVE_QUEUED` ne sont jamais claimables.


### 11) Travailler offline en modifiant l’inventaire

❌ Prendre des décisions KEEP / REJECT ou déplacer des fichiers hors connexion.

Le travail offline ne modifie jamais le NAS.


### 12) Dupliquer les fichiers par projet

❌ Copier les rushes dans des dossiers de projet.

Les projets **référencent** les MediaAssets.


### 13) Réinjecter les exports dans l’inventaire

❌ Traiter des exports comme des sources.

Exports ≠ MediaAssets.


## Anti-patterns de données

### 14) Mélanger facts, suggestions et decisions

❌ Écraser une décision humaine par un recalcul ou une suggestion.

* facts : recalculables
* suggestions : recalculables
* decisions : humaines, jamais modifiées automatiquement


### 15) Appliquer automatiquement des suggestions

❌ Transformer une suggestion (IA/LLM) en vérité.

Toute suggestion doit être **explicitement validée** par un humain.


### 16) Champs structurés non versionnés

❌ Modifier silencieusement un custom field (type, enum, sens).

Les définitions de champs sont versionnées.


### 17) Binaires stockés en base de données

❌ Stocker proxies, thumbnails ou waveforms en DB.

La DB stocke des métadonnées et des références, jamais des binaires.


### 18) Suppression des originaux sans nettoyage des dérivés

❌ Supprimer un asset REJECTED sans supprimer ses dérivés.

Toute purge doit nettoyer :

* originaux
* sidecars
* dérivés (`RUSHES_DB/.derived/{uuid}`)


## Anti-patterns d’architecture

### 19) Media server déguisé

❌ Transformer Retaia Core en :

* Plex-like
* DAM cloud-like
* serveur de streaming généraliste

Retaia Core est un **catalogue de production**, pas un media server.


### 20) Couplage fort entre composants

❌ Retaia Agent qui décide.
❌ UI qui accède directement au filesystem.
❌ Logique métier partagée hors serveur.

Chaque composant a un rôle strict.


### 21) Changement silencieux de comportement

❌ Modifier un workflow sans :

* mise à jour de la documentation
* migration explicite

Les workflows et la machine à états sont normatifs.


## Anti-patterns d’évolution

### 22) Feature ajoutée sans invariant clair

❌ Ajouter une fonctionnalité sans définir :

* ce qu’elle peut faire
* ce qu’elle ne peut jamais faire


### 23) Complexité "intelligente"

❌ Introduire des heuristiques obscures ou magiques.

Préférer :

* explicite
* boring
* débogable


## Règle finale

Si une idée :

* réduit le contrôle humain
* masque une action destructive
* rend le système moins compréhensible après 6 mois

Alors cette idée est un **anti-pattern**, même si elle "fait gagner du temps" aujourd’hui.

## Références associées

* [CONCEPTUAL-ARCHITECTURE.md](../architecture/CONCEPTUAL-ARCHITECTURE.md)
* [STATE-MACHINE.md](../state-machine/STATE-MACHINE.md)
* [WORKFLOWS.md](../workflows/WORKFLOWS.md)
