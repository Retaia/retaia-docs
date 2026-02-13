# Feature Flag Lifecycle (Normatif)

Objectif: éviter la dette technique liée aux flags long-terme.

Règle principale:

* un feature flag est **temporaire**
* une fois la feature stabilisée et intégrée au comportement nominal (`main/master`), le flag DOIT être supprimé
* la suppression inclut le flag runtime, les branches conditionnelles mortes, les tests obsolètes et la doc de transition

## 1) Phases obligatoires

1. **Introduction**
* définir le nom du flag (`features.<domaine>.<fonction>`)
* définir le comportement OFF/ON et le owner
* ajouter tests OFF + ON

2. **Rollout**
* activer progressivement (environnement/cible)
* observer les métriques et erreurs
* corriger les écarts

3. **Stabilisation**
* feature considérée nominale
* plus aucun rollback produit attendu via ce flag

4. **Assimilation au mainline**
* remplacer la branche conditionnelle par le comportement final unique
* supprimer le flag du payload runtime (`server_policy.feature_flags`)
* supprimer les switches applicatifs corrélés (`app_feature_enabled`) devenus inutiles
* supprimer tests/doc purement liés au mode transitoire

## 2) Gates PR obligatoires

Une PR qui finalise une feature flaggée DOIT contenir:

* suppression explicite du flag dans OpenAPI/contrats/policy runtime
* suppression du code mort OFF/ON devenu inutile
* mise à jour des tests de non-régression sur le comportement final unique
* note d’impact consommateurs (`core/ui/agent/mcp`)

## 3) Anti-patterns interdits

* conserver un flag actif "au cas où" après stabilisation
* empiler plusieurs flags pour une même feature stabilisée
* garder des chemins OFF/ON non testés en CI
* utiliser un flag temporaire comme permission permanente

## 4) Exception

Seuls les kill-switches de sécurité/opérations peuvent rester permanents, avec justification écrite et owner explicite.
