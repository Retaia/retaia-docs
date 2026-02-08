# AI‑Assisted Development

Ce document définit les règles d’utilisation de l’IA (assistant ou agent codeur) dans le projet **Retaia**.

Ces règles sont **normatives**. Toute contribution qui ne les respecte pas peut être refusée, même si le code fonctionne.


## 1. Définition

Le projet Retaia autorise le **développement assisté par IA** sous deux formes :

* **Assistant IA** : outil de suggestion (complétion, explication, refactor local, génération de tests ou de documentation).
* **Agent codeur** : outil capable de produire des changements multi‑fichiers de manière autonome.

Dans tous les cas, l’IA est considérée comme un **outil**, jamais comme une autorité de décision.


## 2. Principe fondamental

> L’IA peut proposer du code.
> Le projet n’accepte que du code **compris, relu et validé par un humain**.

Aucun changement n’est accepté sur la base de “ça a l’air de marcher”.


## 3. Autorisations

L’utilisation de l’IA est **autorisée** pour :

* génération de squelettes (controllers, services, DTO, scripts)
* refactors locaux et ciblés
* amélioration de lisibilité
* écriture ou amélioration de tests
* documentation technique
* scripts d’infrastructure ou de tooling


## 4. Interdictions strictes

L’IA (assistant ou agent) **ne doit jamais** :

* modifier la machine à états sans modification explicite de `STATE-MACHINE.md`
* modifier l’API sans mise à jour de `API-CONTRACTS.md` et/ou OpenAPI
* introduire des décisions métier implicites
* effectuer des opérations destructives non documentées (move, delete, purge)
* pousser directement sur la branche `master`
* introduire ou manipuler des secrets (tokens, clés, credentials)

Toute violation rend la contribution invalide.


## 5. Règles de contribution (PR)

Toute contribution issue d’une IA **doit** :

* passer par une Pull Request
* inclure une description humaine claire du changement
* expliquer pourquoi l’IA a été utilisée
* lister les fichiers modifiés et leur rôle
* préciser les risques et le plan de rollback

Les changements purement mécaniques (formatage, renommage massif) doivent être isolés dans une PR dédiée.


## 6. Spécifications et contrat

Toute PR qui impacte :

* le comportement du système
* les transitions d’état
* les workflows
* l’API ou les contrats

**doit inclure** la mise à jour correspondante dans le repository `retaia-docs`.

Le code ne fait jamais foi sur les spécifications.


## 7. Commits et historique

* Les commits produits par une IA doivent respecter les **Conventional Commits**.
* Les commits intermédiaires générés par un agent sont autorisés sur une branche `feature/*`.
* Avant merge, l’historique doit être nettoyé (rebase ou squash) en commits propres et intentionnels.


## 8. Sécurité et données

Il est interdit :

* d’inclure des données réelles (clients, rushes, chemins NAS) dans des prompts externes
* de copier-coller des extraits sensibles dans un contexte non maîtrisé

Les environnements de développement doivent utiliser des données factices ou anonymisées.


## 9. Responsabilité

La responsabilité d’un changement appartient **toujours** à l’humain qui le merge.

L’IA n’est jamais responsable d’un bug, d’une régression ou d’une violation de contrat.


## 10. Objectif

L’objectif du développement assisté par IA dans Rush est :

* d’augmenter la vitesse d’exécution
* sans réduire la lisibilité
* sans affaiblir les contrats
* sans créer de dette implicite

Toute utilisation de l’IA qui va à l’encontre de ces objectifs doit être stoppée.
