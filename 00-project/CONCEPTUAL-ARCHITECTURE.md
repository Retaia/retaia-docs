# Conceptual Architecture — Retaia Core & Retaia Agent

Ce document décrit l’**architecture conceptuelle** du système Rush.

Il définit les **rôles**, les **responsabilités** et les **frontières** entre les composants.
Il ne décrit **pas** les détails d’implémentation.

Ces règles sont **normatives**.


## 1) Objectifs

Le système Rush vise à :

* cataloguer et suivre le cycle de vie des médias (assets)
* orchestrer des traitements asynchrones via des agents **non fiables**
* préserver la décision humaine (KEEP / REJECT)
* éviter toute action destructive implicite
* rester robuste face aux pannes, au matériel hétérogène et au réseau


## 2) Principes structurants

* **Single Source of Truth** : le serveur est la source de vérité
* **Séparation des responsabilités** : inventaire ≠ processing ≠ décision
* **Asynchronisme assumé** : les jobs peuvent rester `pending` longtemps
* **Idempotence partout** : retries sûrs par design
* **Capabilities explicites** : aucun pouvoir implicite côté agent
* **Humain au centre** : aucune décision métier automatisée


## 3) Composants principaux

### 3.1 Retaia Core (Serveur)

Rôle : **orchestrateur central**.

Responsabilités :

* inventaire des assets (métadonnées, états)
* application de la machine à états
* création et suivi des jobs
* validation des résultats de processing
* exposition de l’API (UI, agents, clients)

Garanties :

* cohérence des états
* refus des transitions non autorisées
* aucun accès destructif délégué aux agents

Retaia Core **ne traite pas** les médias.


### 3.2 Retaia Agent (Agents de processing)

Rôle : **exécuteurs**.

Responsabilités :

* exécuter des jobs atomiques
* produire des facts, dérivés et suggestions
* uploader les dérivés via l’API

Contraintes :

* agents considérés comme **non fiables** (crash, reboot, réseau)
* aucun pouvoir de décision
* aucun accès en écriture au NAS ou au filesystem serveur
* aucune opération destructive

Un agent peut être :

* faible (ex: Raspberry Pi)
* puissant (workstation, serveur IA)

Les capacités réelles d’un agent sont décrites uniquement par ses **capabilities déclarées**.


### 3.3 NAS / Storage

Rôle : **stockage des originaux**.

Principes :

* les originaux ne sont jamais modifiés par les agents
* les agents accèdent aux sources en **lecture seule**
* les dérivés sont stockés séparément et sont recréables

Le NAS n’implémente aucune logique métier.


### 3.4 UI Web

Rôle : **interface humaine**.

Responsabilités :

* revue des médias (via proxies)
* décisions KEEP / REJECT
* déclenchement d’actions explicites (reprocess, batch moves, purge)

Contraintes :

* aucune décision automatique
* aucune action destructive implicite

La spécification UI est volontairement hors scope de ce document.


## 4) Flux principaux

### 4.1 Ingestion

1. Découverte d’un média
2. Enregistrement comme asset (`DISCOVERED → READY`)
3. Création des jobs de processing initiaux


### 4.2 Processing asynchrone

1. Création d’un job (`pending`)
2. Claim par un agent compatible
3. Exécution + upload des dérivés
4. Validation côté serveur
5. Mise à jour des états

Un job peut rester `pending` indéfiniment si aucun agent compatible n’est disponible.


### 4.3 Décision humaine

1. Asset en `DECISION_PENDING`
2. Revue via l’UI
3. Décision explicite KEEP / REJECT

Aucune automatisation ne peut produire cette décision.


### 4.4 Actions destructives

* batch moves
* purge

Principes :

* toujours explicites
* toujours confirmées
* jamais exécutées par un agent


## 5) Contrats et hiérarchie normative

Ordre de priorité :

1. STATE-MACHINE.md
2. JOB-TYPES.md
3. CAPABILITIES.md
4. AGENT-PROTOCOL.md
5. API-CONTRACTS.md
6. Implémentation

Si l’implémentation contredit un document de niveau supérieur,
elle est considérée comme invalide.


## 6) Anti-objectifs

Le système Rush **ne doit pas** :

* déplacer ou supprimer des fichiers sans validation humaine
* prendre des décisions de tri automatiquement
* dépendre d’un type de matériel unique
* masquer des états ou des erreurs
* "corriger" silencieusement une situation incohérente


## 7) Résumé

Rush est un système :

* orchestré par un serveur central
* exécuté par des agents interchangeables
* gouverné par des contrats explicites
* contrôlé par l’humain

Toute évolution doit renforcer ces principes, jamais les affaiblir.
