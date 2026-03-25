# Wireframes texte - refonte UI

> Statut : wireframes UI normatifs pour `UI_WEB`.
> Source de cadrage : [UI-GLOBAL-SPEC.md](UI-GLOBAL-SPEC.md) et [UI-REFONTE-RECOMMANDATION.md](UI-REFONTE-RECOMMANDATION.md)
> Objectif : decrire les ecrans cibles en filaire texte et imposer la structure fonctionnelle minimale partagee.

## 1. Principes de lecture

Ces wireframes sont :

- desktop-first
- centres sur l'usage
- alignes avec un shell Tailadmin
- rediges avec des labels UI simples
- alignes avec les regles normatives publiees ailleurs dans le corpus UI
- normatifs pour la structure fonctionnelle minimale, les blocs obligatoires et leur hierarchie visible

Regle :

- l'implementation visuelle finale peut varier, mais l'absence d'un bloc ou d'un patron explicitement impose ici constitue un ecart documentaire pour `UI_WEB`

Conventions :

- colonne gauche : navigation ou liste
- centre : zone principale
- colonne droite : rail contextuel
- `[ ... ]` : bloc ou composant
- `( )` : action ou controle

## 2. Shell global

```text
+--------------------------------------------------------------------------------------------------+
| SIDEBAR                            | BARRE DE CONTEXTE                                           |
|------------------------------------+-------------------------------------------------------------|
| Logo / nom app                     | Titre page        Sous-titre        Compteurs      Actions |
|                                    |-------------------------------------------------------------|
| > A traiter                        |                                                             |
|   Bibliotheque                     |                                                             |
|   A supprimer                      |                                                             |
|   Activite                         |                 ZONE PRINCIPALE                             |
|                                    |                                                             |
|------------------------------------|                                                             |
| Langue                             |                                                             |
| Theme : Systeme / Clair / Sombre   |                                                             |
| Connexion / source                 |                                                             |
| Parametres                         |                                                             |
| Compte                             |                                                             |
+--------------------------------------------------------------------------------------------------+
```

Notes :

- la sidebar reste stable sur toutes les pages de travail
- la barre de contexte change selon la page
- le theme switch doit etre toujours accessible
- `A supprimer` est une entree de navigation a part entiere
- `Compte` reste dans la zone basse de la sidebar
- si l'utilisateur n'est pas connecte, ce shell n'apparait pas
- hors connexion, seuls les ecrans publics auth sont visibles : connexion, reinitialisation du mot de passe, verification e-mail

## 3. Wireframe - A traiter

Objectif :

- trier rapidement les nouveaux elements
- garder liste et detail visibles ensemble
- faire apparaitre les actions groupees sans casser le tri unitaire

```text
+--------------------------------------------------------------------------------------------------------------+
| SIDEBAR         | A TRAITER | 128 elements | [Recherche...] [Type] [Etat] [Date] [Table|Grille] (Suivant) |
|-----------------+--------------------------------------------------------------------------------------------|
| > A traiter     | LISTE                                             | DETAIL                              | RAIL |
|   Bibliotheque  |---------------------------------------------------+-------------------------------------+------|
|   A supprimer   | [ ] vignette  Nom fichier        A traiter   >    | [Preview media large]               | Sel. |
|   Activite      | [ ] vignette  Nom fichier        Pret a examiner  |-------------------------------------|------|
|                 | [ ] vignette  Nom fichier        A decider        | [Play proxy] [00:12 / 01:42]        | 12   |
|                 | [ ] vignette  Nom fichier        A traiter        | Etat visible                        | sel. |
|-----------------| [ ] vignette  Nom fichier        A traiter        | Date / type / duree / poids         |------|
| Langue          |                                                   | Raccourcis : Space / K / R / ->     |      |
| Theme           |                                                   | (Conserver) (Ecarter) (Annuler)     | [Sel.|
| Connexion       |                                                   |-------------------------------------| mult.|
| Parametres      |                                                   | Tags                                | cours|
| Compte          |                                                   | [tag] [tag] [+ Ajouter]             | ou   |
|                 |                                                   |-------------------------------------| vide]|
|                 |                                                   | Projects                            |      |
|                 |                                                   | [Projet A] [Projet B] [+ Ajouter]   |      |
|                 |                                                   |-------------------------------------|      |
|                 |                                                   | Notes                               |      |
|                 |                                                   | [zone de texte]                     | [Aide|
|                 |                                                   |-------------------------------------| racc]|
|                 |                                                   | Infos techniques / transcript audio |      |
+--------------------------------------------------------------------------------------------------------------+
```

Notes UX :

- la liste doit accepter souris + clavier
- un clic ligne selectionne, la case coche ajoute a la selection multiple
- `Suivant` doit etre visible sans monopoliser l'ecran
- le rail droit peut etre replie si aucune selection multiple n'est active
- le switch `Table|Grille` doit etre visible comme un controle de vue rapide
- `Table` est la vue par defaut
- le choix `Table|Grille` doit etre persiste
- le preview doit changer selon le type d'asset : image, video, audio, fallback
- le transcript ne doit apparaitre que pour une video avec piste audio ou un asset audio only
- le bloc `Projects` illustre le rattachement metier humain explicite, distinct des tags et de la localisation
- `Space` lit ou met en pause le proxy, `K` conserve, `R` ecarte, `←` passe a l'asset precedent, `→` passe a l'asset suivant

### Variante grille - A traiter

```text
+--------------------------------------------------------------------------------------------------------------+
| SIDEBAR         | A TRAITER | 128 elements | [Recherche...] [Type] [Etat] [Date] [Table|Grille] (Suivant) |
|-----------------+--------------------------------------------------------------------------------------------|
| > A traiter     | GRILLE                                            | DETAIL                              | RAIL |
|   Bibliotheque  |---------------------------------------------------+-------------------------------------+------|
|   A supprimer   | [ ] [thumb] Nom fichier                           | [Preview media large]               | Sel. |
|   Activite      |     type | date | etat visible                    |-------------------------------------| mult.|
|                 | [ ] [thumb] Nom fichier                           | [Play proxy] [00:12 / 01:42]        |------|
|                 |     type | date | etat visible                    |                                     |      |
|-----------------| [ ] [thumb] Nom fichier                           |                                     |      |
| Langue          |     type | date | etat visible                    |                                     |      |
| Theme           | [ ] [thumb] Nom fichier                           |                                     |      |
| Connexion       |     type | date | etat visible                    |                                     |      |
| Parametres      |                                                   |                                     |      |
| Compte          |                                                   |                                     |      |
+--------------------------------------------------------------------------------------------------------------+
```

## 4. Wireframe - A traiter avec selection multiple active

```text
+--------------------------------------------------------------------------------------------------------------+
| SIDEBAR         | A TRAITER | 128 elements | 12 selectionnes | (Voir les changements) (Appliquer)         |
|-----------------+--------------------------------------------------------------------------------------------|
| > A traiter     | LISTE                                             | DETAIL                              | SEL. |
|   Bibliotheque  |---------------------------------------------------+-------------------------------------+------|
|   A supprimer   | [x] item 1                                        | [Preview media]                     | 12   |
|   Activite      | [x] item 2                                        |-------------------------------------| elem |
|                 | [ ] item 3                                        | Nom / etat / tags / notes           |------|
|-----------------| [x] item 4                                        |                                     | Act. |
| Langue          |                                                   |                                     | [Con-|
| Theme           |                                                   |                                     | server]
| Connexion       |                                                   |                                     | [Ecar-|
| Parametres      |                                                   |                                     | ter ]|
| Compte          |                                                   |                                     |------|
|                 |                                                   |                                     | Chang|
|                 |                                                   |                                     | ements
|                 |                                                   |                                     | en   |
|                 |                                                   |                                     | atten|
|                 |                                                   |                                     | te   |
|                 |                                                   |                                     |------|
|                 |                                                   |                                     | + Tag|
|                 |                                                   |                                     | - Tag|
|                 |                                                   |                                     | Note |
|                 |                                                   |                                     | comm.|
|                 |                                                   |                                     |------|
|                 |                                                   |                                     | Voir |
|                 |                                                   |                                     | Appl.|
|                 |                                                   |                                     | Annul|
+--------------------------------------------------------------------------------------------------------------+
```

Notes UX :

- le rail de selection multiple doit etre la seule source d'action de masse
- l'utilisateur doit toujours voir le detail de l'element courant
- les actions groupees se preparent d'abord dans le rail : tags, note commune, `Conserver`, `Ecarter`
- `Voir les changements` montre les changements a appliquer
- `Appliquer` applique les changements en attente
- `Annuler` annule les changements en attente
- aucune navigation vers une page dediee n'est necessaire
- le rail droit est un panneau contextuel unique, pas un sous-systeme
- les actions unitaires restent dans le detail, les actions groupees restent dans le rail
- le rail a 3 etats : neutre, changements en attente, resultat apres application

## 5. Wireframe - Bibliotheque

Objectif :

- retrouver vite
- lire confortablement
- permettre une requalification ponctuelle
- reprendre le meme patron d'ecran que `A traiter`

```text
+--------------------------------------------------------------------------------------------------------------+
| SIDEBAR         | BIBLIOTHEQUE | [Recherche dominante..........................] [Table|Grille] (Exporter) |
|-----------------+--------------------------------------------------------------------------------------------|
|   A traiter     | [Recherche...] [Etat] [Type] [Date] [Tri] [Densite]                                     |
| > Bibliotheque  |--------------------------------------------------------------------------------------------|
|   A supprimer   | LISTE                                             | DETAIL                              | RAIL |
|   Activite      |---------------------------------------------------+-------------------------------------+------|
|                 | [ ] vignette  Nom / tags / date / type            | [Preview]                           | Sel. |
|                 | [ ] vignette  Nom / tags / date / type            |-------------------------------------| mult.|
|-----------------| [ ] vignette  Nom / tags / date / type            | Nom                                 |------|
| Langue          | [ ] vignette  Nom / tags / date / type            | Classe / Ecarte / A decider         | Infos|
| Theme           |                                                   |-------------------------------------|------|
| Connexion       |                                                   | Tags / Projects / Notes             |      |
| Parametres      |                                                   |-------------------------------------|      |
| Compte          |                                                   | Transcript / metadata detaillees    |      |
+--------------------------------------------------------------------------------------------------------------+
```

Notes UX :

- la recherche est l'action principale
- le layout doit rester tres proche de `A traiter`
- le rail droit peut afficher aide filtres, vues enregistrees, activite recente
- les actions groupees suivent la meme logique de rail droit que `A traiter`
- les differences principales portent sur les actions et le niveau d'urgence
- `Table` est la vue par defaut
- le choix `Table|Grille` doit etre persiste
- le detail Bibliotheque illustre un bloc `Projects` visible au meme niveau que les autres metadonnees humaines editables

### Variante grille - Bibliotheque

```text
+--------------------------------------------------------------------------------------------------------------+
| SIDEBAR         | BIBLIOTHEQUE | [Recherche dominante..........................] [Table|Grille] (Exporter) |
|-----------------+--------------------------------------------------------------------------------------------|
|   A traiter     | [Etat] [Type] [Date] [Tri] [Densite]                                                     |
| > Bibliotheque  |--------------------------------------------------------------------------------------------|
|   A supprimer   | GRILLE                                            | DETAIL                              | RAIL |
|   Activite      |---------------------------------------------------+-------------------------------------+------|
|                 | [ ] [thumb] Nom fichier                           | [Preview]                           | Sel. |
|                 |     type | date | etat visible                    |-------------------------------------| mult.|
|-----------------| [ ] [thumb] Nom fichier                           | Nom                                 |------|
| Langue          |     tags cles | etat visible                       | Tags / Projects / Notes             | Infos|
| Theme           | [ ] [thumb] Nom fichier                           |-------------------------------------|------|
| Connexion       |     type | date | etat visible                    | Transcript / metadata detaillees    |      |
| Parametres      |                                                   |                                     |      |
| Compte          |                                                   |                                     |      |
+--------------------------------------------------------------------------------------------------------------+
```

## 6. Wireframe - Vue "A supprimer"

Objectif :

- rendre lisibles les elements ecartes
- reprendre la structure de `Bibliotheque` avec des actions plus limitees

```text
+--------------------------------------------------------------------------------------------------------------+
| SIDEBAR         | A SUPPRIMER | [Recherche...] [Date] [Anciennete] [Tri] [Table|Grille]                   |
|-----------------+--------------------------------------------------------------------------------------------|
|   A traiter     | RESULTATS                                         | DETAIL                              | RAIL |
|   Bibliotheque  |---------------------------------------------------+-------------------------------------+------|
| > A supprimer   | [ ] vignette Nom / tags / date / type            | [Preview]                           | Sel. |
|   Activite      | [ ] vignette Nom / tags / date / type            |-------------------------------------| mult.|
|                 | [ ] vignette Nom / tags / date / type            | Nom                                 |------|
|-----------------|                                                   | Ecarte / A supprimer                | Act. |
| Langue          |                                                   | Anciennete / date d'ecartement      | [Rem.|
| Theme           |                                                   |-------------------------------------| a tr.]|
| Connexion       |                                                   | Tags / Notes                        |------|
| Parametres      |                                                   |-------------------------------------| Global
| Compte          |                                                   | (Remettre a traiter)                | purge|
|                 |                                                   |-------------------------------------| (Sup.|
|                 |                                                   | Historique / metadata detaillees    | defin.)|
+--------------------------------------------------------------------------------------------------------------+
```

Notes UX :

- la page doit reutiliser au maximum le meme layout que `Bibliotheque`
- les differences portent surtout sur les actions autorisees
- en selection multiple, l'action principale est `Remettre a traiter`
- le rail droit suit la meme logique contextuelle, mais avec moins d'actions
- l'apercu des changements ne doit montrer que `Remettre a traiter`
- `Supprimer definitivement` reste une action globale distincte et fortement confirmee
- `Table` est la vue par defaut
- le choix `Table|Grille` doit etre persiste

### Variante grille - A supprimer

```text
+--------------------------------------------------------------------------------------------------------------+
| SIDEBAR         | A SUPPRIMER | [Recherche...] [Date] [Anciennete] [Tri] [Table|Grille]                   |
|-----------------+--------------------------------------------------------------------------------------------|
|   A traiter     | GRILLE                                            | DETAIL                              | RAIL |
|   Bibliotheque  |---------------------------------------------------+-------------------------------------+------|
| > A supprimer   | [ ] [thumb] Nom fichier                           | [Preview]                           | Sel. |
|   Activite      |     type | date | anciennete                       |-------------------------------------| mult.|
|                 | [ ] [thumb] Nom fichier                           | Nom                                 |------|
|-----------------|     type | date | etat visible                    | A supprimer / anciennete            | Act. |
| Langue          | [ ] [thumb] Nom fichier                           |-------------------------------------| [Rem.|
| Theme           |     type | date | anciennete                       | Tags / Notes                        | a tr.]|
| Connexion       |                                                   |-------------------------------------|------|
| Parametres      |                                                   | Historique / metadata detaillees    | Global
| Compte          |                                                   |                                     | purge|
+--------------------------------------------------------------------------------------------------------------+
```

## 7. Wireframe - Activite

Objectif :

- voir ce qui a ete fait
- comprendre une action ou une action groupee
- annuler rapidement quand c'est possible

```text
+--------------------------------------------------------------------------------------------------------------+
| SIDEBAR         | ACTIVITE | [Type action] [Utilisateur] [Date] [Statut] (Annuler la derniere action)  |
|-----------------+--------------------------------------------------------------------------------------------|
|   A traiter     | JOURNAL                                           | DETAIL                              |
|   Bibliotheque  |---------------------------------------------------+-------------------------------------|
|   A supprimer   | 10:42  Action groupee    12 elements    succes    | Titre action                        |
| > Activite      | 10:31  Element conserve  1 element      succes    |-------------------------------------|
|                 | 10:27  Notes modifiees   1 element      succes    | Resume                              |
|-----------------| 10:08  Action groupee    8 elements     partiel   |-------------------------------------|
| Langue          | 09:52  Element ecarte    1 element      succes    | Elements concernes                  |
| Theme           |                                                   | [table ou liste]                    |
| Connexion       |                                                   |-------------------------------------|
| Parametres      |                                                   | Erreurs / details / export          |
| Compte          |                                                   |-------------------------------------|
|                 |                                                   | (Voir les details) (Exporter)       |
+--------------------------------------------------------------------------------------------------------------+
```

## 8. Wireframe - Detail plein ecran

Usage :

- lien direct
- verification concentree
- travail sur grand media

```text
+--------------------------------------------------------------------------------------------------+
| (Retour)  Nom du fichier                                              [Etat]   (Suivant)        |
|--------------------------------------------------------------------------------------------------|
|                                              PREVIEW                                             |
|                           [Play proxy] [00:12 / 01:42] [Volume]                                 |
|                                                                                                  |
|--------------------------------------------------------------------------------------------------|
| (Conserver) (Ecarter) (Annuler)    Tags [tag] [tag] [+]    Projects [Projet A] [+]            |
|--------------------------------------------------------------------------------------------------|
| Infos essentielles                 | Infos detaillees                 | Transcript / historique    |
| date, type, duree, poids           | chemin logique, source, etc.    | texte ou etat indisponible |
| lieu / captured_at / projects      | description projet si presente  |                           |
+--------------------------------------------------------------------------------------------------+
```

Notes UX :

- le preview doit etre adapte au type d'asset, avec un rendu distinct pour image, video, audio
- `Space` pilote la lecture du proxy
- `K` declenche `Conserver`
- `R` declenche `Ecarter`
- `←` passe a l'asset precedent quand le contexte le permet
- `→` passe a l'asset suivant quand le contexte le permet
- le transcript n'apparait que si le media contient de l'audio
- si le proxy est indisponible, afficher un fallback lisible plutot qu'un lecteur vide
- le detail plein ecran illustre `Projects` comme contexte humain de reutilisation, sans le confondre avec le lieu de prise

## 9. Wireframe - Connexion

Regle :

- hors connexion, seuls les ecrans auth publics sont visibles : `Connexion`, `Reinitialiser le mot de passe`, `Verification e-mail`
- aucun menu lateral, aucune page metier, aucun contenu applicatif ne doit apparaitre
- apres connexion reussie, l'utilisateur arrive dans le shell principal
- si l'utilisateur est deja connecte, cet ecran ne doit jamais apparaitre
- dans ce cas, `/auth` redirige vers `/review`

```text
+--------------------------------------------------------------------------------------+
| Logo / nom app                                                                       |
|--------------------------------------------------------------------------------------|
|                         BIENVENUE                                                    |
|               Connectez-vous pour acceder a l'outil                                  |
|--------------------------------------------------------------------------------------|
| [E-mail..............................................]                               |
| [Mot de passe........................................]                               |
| (Se connecter)                                                                       |
|--------------------------------------------------------------------------------------|
| Mot de passe oublie | Verification e-mail | Double authentification                  |
|--------------------------------------------------------------------------------------|
| Etat de connexion API / message de session                                           |
+--------------------------------------------------------------------------------------+
```

## 10. Wireframe - Reinitialiser le mot de passe

Regle :

- ecran `public only`
- accessible depuis un lien avec token
- si l'utilisateur est deja connecte, redirection vers `/review`

```text
+--------------------------------------------------------------------------------------+
| Logo / nom app                                                                       |
|--------------------------------------------------------------------------------------|
|                    DEFINIR UN NOUVEAU MOT DE PASSE                                   |
|--------------------------------------------------------------------------------------|
| [Nouveau mot de passe..............................]                                 |
| [Confirmer le mot de passe.........................]                                 |
| (Enregistrer le nouveau mot de passe)                                                |
|--------------------------------------------------------------------------------------|
| Etat : lien valide | lien invalide | lien expire                                     |
|--------------------------------------------------------------------------------------|
| Apres succes : (Aller a la connexion)                                                |
+--------------------------------------------------------------------------------------+
```

## 11. Wireframe - Verification e-mail

Regle :

- ecran `public only`
- accessible depuis un lien avec token
- si l'utilisateur est deja connecte, redirection vers `/review`

```text
+--------------------------------------------------------------------------------------+
| Logo / nom app                                                                       |
|--------------------------------------------------------------------------------------|
|                        VERIFICATION DE L'E-MAIL                                      |
|--------------------------------------------------------------------------------------|
| Verification en cours...                                                             |
|--------------------------------------------------------------------------------------|
| Etat succes : votre e-mail est verifie                                               |
| Etat erreur : lien invalide ou expire                                                |
|--------------------------------------------------------------------------------------|
| (Renvoyer l'e-mail de verification)   (Aller a la connexion)                         |
+--------------------------------------------------------------------------------------+
```

## 12. Wireframe - Parametres

```text
+--------------------------------------------------------------------------------------------------+
| SIDEBAR         | PARAMETRES                                                                     |
|-----------------+--------------------------------------------------------------------------------|
|   A traiter     | [Connexion API]                                                                |
|   Bibliotheque  | URL de base [............................]                                      |
|   A supprimer   | Jeton       [............................]    (Tester) (Enregistrer)           |
|   Activite      |--------------------------------------------------------------------------------|
|-----------------| [Source de donnees]                                                            |
| Langue          | (Mock) (API)                                                                   |
| Theme           |--------------------------------------------------------------------------------|
| Connexion       | [Preferences d'interface]                                                      |
| > Parametres    | Langue [FR/EN]   Theme [Systeme/Clair/Sombre]   Densite [..]                 |
| Compte          |--------------------------------------------------------------------------------|
|                 | [Valeurs verrouillees par l'environnement]                                     |
|                 | message informatif / lecture seule                                              |
+--------------------------------------------------------------------------------------------------+
```

## 13. Wireframe - Compte

```text
+--------------------------------------------------------------------------------------------------+
| SIDEBAR         | COMPTE                                                                         |
|-----------------+--------------------------------------------------------------------------------|
|   A traiter     | [Carte utilisateur]                                                            |
|   Bibliotheque  | Nom                                                                             |
|   A supprimer   | E-mail                                                                          |
|   Activite      | Role / type de compte                                                           |
| > Compte        |--------------------------------------------------------------------------------|
|-----------------| [Securite]                                                                      |
| Langue          | E-mail verifie : Oui / Non                                                     |
| Theme           | Double authentification : Active / Inactive                                    |
| Connexion       | Codes de recuperation : disponibles / non disponibles                           |
| Parametres      |--------------------------------------------------------------------------------|
| Compte          | [Actions]                                                                       |
|                 | (Se deconnecter)                                                                |
|                 | autres actions uniquement si l'API les supporte                                 |
+--------------------------------------------------------------------------------------------------+
```

## 14. Etats critiques a maquetter

### 14.1 Aucun element a traiter

```text
+------------------------------------------------------------------+
| A TRAITER                                                        |
|------------------------------------------------------------------|
|                     Aucun element a traiter                      |
|        Tout est a jour. Revenez plus tard ou changez vos filtres |
|                     (Actualiser)                                 |
+------------------------------------------------------------------+
```

### 14.2 Aucun resultat en bibliotheque

```text
+------------------------------------------------------------------+
| BIBLIOTHEQUE                                                     |
|------------------------------------------------------------------|
|                     Aucun resultat                               |
|        Essayez une autre recherche ou retirez un filtre          |
|            (Effacer les filtres)   (Retour a la vue par defaut)  |
+------------------------------------------------------------------+
```

### 14.3 Erreur reseau

```text
+--------------------------------------------------------------------------------------+
| Message                                                                               |
|--------------------------------------------------------------------------------------|
| Impossible de charger les donnees pour le moment.                                     |
| Verifiez la connexion ou reessayez.                                                   |
| (Reessayer)    (Voir les details)                                                     |
+--------------------------------------------------------------------------------------+
```

### 14.4 Confirmation action sensible

```text
+-------------------------------------------------------------------------+
| Confirmation                                                            |
|-------------------------------------------------------------------------|
| Vous allez supprimer definitivement 12 elements.                        |
| Cette action ne pourra pas etre annulee.                                |
|                                                                         |
| (Annuler)                                  (Supprimer definitivement)   |
+-------------------------------------------------------------------------+
```

### 14.5 Rail droit - resultat apres application

```text
+--------------------------------------------------------------------------------------------------------------+
| SIDEBAR         | BIBLIOTHEQUE | 212 resultats | 12 selectionnes                                             |
|-----------------+--------------------------------------------------------------------------------------------|
|   A traiter     | LISTE                                             | DETAIL                              | SEL. |
| > Bibliotheque  |---------------------------------------------------+-------------------------------------+------|
|   A supprimer   | [x] item 1                                        | [Preview media]                     | 12   |
|   Activite      | [x] item 2                                        |-------------------------------------| elem |
|                 | [ ] item 3                                        | Nom / etat / tags / notes           |------|
|-----------------| [x] item 4                                        |                                     | Res. |
| Langue          |                                                   |                                     | 10   |
| Theme           |                                                   |                                     | modi.|
| Connexion       |                                                   |                                     | 2 err|
| Parametres      |                                                   |                                     |------|
| Compte          |                                                   |                                     | Voir |
|                 |                                                   |                                     | activ|
|                 |                                                   |                                     | ite  |
|                 |                                                   |                                     | Ferm.|
+--------------------------------------------------------------------------------------------------------------+
```

Notes UX :

- cet etat remplace temporairement le rail de preparation
- le detail complet des erreurs ou de l'historique appartient a `Activite`
- `Fermer` ramene le rail a l'etat neutre

## 15. Ordre de priorite pour le maquettage

1. Shell global
2. `A traiter`
3. `A traiter` avec selection multiple active
4. `Bibliotheque`
5. `A supprimer`
6. `Activite`
7. detail plein ecran
8. `Connexion`
9. `Reinitialiser le mot de passe`
10. `Verification e-mail`
11. `Parametres`
12. `Compte`
13. etats vides, erreurs, confirmations

## 16. Decision de design

Si l'equipe doit partir vite en maquette, il faut d'abord designer :

- un shell stable
- un pattern principal liste + detail + rail
- un vocabulaire UI simple
- des composants reutilisables pour les listes, les actions et les etats

Ces wireframes sont faits pour servir de base avant les maquettes haute fidelite.
