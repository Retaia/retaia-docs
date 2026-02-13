# Feature Flag Lifecycle (Normatif)

Objectif: supprimer la dette technique des flags sans casser les clients UI/Agent/MCP.

## 1) Règles de base

* un feature flag est temporaire par défaut
* une feature stabilisée DOIT être assimilée au mainline
* après assimilation, le flag DOIT être retiré (runtime + code conditionnel + tests/doc transitoires)
* exception autorisée: kill-switch sécurité/opérations avec owner explicite

## 2) Versionnement/acceptance obligatoire

Le Core DOIT implémenter un contrat de compatibilité de flags:

* client -> Core: `client_feature_flags_contract_version`
  * `GET /app/policy` (query)
  * `POST /agents/register` (body, optionnel)
* Core -> client:
  * `feature_flags_contract_version` (latest)
  * `accepted_feature_flags_contract_versions[]`
  * `effective_feature_flags_contract_version`
  * `feature_flags_compatibility_mode` (`STRICT|COMPAT`)

Règles:

* si la version client est acceptée mais non-latest, Core DOIT répondre en mode `COMPAT`
* mode `COMPAT` NE DOIT PAS casser les clients existants
* un flag retiré du mainline DOIT rester servi en tombstone `false` tant qu'une version acceptée peut encore le lire
* un client qui ne transmet pas de version DOIT recevoir un profil non cassant

## 3) Assimilation au mainline

Préconditions avant retrait définitif d'un flag:

* observabilité montre l'absence de clients dépendants d'une version ancienne
* période de compatibilité minimale écoulée
* tests `STRICT` et `COMPAT` verts

Action de retrait:

* supprimer le flag de la version latest
* conserver tombstone `false` dans les profils `COMPAT` encore acceptés
* retirer tombstone une fois la fenêtre d'acceptance fermée

## 4) Gates PR obligatoires

Une PR qui retire un flag DOIT inclure:

* mise à jour OpenAPI/contrats (`ServerPolicy` versions + mode compat)
* mise à jour tests UI/Agent/MCP (non-régression en `COMPAT`)
* note d'impact consommateurs (`core/ui/agent/mcp`)
* plan de cutover et date de fin d'acceptance

## 5) Continuous development (obligatoire)

* les équipes DOIVENT pouvoir livrer en continu sans freeze client
* toute évolution de flag DOIT rester non cassante pour les versions clientes acceptées
* l'enchaînement "introduire -> activer -> assimiler -> retirer" DOIT être répétable à chaque itération
* le mode `COMPAT` est un mécanisme de continuous development, pas un legacy permanent

## 6) Continuous deployment (obligatoire)

* chaque déploiement Core DOIT être éligible à production sans migration client immédiate
* un retrait de flag n'est déployable que si les profils `COMPAT` requis sont servis
* la pipeline CD DOIT bloquer un retrait de flag si la fenêtre d'acceptance n'est pas satisfaite
* la rollback strategy DOIT préserver la négociation de version des flags
