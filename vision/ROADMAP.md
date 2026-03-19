# ROADMAP — Retaia

Cette roadmap liste les évolutions produit prévues, exploratoires ou explicitement non planifiées au-delà du scope de release courant.

Règles :

* ce document n’est pas un contrat runtime
* il ne remplace pas les specs normatives
* toute évolution retenue DOIT ensuite être traduite dans les contrats, politiques et workflows concernés
* un item peut être retiré de la roadmap même s’il existe encore dans des documents de préparation technique ; dans ce cas, la roadmap fait foi pour la priorité produit


## Principes

Toute évolution future DOIT respecter :

* review preview-first
* décision humaine explicite
* aucune action destructive implicite
* comportements stables et lisibles
* pas de bricolage frontend pour masquer un manque de support produit ou technique


## Prévu

### 1. V1.1 — Extension MCP et fonctions AI

Objectif :

* étendre le scope produit au client MCP et aux fonctionnalités dépendantes de l'AI

Contenu prévu :

* `MCP`
* transcription audio
* suggestions de tags
* inventaire runtime providers/modèles
* continuité du modèle runtime status-driven déjà cadré dans les specs

Notes :

* le MCP reste un client d’orchestration ; il ne traite pas les médias directement
* `AGENT_UI` couvre les surfaces CLI et GUI avec parité fonctionnelle obligatoire
* cette étape correspond à un élargissement du produit livré, pas à un changement de philosophie


### 2. V1 — Release initiale

Objectif :

* livrer le socle produit exploitable sans dépendance aux fonctionnalités AI

Contenu prévu :

* `Core`
* API v1
* `UI_WEB`
* `Agent`, incluant `AGENT_UI` en CLI et GUI
* processing review non-AI, décisions humaines, moves, purge, recherche full-text v1

Contraintes produit :

* aucune IA ne prend de décision KEEP / REJECT
* les enrichissements dépendants de l'AI restent hors conformité v1
* `AGENT_UI` fait partie de la release initiale et n'est pas un scope différé


## Exploratoire

### 3. Aperçu vidéo au survol de la timeline

Objectif :

* afficher une vignette correspondant au timecode survolé dans la timeline vidéo, de type YouTube

Statut :

* envisagé pour une version suivante de Retaia
* hors release actuelle

Pourquoi ce n’est pas retenu immédiatement :

* une solution reposant seulement sur le preview vidéo actuelle côté frontend serait trop fragile
* le résultat dépendrait trop des codecs, GOP, performances client et conditions de seeking
* cette interaction doit être rapide, stable et cohérente sur l’ensemble du produit

Exigences minimales avant implémentation :

* support media pipeline ou backend pour des thumbnails de timeline fiables
* contrat API ou métadonnées dédiées pour exposer ces aperçus
* comportement cohérent dans `A traiter`, `Bibliothèque` et le détail standalone
* fallback explicite si les aperçus de timeline ne sont pas disponibles
* accessibilité couverte pour souris, clavier et lecteurs d’écran

Non-objectif :

* ne pas implémenter cette fonctionnalité comme une astuce purement frontend sur le lecteur preview actuel


## Non Planifié

### 4. UI mobile et push mobile

Statut :

* non planifié à ce stade

Décision produit actuelle :

* pas de client mobile Android/iOS dans la roadmap active
* pas de push mobile dans la roadmap active

Impact :

* cette piste ne fait partie d'aucun engagement produit actif ni d'aucune gate normative courante
* si ce sujet redevient prioritaire plus tard, il devra être réintroduit explicitement dans cette roadmap avant relance du chantier


## À Revoir Plus Tard

### 5. Purge multi-sélection UI

Statut :

* possible plus tard
* non prioritaire

Cadre :

* la purge reste unitaire côté Core
* une éventuelle multi-sélection resterait un comportement UI, sans ressource batch dédiée
