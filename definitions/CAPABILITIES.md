# Capabilities — Processing Agents

Ce document définit le **système de capabilities** utilisé pour décrire, planifier et orchestrer le travail des agents de processing dans le projet **Retaia**.

Ces règles sont **normatives**.

## 0. Distinction normative (capabilities vs feature flags)

* `capabilities` = capacités techniques déclarées par un client/agent (ce qu'il sait faire)
* `feature_flags` = activation fonctionnelle globale pilotée par Core (ce qui est autorisé maintenant)
* une capability n'active jamais une feature globale à elle seule
* une feature flag n'accorde jamais une capacité technique absente
* disponibilité effective d'une action = `capability requise` AND `feature_flag actif`


## 1. Définition

Une **capability** décrit une **fonction de traitement** qu’un agent est capable d’exécuter.

Une capability :

* décrit **ce que fait l’agent**, pas comment
* est **déclarative**, jamais implicite
* est **stable** et **versionnée**

Une capability n’est **pas** :

* une technologie (`ffmpeg`, `python`, `gpu`)
* une implémentation (`nvenc`, `cuda`, `libx264`)
* une optimisation interne


## 2. Format

Une capability est identifiée par :

```
<domaine>.<fonction>@<version>
```

Exemples valides :

* `media.facts@1`
* `media.proxies.video@1`
* `media.proxies.audio@1`
* `media.proxies.photo@1`
* `media.thumbnails@1`
* `audio.waveform@1`
* `speech.transcription@1` (**planned v1.1+**, AI-powered)
* `speech.transcription.local.whispercpp@1` (**planned v1.1+**, AI-powered)
* `meta.tags.suggestions@1` (**planned v1.1+**, AI-powered)
* `llm.client.ollama@1` (**planned v1.1+**, AI-powered)
* `llm.client.chatgpt@1` (**planned v1.1+**, AI-powered)
* `llm.client.claude@1` (**planned v1.1+**, AI-powered)

La version suit une logique **major only** :

* incrémentée uniquement en cas de rupture de contrat


## 3. Déclaration par un agent

Lors de son enregistrement, un agent **DOIT** déclarer explicitement :

* son identifiant
* sa plateforme (optionnel)
* la liste complète de ses capabilities

Un agent ne peut **jamais** exécuter un job pour lequel il n’a pas déclaré la capability requise.


## 4. Responsabilité

Déclarer une capability signifie que l’agent garantit :

* la production des outputs attendus
* le respect des invariants définis par le job
* l’absence d’effet de bord destructif

Un agent qui déclare une capability qu’il ne respecte pas est considéré comme **défaillant**.


## 5. Matching jobs ↔ agents

Chaque job déclare :

* un `job_type`
* une liste de `required_capabilities`

Le serveur peut assigner un job à un agent uniquement si :

```
agent.capabilities ⊇ job.required_capabilities
```

Le matching est **strict**. Il n’existe pas de fallback implicite.


## 6. Évolution des capabilities

* Ajouter une nouvelle capability est un **changement compatible**.
* Modifier le comportement d’une capability existante est un **changement structurel**.
* Supprimer une capability est interdit sans migration explicite.

Toute évolution de capability doit être documentée.


## 7. Anti‑patterns

Les pratiques suivantes sont interdites :

* déduire une capability depuis la configuration matérielle
* exécuter un job "presque compatible"
* surcharger une capability pour plusieurs fonctions
* créer des capabilities trop fines ou liées à une techno


## 8. Objectif

Le système de capabilities vise à :

* rendre le scheduling explicite
* permettre la cohabitation de versions d’agents
* éviter les décisions implicites côté serveur
* rendre le système extensible sans couplage fort

Toute implémentation qui court‑circuite ces objectifs est invalide.

## 9. Capabilities LLM minimales (planned v1.1+)

Pour tout agent qui déclare `meta.tags.suggestions@1` :

* le support `llm.client.ollama@1` est obligatoire (phase 1)
* `llm.client.chatgpt@1` et `llm.client.claude@1` sont activables en phase 2 via feature flags runtime
* la sélection du client LLM DOIT rester explicite (configuration/feature flag/runtime policy)
* un client LLM indisponible ne DOIT PAS casser le runtime agent global (fallback ou retry policy)

## 10. Transcription local-first (planned v1.1+)

Pour tout agent qui déclare `speech.transcription@1` :

* le mode local-first est obligatoire
* le support `speech.transcription.local.whispercpp@1` est obligatoire (minimum actuel)
* un backend distant de transcription PEUT exister, mais uniquement en opt-in explicite utilisateur/policy

## 11. Invalidation capability par inventaire modèle (planned v1.1+)

Pour les capabilities dépendantes d'un provider/modèle (`llm.*`, `speech.transcription.*`) :

* l'agent DOIT publier son inventaire provider/modèle disponible au runtime
* si le provider/modèle requis n'est pas disponible localement, la capability DOIT être invalidée
* si le provider/modèle est disponible localement mais non autorisé par Core policy, la capability DOIT être invalidée
* Core ne maintient pas de catalogue runtime de modèles; seul l'agent est source de vérité d'inventaire local
* l'agent PEUT supporter l'installation de modèle quand le provider local le permet

## Références associées

* [JOB-TYPES.md](JOB-TYPES.md)
* [AGENT-PROTOCOL.md](../workflows/AGENT-PROTOCOL.md)
* [API-CONTRACTS.md](../api/API-CONTRACTS.md)
