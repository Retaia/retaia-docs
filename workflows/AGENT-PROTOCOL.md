# Agent Protocol — Retaia Core ↔ Processing Agents

Ce document définit le **protocole opérationnel** entre le serveur Retaia Core et les agents de processing.

Ces règles sont **normatives**.


## 1. Objectif

Le protocole agent vise à :

* permettre la distribution de jobs à des agents **non fiables** (crash, réseau, reboot)
* garantir l’absence de jobs claimés bloqués indéfiniment (lease avec expiration)
* rendre les retries sûrs et prévisibles
* empêcher toute action destructive implicite

Portée d'exécution :

* seul un `AGENT_TECHNICAL` exécute les jobs de processing
* un client `MCP` peut piloter/orchestrer mais ne traite jamais les médias
* rollout projet global: le client applicatif `MCP` (mappé `client_kind=MCP`) est intégré à partir de la v1.1 globale
* gate applicatif: `app_feature_enabled.features.ai=false` désactive uniquement les fonctions `MCP` dépendantes de l'AI; le client `MCP` reste disponible pour ses fonctions non destructives non liées à l'AI
* un client `AGENT`/`MCP` DOIT appliquer `effective_feature_enabled` (pas de logique locale alternative)
* `AGENT_UI` est la surface locale de setup, contrôle et debug de l'agent
* `AGENT_UI` n'est pas une UI métier humaine complète autonome
* toute auth ou approval humaine liée à l'agent passe par ouverture du browser vers `UI_WEB`
* le daemon `AGENT_TECHNICAL` reste un acteur technique séparé, sans identité humaine implicite


## 2. Principes fondamentaux

* `Core` est la source de vérité métier (jobs, états, décisions) et orchestre les moves sur le NAS.
* L’agent est un exécuteur : il ne prend **jamais** de décision métier.
* Les jobs sont **idempotents**.
* Tout claim est **atomique**.
* Le pilotage runtime est status-driven par polling HTTP: l'agent lit l'état Core par polling.
* Un canal push serveur-vers-agent/client peut exister pour réveiller/alerter/diffuser des infos (WebSocket, SSE, webhook, autres push).
* Ces push sont autorisés, mais ne sont jamais la source de vérité métier.

### 2.1 Polling runtime (normatif)

* Les boucles de polling (`GET /jobs`, device flow poll, policy refresh) DOIVENT respecter les intervalles contractuels renvoyés par Core.
* En cas de `429` (`SLOW_DOWN`/`TOO_MANY_ATTEMPTS`), l'agent DOIT appliquer un backoff avec jitter.
* Le refresh des flags/policy DOIT être périodique; l'agent NE DOIT PAS attendre un signal push pour appliquer un changement de vérité métier.
* Les actions mutatrices (claim/submit/fail) ne partent qu'après lecture d'un état compatible via polling.


## 3. Enregistrement d’un agent

### 3.1 Register

Un agent DOIT s’enregistrer avant de pouvoir claim des jobs.

Champs minimum :

* `agent_id`
* `agent_name`
* `agent_version`
* `capabilities[]`
* `os_name`
* `os_version`
* `arch`

Le serveur peut refuser l’enregistrement si la déclaration est invalide.

Règle d'identité d'instance :

* l'agent DOIT générer un `agent_id` stable lors de sa première initialisation
* cet `agent_id` DOIT être un `UUIDv4` aléatoire
* cet identifiant DOIT être persisté localement puis réutilisé à chaque register
* `client_id` identifie le client technique autorisé; plusieurs instances d'agent peuvent le partager
* `agent_id` sert au suivi d'une instance réelle d'agent, indépendamment du `client_id`
* un éventuel identifiant interne de persistance côté Core est hors contrat agent et ne DOIT pas être exposé
* l'agent NE DOIT PAS dériver `agent_id` de l'environnement machine (hostname, MAC, serial, `machine-id`, etc.)
* si deux agents actifs partagent le même `agent_id`, Core autorise le register mais DOIT signaler un conflit d'identité en diagnostics ops
* l'agent DOIT générer une identité de clé `OpenPGP` lors de sa première initialisation
* la clé privée DOIT être persistée localement dans le secret store ou le stockage applicatif protégé de l'agent
* la clé privée NE DOIT JAMAIS quitter l'agent
* la rotation de clé DOIT être explicite

Preuve cryptographique d'instance :

* `agent_id` reste l'identifiant public stable et lisible pour les usages ops
* la clé `OpenPGP` fournit la preuve cryptographique que la requête émane bien de cette instance d'agent
* `POST /agents/register` DOIT déclarer la clé publique OpenPGP active (`openpgp_public_key`) et son `openpgp_fingerprint`
* `POST /agents/register` DOIT aussi être signé avec la clé privée correspondante pour prouver la possession de la clé
* toutes les écritures agent -> Core DOIVENT ensuite être signées avec cette même clé active jusqu'à rotation explicite

Headers de signature agent (obligatoires sur les écritures agent -> Core) :

* `X-Retaia-Agent-Id`
* `X-Retaia-OpenPGP-Fingerprint`
* `X-Retaia-Signature`
* `X-Retaia-Signature-Timestamp`
* `X-Retaia-Signature-Nonce`

Chaîne canonique à signer :

* méthode HTTP
* path HTTP exact
* `agent_id`
* timestamp de signature
* nonce
* SHA-256 hexadécimal du body HTTP brut

Règles de vérification côté Core :

* la signature DOIT être une signature **OpenPGP détachée** conforme au standard [`GPG-OPENPGP-STANDARD.md`](../policies/GPG-OPENPGP-STANDARD.md)
* `X-Retaia-Agent-Id` DOIT correspondre au `agent_id` du bearer technique
* `X-Retaia-OpenPGP-Fingerprint` DOIT correspondre à la clé publique active enregistrée pour cet agent
* Core DOIT vérifier la fraîcheur de `X-Retaia-Signature-Timestamp` dans une fenêtre bornée
* Core DOIT empêcher le rejeu via `X-Retaia-Signature-Nonce`
* Core DOIT rejeter toute requête si la signature est absente, invalide, expirée, rejouée ou si la clé est révoquée/inconnue
* Core DOIT journaliser les échecs de vérification de signature comme événements sécurité
* agent et Core DOIVENT utiliser des librairies OpenPGP standard maintenues; aucune implémentation crypto maison n'est autorisée

### 3.2 Profils d’exécution (normatif)

* l’agent DOIT fournir `AGENT_UI` en mode `CLI` (obligatoire)
* l’agent DOIT fournir `AGENT_UI` en mode `GUI` (obligatoire)
* la `GUI` DOIT offrir les mêmes fonctionnalités opérateur que la `CLI`
* la `CLI` DOIT réciproquement offrir les mêmes fonctionnalités opérateur que la `GUI`
* les deux surfaces DOIVENT déléguer le processing au même moteur (mêmes capacités, mêmes règles)
* le pilotage du daemon (start/stop/status/configuration locale) fait partie du périmètre propre de `AGENT_UI`
* `AGENT_UI` NE DOIT PAS dériver vers une UI métier complète concurrente de `UI_WEB`

Support plateforme minimal attendu :

* Linux headless (Raspberry Pi cible Kodi/Plex) via `CLI` obligatoire; la `GUI` peut être indisponible sur cette cible sans remettre en cause l'obligation produit globale
* macOS (laptop) via `CLI` et `GUI`
* Windows (desktop) via `CLI` et/ou `GUI`

Contrainte d’implémentation :

* la stack agent DOIT être implémentée en Rust pour la portabilité binaire cross-platform et le service mode.

### 3.2.1 Baseline implémentation (normatif)

Pour éviter le code local à maintenir, cette règle s'applique à toute implémentation (quel que soit le langage) :

* pour une préoccupation transverse (parsing CLI, sérialisation, erreurs typées, notification OS, retry/backoff, etc.), une librairie dédiée et maintenue DOIT être utilisée
* l'implémentation locale d'une préoccupation transverse est interdite tant qu'une librairie maintenue existe
* si l'implémentation est en Rust, baseline attendue: `clap` (CLI), `thiserror` (erreurs typées), `tauri-plugin-notification` (notifications GUI Tauri)

### 3.3 Modes d’auth agent (normatif)

* mode non-interactif (service/daemon): `client_id + secret_key -> POST /auth/clients/token` après approval humain via `UI_WEB`
* `AGENT_UI` est une surface locale de setup/contrôle/debug; il NE DOIT PAS implémenter de login humain direct
* `AGENT_UI` DOIT ouvrir le browser vers `UI_WEB` pour toute authentification ou approval humaine liée au daemon
* `UI_WEB` reste la seule UI autorisée à porter l'identité humaine (`login + bearer + refresh`)
* un agent non-interactif NE DOIT PAS dépendre d’un login UI pour redémarrer
* le bearer utilisateur appartient exclusivement à `UI_WEB`; il NE DOIT JAMAIS être exposé ni réutilisé par `AGENT_UI` ou `AGENT_TECHNICAL`
* le daemon `AGENT_TECHNICAL` agit toujours sous sa propre identité technique (`agent_id` + clé OpenPGP + auth technique), jamais au nom implicite de l'utilisateur connecté dans `UI_WEB`
* `client_id + secret_key` autorise le client technique et permet de mint le bearer technique; une écriture mutatrice agent NE DOIT JAMAIS être acceptée sur cette seule base sans preuve `agent_id + OpenPGP + signature`
* `AGENT_TECHNICAL` N'UTILISE JAMAIS `WebAuthn` au runtime

Extension future user-scoped (réservée) :

* si une action user-scoped liée au daemon doit exister plus tard, elle DOIT passer par un contrat de délégation explicite séparé
* une telle délégation DOIT être approuvée par un utilisateur authentifié dans `UI_WEB`, bornée dans le temps, liée à un `agent_id` précis et limitée à des scopes nommément listés
* en l'absence d'un tel contrat, `AGENT_UI` reste limité au setup/contrôle/debug local et ne porte aucune action user-scoped autonome

Feature flags runtime :

* l’agent DOIT consommer les `feature_flags` renvoyés par Core via `GET /app/policy` (canal runtime canonique)
* `POST /agents/register` PEUT transporter un snapshot initial de compatibilité, mais NE DOIT PAS remplacer le refresh périodique via `GET /app/policy`
* l’agent NE DOIT PAS hardcoder l’état des flags
* un changement runtime de flag DOIT être appliqué sans rebuild agent
* `feature_flags` ne remplacent pas les `capabilities` déclarées de l'agent
* une action agent n'est valide que si capability requise + flag(s) actif(s)

Secrets :

* `secret_key` ne DOIT jamais être loggée
* stockage secret DOIT utiliser le magasin sécurisé OS (Linux Secret Service/file perms stricts, macOS Keychain, Windows Credential Manager/DPAPI)
* rotation `POST /auth/clients/{client_id}/rotate-secret` DOIT être supportée sans réinstallation complète

### 3.4 Clients LLM minimum (validé en v1.1+; activable plus tôt sous `feature_flags`)

Pour les workloads AI `suggest_tags` (`meta.tags.suggestions@1`), validés en v1.1+ et activables plus tôt sous `feature_flags`, l'agent DOIT supporter au minimum :

* `ollama`
* `chatgpt` (phase 2, sous flag)
* `claude` (phase 2, sous flag)

Règles :

* sélection provider explicite via config/runtime policy (pas de hardcode implicite)
* indisponibilité d'un provider requis => échec explicite (retryable si policy le permet), ou mode dégradé seulement si une auto-réparation explicite est active
* comportement déterministe du routing provider pour une même policy d'exécution
* inventaire provider/modèle DOIT être publié par l'agent (pas de liste statique embarquée côté UI/Core)
* modèle effectif DOIT provenir d'un choix utilisateur explicite (CLI/GUI/config utilisateur)
* en mode non-interactif, le modèle choisi par l'utilisateur DOIT rester traçable et réutilisable jusqu'à changement explicite
* phase rollout: `ollama` activé en premier; `chatgpt` et `claude` activés uniquement derrière feature flags runtime
* si le provider/modèle requis n'est pas trouvé localement, l'agent DOIT invalider les capabilities associées
* si le provider/modèle local est hors policy Core, l'agent DOIT invalider les capabilities associées
* si le provider est géré localement, l'agent PEUT supporter l'installation de modèle

### 3.5 Local-first AI/transcription (validé en v1.1+; activable plus tôt sous `feature_flags`)

Pour `AGENT` et `MCP` :

* exécution local-first obligatoire pour les workloads AI/transcription quand un modèle local compatible est disponible
* transcription locale minimum supportée: `Whisper.cpp`
* usage d'un backend distant autorisé uniquement en opt-in explicite utilisateur/policy
* le mode distant ne DOIT pas devenir le défaut implicite
* la qualité de résultat prime sur la performance par défaut (latence/coût secondaires)


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

### 4.3.1 Résolution des paths source (normatif)

Pour tout job de processing claimé, l'agent reçoit un locator source:

* `source.storage_id`
* `source.original_relative`
* `source.sidecars_relative[]`

Configuration agent obligatoire:

* l’agent DOIT exposer une configuration locale `storage_mounts` (map `storage_id -> absolute_local_mount_path`)
* pour chaque mount `storage_mounts[*]`, l’agent DOIT lire et valider le marker `/.retaia`
* le marker `/.retaia` DOIT être considéré comme la référence locale canonique pour `paths.inbox`, `paths.archive`, `paths.rejects`
* le marker `/.retaia` est créé et maintenu exclusivement par Retaia Core (au boot et lors des updates applicatifs); l’agent NE DOIT JAMAIS le créer, l’éditer ou le réparer
* `source.storage_id` DOIT matcher strictement `/.retaia.storage_id`; sinon l’agent DOIT échouer explicitement
* la résolution du fichier source DOIT se faire par concaténation contrôlée:
  * `absolute_input_path = storage_mounts[source.storage_id] + "/" + source.original_relative`
* `source.*` DOIT rester relatif et ne DOIT PAS contenir `..`, de chemin absolu, ni de null byte
* `/.retaia.paths.*` DOIT rester relatif et ne DOIT PAS contenir `..`, de chemin absolu, ni de null byte
* en cas de mapping absent/invalide, l’agent DOIT échouer explicitement (erreur claire, pas de fallback implicite)
* en cas de marker absent/invalide/incohérent, l’agent DOIT échouer explicitement (erreur claire, pas de fallback implicite)


### 4.4 Heartbeat

Un agent qui a claim un job DOIT envoyer des heartbeats réguliers.

Le heartbeat :

* confirme que l’agent est vivant
* prolonge la lease
* DOIT être signé avec la clé privée active de l'agent

Si aucun heartbeat n’est reçu avant `lease_expires_at`, le job redevient claimable.


### 4.5 Completion

Quand le travail est terminé, l’agent soumet un résultat.

Le résultat DOIT inclure :

* `lock_token`
* `job_type`
* `result` (patch par domaine, selon le `job_type`)
* `warnings[]` / `metrics` (optionnels)
* une signature **OpenPGP détachée** valide sur la requête HTTP

Règle waveform audio (v1) :

* la génération serveur/agent de `waveform` est obligatoire pour les profils audio qui exigent `generate_audio_waveform`
* si aucun dérivé `waveform` n’est produit pour un profil audio qui l'exige, le résultat est non conforme
* le fallback UI local reste utile en dégradation de lecture, mais NE REMPLACE PAS l’obligation de production côté processing

Le serveur :

* valide le résultat
* enregistre les outputs
* marque le job comme `completed` ou `failed`


## 5. Idempotence

Les endpoints de completion DOIVENT être idempotents.

* un retry de `complete` ne doit pas créer de doublons
* un job déjà `completed` doit renvoyer un succès stable
* un retry avec un nonce de signature déjà utilisé DOIT être rejeté comme rejeu, même si la signature est cryptographiquement valide


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
* le bearer technique autorise le client agent, mais ne constitue pas à lui seul une preuve d'instance suffisante; les écritures agent -> Core DOIVENT être protégées par signature OpenPGP standard


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
* client `MCP` qui claim/heartbeat/submit un job de processing


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
