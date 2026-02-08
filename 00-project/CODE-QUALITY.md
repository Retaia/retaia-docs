# CODE QUALITY — RushCatalog & RushIndexer

Ce document définit les **règles de qualité de code** pour l’ensemble du projet Rush.

Ces règles sont **normatives** : elles s’appliquent à tous les repositories (server, agent, cli, infra, specs).
Les repositories peuvent ajouter des règles **plus strictes**, mais ne doivent jamais contredire ce document.


## 1) Principes

### Quality over quantity
Le projet privilégie :
- un code lisible et maintenable
- des changements petits et réversibles
- une traçabilité claire du “pourquoi”

Sont refusés :
- les PR “fourre-tout”
- les changements massifs sans valeur fonctionnelle
- la complexité ajoutée “au cas où”

### Pas de magie
Tout comportement important doit être :
- explicite
- documenté (dans `rush-specs`)
- testable


## 2) Règles de Pull Request

Une PR DOIT :
- avoir un objectif unique clairement énoncé
- rester petite (ou être découpée)
- éviter de mélanger refactor + feature + formatting
- décrire les risques et le rollback si nécessaire

Une PR NE DOIT PAS :
- introduire un changement de comportement sans mise à jour des specs
- modifier les specs via un repo applicatif (voir `AGENT.md` côté repos)


## 3) Tests (obligatoires)

### Politique générale
Toute modification qui change le comportement DOIT être couverte par des tests.

Minimum attendu :
- logique métier : **tests unitaires**
- intégration API / DB / IO : **tests d’intégration**
- contrats API / protocoles : **tests contractuels** (au moins scénarios)

### Bugs
Tout bug corrigé DOIT ajouter un test de non-régression.

### Idempotence / retries
Toute logique liée à :
- leases / TTL
- claim atomique
- retries
  DOIT être testée (au moins sur les chemins critiques).


## 4) Coverage (progressif mais opposable)

Objectif : augmenter la confiance sans encourager la triche.

Règles :
- Il est interdit de **faire baisser** le coverage global du repo (à tolérance technique près).
- Toute PR qui touche du code métier DOIT augmenter ou maintenir le coverage sur les fichiers modifiés.
- Toute PR de correction de bug DOIT ajouter au moins un test.

Seuils (v0, ajustables par repo) :
- code métier touché : viser ≥ 80% (ligne ou branche selon l’outil)
- exceptions possibles uniquement si justifiées dans la PR

Le coverage n’est pas un KPI marketing : il sert à éviter les régressions, pas à “faire un chiffre”.


## 5) Lisibilité et design

### Règles de base
- fonctions courtes et nommées clairement
- pas d’effets de bord cachés
- erreurs explicites (pas de “fail silently”)
- logs utiles, pas verbeux

### Complexité
Si une logique devient complexe :
- l’extraire dans une unité testable
- documenter l’invariant dans les specs si c’est un comportement système


## 6) Dépendances et sécurité

- éviter les dépendances inutiles
- toute dépendance doit être justifiée
- pas de secrets dans le code, les commits ou les logs
- pas de données réelles sensibles dans les tests


## 7) Qualité spécifique par repo

Chaque repo peut définir dans `docs/` :
- outils de lint / format / analyse statique
- commandes de test
- conventions locales

Mais :
- `docs/` est **non normatif**
- aucune règle de comportement système ne doit être définie dans `docs/`


## 8) Critère final de refus

Une contribution est refusée si elle :
- réduit la lisibilité globale
- introduit une action destructive implicite
- affaiblit le contrôle humain
- contourne les specs ou les tests