# Capabilities — Processing Agents

Ce document définit le **système de capabilities** utilisé pour décrire, planifier et orchestrer le travail des agents de processing dans le projet **Retaia**.

Ces règles sont **normatives**.


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

* `media.proxies.video@1`
* `media.thumbnails@1`
* `audio.waveform@1`
* `speech.transcription@1`

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

## Références associées

* [JOB-TYPES.md](JOB-TYPES.md)
* [AGENT-PROTOCOL.md](../workflows/AGENT-PROTOCOL.md)
* [API-CONTRACTS.md](../20-api/API-CONTRACTS.md)
