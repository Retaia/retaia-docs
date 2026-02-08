# CHANGE MANAGEMENT — RushCatalog + RushIndexer

Ce document définit les **règles de gestion du changement** du projet RushCatalog + RushIndexer.

Il vise à garantir la **stabilité à long terme**, la **prévisibilité du comportement**, et l’absence de surprises lors des évolutions.


## Philosophie générale

Le projet privilégie :

* la robustesse plutôt que la nouveauté
* l’explicite plutôt que l’implicite
* la traçabilité plutôt que la magie

Principe directeur :

> **Aucun changement ne doit diminuer le contrôle humain ni introduire un comportement destructif implicite.**


## Catégories de changements

### 1) Changements internes (non visibles)

Exemples :

* refactorisation du code
* optimisation de performances
* amélioration interne du polling ou des jobs

Règles :

* aucun impact sur les workflows
* aucun impact sur les états
* aucun impact sur l’API publique

Ces changements ne nécessitent pas de migration ni de communication utilisateur.


### 2) Changements compatibles (évolution contrôlée)

Exemples :

* ajout d’un nouveau type de dérivé (ex: nouveau proxy)
* ajout d’un champ optionnel
* ajout d’un job secondaire
* ajout d’un événement métier

Règles :

* rétrocompatibilité obligatoire
* valeurs par défaut explicites
* migrations non destructives
* documentation mise à jour


### 3) Changements structurels (impact fort)

Exemples :

* modification de la machine à états
* modification du lifecycle (nouvel état, transition)
* modification des règles de batch move
* modification de la politique de purge
* modification du rôle des agents

Règles :

* justification écrite obligatoire
* mise à jour **préalable** de la documentation
* migration de données explicite
* communication utilisateur requise


## Machine à états

La machine à états définie dans `STATE-MACHINE.md` est **normative**.

Règles :

* aucune transition implicite
* aucune transition ajoutée sans mise à jour du document
* toute implémentation doit refuser les transitions non autorisées


## Processing & dérivés

### Pipeline de processing

* Le processing est assuré par des **agents en arrière-plan**.
* Toute modification du pipeline (ordre, contenu, obligations) est un changement structurel.

### Dérivés

* Les dérivés sont **recréables**.
* Toute modification de format de proxy ou de dérivé doit :

    * incrémenter une version
    * invalider les dérivés existants
    * déclencher un reprocess contrôlé


## Décisions humaines

* Les décisions KEEP / REJECT sont **intangibles**.
* Aucune évolution ne peut permettre leur modification automatique.
* Toute tentative de contournement est un anti-pattern.


## Jobs & agents

* Les agents sont considérés comme **non fiables** (crash possibles).
* Les jobs doivent être idempotents.
* Toute modification des règles de lock, TTL ou retry est un changement structurel.


## API & contrats

* L’API est un **contrat stable**.
* Toute rupture de compatibilité nécessite :

    * une nouvelle version d’API (`/v2`)
    * une période de transition

L’UI web, RushIndexer et les futurs clients (ex: MCP) consomment la même API.


## Purge & destruction de données

* La purge (`REJECTED → PURGED`) est une action **destructive**.
* Toute évolution de la politique de purge est un changement structurel.
* Aucune purge ne peut concerner `ARCHIVED`.
* Toute purge doit supprimer **originaux + sidecars + dérivés**.


## Documentation comme source de vérité

Ordre de priorité :

1. Documentation (machine à états, workflows, définitions)
2. Implémentation

Si le code contredit la documentation, le code est considéré comme incorrect.


## Règle finale

Si une évolution :

* réduit la lisibilité du système
* introduit une action destructive implicite
* affaiblit la décision humaine

Alors cette évolution est **refusée par design**.


## Branching & déploiement

La branche principale du projet est **`master`**.

Règles :

- `master` est **toujours déployable**.
- Aucun push direct n’est autorisé sur `master`.
- Tout changement passe par une Pull Request.
- Les branches `feature/*` sont de courte durée.
- Les branches `hotfix/*` sont créées depuis `master` pour les correctifs urgents.

Le projet adopte une stratégie **trunk-based** :

- Les fonctionnalités stables sont mergées dès qu’elles sont prêtes.
- Le système peut être déployé plusieurs fois par jour.
- Les fonctionnalités incomplètes ne doivent jamais casser `master` et doivent être protégées
  (feature flags, endpoints non exposés, configuration).

Chaque merge sur `master` rend le déploiement possible immédiatement.

Les déploiements sont identifiés par :

- le hash Git
- et/ou un tag de type `deploy-YYYYMMDD-HHMM`.

## Commit convention

Tous les repositories du projet Rush (server, agent, cli, infra, specs)
DOIVENT utiliser la convention Conventional Commits.

Format obligatoire :

<type>(<scope>): <description>

Types autorisés :
- feat
- fix
- refactor
- perf
- docs
- test
- chore
- build
- ci

Règles :
- Un commit = une intention
- Pas de commit "misc", "wip", "update"
- Toute modification de comportement doit être au minimum un `feat` ou un `fix`
- Toute modification incompatible avec l’existant doit être marquée `BREAKING CHANGE`

Exemples valides :
- feat(api): add batch move preview endpoint
- fix(agent): prevent double claim on job
- docs(specs): clarify state transition constraints

Dans le repo rush-specs :
- toute modification de comportement → feat
- toute clarification sans changement → docs
- toute correction d’ambiguïté → fix 

  Les commits générés avec l’assistance d’une IA sont soumis aux mêmes règles
  et doivent être compris et validés par un humain avant merge.