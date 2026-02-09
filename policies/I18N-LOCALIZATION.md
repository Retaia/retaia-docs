# I18N & Localization Policy — Retaia Core + Retaia Agent

Ce document définit les règles normatives pour rendre les applications Retaia multilingues.

## 1) Objectif

Permettre un usage fiable en plusieurs langues sans ambiguïté métier, ni divergence fonctionnelle.

## 2) Principes

* l'anglais (`en`) est la langue canonique de référence pour les clés et textes source
* les langues d'interface sont configurables par utilisateur
* aucune logique métier ne dépend d'une chaîne traduite
* les codes d'erreur, états et identifiants restent stables et non traduits
* une traduction manquante ne bloque jamais l'exécution

## 3) Séparation stricte contenu / logique

Obligatoire :

* stocker les textes UI dans des catalogues de traduction (clés stables)
* manipuler en code des constantes métier (`state`, `error_code`, `job_type`)
* traduire à l'affichage, jamais dans le modèle métier

Interdit :

* brancher de la logique sur un libellé localisé
* persister en base un état métier traduit
* parser un message traduit pour décider d'une action

## 4) Langues supportées v1

* minimum requis : `en`, `fr`
* ajout de langue autorisé sans rupture API
* fallback obligatoire : `locale utilisateur -> en -> clé brute`

## 5) Contrat API

* l'API expose des codes stables (ex: `STATE_CONFLICT`, `DECISION_PENDING`)
* l'API peut exposer un `message` localisé optionnel, mais le client ne doit pas en dépendre
* le client envoie `Accept-Language` pour les messages d'interface
* les payloads métier restent indépendants de la locale

## 6) Contrat UI

* toute chaîne visible utilisateur doit être externalisée
* les écrans de review, décision et batch move doivent être entièrement localisables
* les formats date/heure/nombre utilisent la locale utilisateur
* les termes critiques (KEEP / REJECT) doivent conserver un mapping explicite vers leurs constantes métier

## 7) Qualité et tests

* test automatique de couverture des clés par locale supportée
* test de fallback quand une clé manque
* test de non-régression sur les libellés d'actions destructives
* revues produit sur la clarté des traductions à fort enjeu (move, purge, decision)

## 8) Migration & gouvernance

* toute nouvelle chaîne UI doit être ajoutée en `en` et `fr` avant merge
* toute suppression/renommage de clé doit être tracée dans le changelog
* une release ne peut pas introduire de régression bloquante i18n sur les parcours critiques

## Références associées

* [PROJECT-BRIEF.md](../vision/PROJECT-BRIEF.md)
* [API-CONTRACTS.md](../api/API-CONTRACTS.md)
* [ERROR-MODEL.md](../api/ERROR-MODEL.md)
* [SUCCESS-CRITERIA.md](../success-criteria/SUCCESS-CRITERIA.md)
