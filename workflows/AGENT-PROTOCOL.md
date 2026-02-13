# Agent Protocol — Retaia Core ↔ Processing Agents

Ce document définit le **protocole opérationnel** entre le serveur Retaia Core et les agents de processing.

Ces règles sont **normatives**.


## 1. Objectif

Le protocole agent vise à :

* permettre la distribution de jobs à des agents **non fiables** (crash, réseau, reboot)
* garantir l’absence de jobs claimés bloqués indéfiniment (lease avec expiration)
* rendre les retries sûrs et prévisibles
* empêcher toute action destructive implicite


## 2. Principes fondamentaux

* Le serveur est la **source de vérité** (jobs, états, décisions).
* L’agent est un exécuteur : il ne prend **jamais** de décision métier.
* Les jobs sont **idempotents**.
* Tout claim est **atomique**.


## 3. Enregistrement d’un agent

### 3.1 Register

Un agent DOIT s’enregistrer avant de pouvoir claim des jobs.

Champs minimum :

* `agent_name`
* `agent_version`
* `capabilities[]`
* `platform` (optionnel)

Le serveur peut refuser l’enregistrement si la déclaration est invalide.

### 3.2 Profils d’exécution (normatif)

* l’agent DOIT fournir un mode `CLI` (obligatoire)
* l’agent PEUT fournir un mode `GUI` (optionnel)
* le mode `GUI` DOIT déléguer le processing au même moteur que `CLI` (mêmes capacités, mêmes règles)

Support plateforme minimal attendu :

* Linux headless (Raspberry Pi cible Kodi/Plex) via `CLI` uniquement
* macOS (laptop) via `CLI` et/ou `GUI`
* Windows (desktop) via `CLI` et/ou `GUI`

Contrainte d’implémentation :

* la stack agent DOIT être implémentée en Rust pour la portabilité binaire cross-platform et le service mode.

### 3.3 Modes d’auth agent (normatif)

* mode non-interactif (service/daemon): `client_id + secret_key -> POST /auth/clients/token` ou OAuth2 client-credentials
* mode interactif opéré par un humain (CLI/GUI): login utilisateur via `POST /auth/login` (+ 2FA si active)
* un agent non-interactif NE DOIT PAS dépendre d’un login UI pour redémarrer

Feature flags runtime :

* l’agent DOIT consommer les `feature_flags` renvoyés par Core (au minimum via `POST /agents/register`)
* l’agent NE DOIT PAS hardcoder l’état des flags
* un changement runtime de flag DOIT être appliqué sans rebuild agent

Secrets :

* `secret_key` ne DOIT jamais être loggée
* stockage secret DOIT utiliser le magasin sécurisé OS (Linux Secret Service/file perms stricts, macOS Keychain, Windows Credential Manager/DPAPI)
* rotation `POST /auth/clients/{client_id}/rotate-secret` DOIT être supportée sans réinstallation complète

### 3.4 Clients LLM minimum (normatif)

Pour les workloads AI `suggest_tags` (`meta.tags.suggestions@1`), l'agent DOIT supporter au minimum :

* `ollama`
* `chatgpt`
* `anthropic`

Règles :

* sélection provider explicite via config/runtime policy (pas de hardcode implicite)
* indisponibilité d'un provider => fallback vers un provider disponible ou retryable (pas de crash global agent)
* comportement déterministe du routing provider pour une même policy d'exécution


## 4. Cycle de vie d’un job

### 4.1 Découverte

L’agent récupère la liste des jobs claimables via `GET /jobs`.

Le serveur ne renvoie que :

* des jobs en statut `pending`
* compatibles avec les `capabilities` déclarées par l’agent

Le serveur peut limiter la liste (pagination, quotas).

### 4.2 Jobs pending longue durée

Un job peut rester en statut `pending` pendant une durée indéterminée si
aucun agent enregistré ne déclare les capabilities requises.

Ce comportement est normal et attendu.

Un job `pending` n’est ni en erreur, ni bloqué, ni abandonné.


### 4.3 Claim (lease)

L’agent claim un job de manière atomique via `POST /jobs/{job_id}/claim`.

Le claim crée une **lease** (verrou temporaire) :

* `claimed_by = agent_id`
* `claimed_at`
* `lease_expires_at`

Si le job est déjà claim, le serveur DOIT refuser.


### 4.4 Heartbeat

Un agent qui a claim un job DOIT envoyer des heartbeats réguliers.

Le heartbeat :

* confirme que l’agent est vivant
* prolonge la lease

Si aucun heartbeat n’est reçu avant `lease_expires_at`, le job redevient claimable.


### 4.5 Completion

Quand le travail est terminé, l’agent soumet un résultat.

Le résultat DOIT inclure :

* `lock_token`
* `job_type`
* `result` (patch par domaine, selon le `job_type`)
* `warnings[]` / `metrics` (optionnels)

Le serveur :

* valide le résultat
* enregistre les outputs
* marque le job comme `completed` ou `failed`


## 5. Idempotence

Les endpoints de completion DOIVENT être idempotents.

* un retry de `complete` ne doit pas créer de doublons
* un job déjà `completed` doit renvoyer un succès stable


## 6. Retry policy

Le serveur décide si un job :

* est retryable
* doit passer en `failed`

L’agent ne décide jamais de la stratégie globale de retry.


## 7. Timeouts et TTL

* Les valeurs de lease/TTL doivent être explicites (configuration côté serveur).
* Toute modification des TTL/lock/retry est un changement structurel.


## 8. Sécurité

* Les agents n’ont accès qu’aux endpoints nécessaires.
* Les actions destructives (purge, move) ne sont jamais exposées aux agents.
* le mode `GUI` ne DOIT PAS exposer ni exporter les tokens en clair.


## 9. Observabilité

L’agent DOIT produire :

* logs structurés
* un identifiant de corrélation par job (`job_id`)

Le serveur DOIT enregistrer :

* l’historique de claim
* les échecs et raisons


## 10. Anti-patterns

Interdit :

* claim non atomique
* lease sans expiration
* retry infini côté agent
* job complété sans outputs documentés
* agent qui modifie des fichiers source


## 11. Objectif

Ce protocole existe pour rendre le système :

* robuste
* prévisible
* débogable
* extensible

Toute implémentation qui contourne ce protocole est invalide.

## Références associées

* [WORKFLOWS.md](WORKFLOWS.md)
* [JOB-TYPES.md](../definitions/JOB-TYPES.md)
* [CAPABILITIES.md](../definitions/CAPABILITIES.md)
* [API-CONTRACTS.md](../api/API-CONTRACTS.md)
