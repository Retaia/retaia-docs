# UI Global Spec

Ce document fixe les regles globales UI qui doivent etre partagees par tous les clients Retaia.

Statut :

* normatif pour les parcours UI, le vocabulaire visible, la navigation et les comportements d'interface
* non substituable par une recommandation locale de `retaia-ui`

## 1) Routes UI canoniques

Workspaces :

* `/review`
* `/library`
* `/rejects`
* `/activity`
* `/settings`
* `/account`
* `/auth`
* `/auth/reset-password`
* `/auth/verify-email`

Routes detail/focus :

* `/review/asset/:assetId`
* `/library/asset/:assetId`
* `/rejects/asset/:assetId`

Regles :

* les routes `*/detail/:assetId` sont retirees du cadrage global
* les labels visibles peuvent etre localises, les routes restent techniques, stables et non localisees
* toute navigation retour depuis une route detail DOIT conserver les query params utiles du workspace d'origine

## 2) Lifecycle UI des actions groupees

Le traitement groupe reste un concept UI uniquement.

Machine d'etat UI normative :

* `idle`
* `selection_active`
* `changes_pending`
* `confirmation_open`
* `executing`
* `result_ready`

Regles :

* la selection multiple ne cree aucune ressource Core dediee
* les changements sont prepares localement en UI avant emission des appels unitaires
* une action groupee sensible DOIT exposer au minimum :
  * preview
  * confirmation explicite
  * resultat agregé (succes / erreurs)
* l'annulation avant confirmation DOIT emettre zero appel Core
* l'execution DOIT rester asset par asset cote Core

## 3) Raccourcis clavier globaux

Un registre global de raccourcis est obligatoire.

Regles :

* les raccourcis ne DOIVENT pas casser la saisie dans `input`, `textarea`, `select`, `contenteditable`
* les raccourcis destructifs ou groupes DOIVENT etre explicites, aides et testes
* une aide raccourcis DOIT etre accessible dans le workspace principal
* toute modification de binding DOIT mettre a jour :
  * le registre global
  * les tests UI
  * l'aide visuelle

Raccourcis minimum a garantir :

* navigation liste suivante / precedente
* ouverture du detail courant
* focus recherche
* toggle selection multiple de l'asset courant
* `KEEP`
* `REJECT`
* `CLEAR`
* undo derniere action
* ouverture/fermeture aide raccourcis

Le registre de reference est :

* [KEYBOARD-SHORTCUTS-REGISTRY.md](./KEYBOARD-SHORTCUTS-REGISTRY.md)

## 4) Vocabulaire UI canonique

Libelles FR visibles normatifs :

* `Review` -> `A traiter`
* `Library` -> `Bibliotheque`
* `Rejects` -> `A supprimer`
* `Activity` -> `Activite`
* `Account` -> `Compte`

Regles :

* ne pas exposer les etats metier bruts dans l'UI si un libelle utilisateur plus clair existe
* `Rejects` est le nom technique de route/espace interne ; `A supprimer` est le libelle visible prioritaire en FR
* le mapping entre libelles UI et constantes metier DOIT rester explicite et teste
* pour la locale `fr`, ces libelles visibles DOIVENT etre utilises sur les surfaces de navigation partagees sauf derogation normative explicite documentee ici

## 5) Shell UI global

Le shell de travail desktop canonical comprend :

* sidebar gauche fixe
* barre de contexte haute dans le contenu
* zone principale liste/detail
* rail droit contextuel

Regles :

* `Compte`, `Parametres`, langue et theme vivent dans la zone basse de la sidebar
* le shell complet ne DOIT etre visible que pour un utilisateur connecte
* les pages publiques auth n'affichent ni sidebar ni contenu metier
* le rail droit est un panneau contextuel unique, pas un sous-systeme de navigation
* `A supprimer` est une entree de navigation de premier niveau

## 6) Themes, densite et modes de vue

Themes obligatoires :

* `system`
* `light`
* `dark`

Regles theme :

* le mode initial recommande est `system`
* le choix utilisateur DOIT etre persiste
* le dark theme ne DOIT PAS etre un noir pur
* les contrastes critiques DOIVENT rester conformes AA

Modes de vue :

* `table`
* `grid`

Regles vue/densite :

* `table` est le mode par defaut
* le choix `table|grid` DOIT etre persiste par workspace
* la densite d'affichage DOIT etre persistable
* les actions et raccourcis principaux DOIVENT rester coherents entre themes et modes de vue

## References associees

* [UI-UX-BRIEF-DESIGNER.md](./UI-UX-BRIEF-DESIGNER.md)
* [UI-REFONTE-RECOMMANDATION.md](./UI-REFONTE-RECOMMANDATION.md)
* [UI-WIREFRAMES-TEXTE.md](./UI-WIREFRAMES-TEXTE.md)
* [KEYBOARD-SHORTCUTS-REGISTRY.md](./KEYBOARD-SHORTCUTS-REGISTRY.md)
* [PROJECT-BRIEF.md](../vision/PROJECT-BRIEF.md)
* [I18N-LOCALIZATION.md](../policies/I18N-LOCALIZATION.md)
* [TEST-PLAN.md](../tests/TEST-PLAN.md)
