# Security Baseline — Assume Breach (Core/UI/Agent/MCP)

Ce document définit la baseline sécurité normative pour réduire l'impact d'une fuite.

Objectif: en cas d'exfiltration partielle (DB, logs, token, backup), les données volées restent inutiles ou de valeur fortement dégradée pour un attaquant.

## 1) Principes

* assume breach: le design DOIT considérer qu'une fuite finira par arriver
* deny by default
* least privilege (scope minimal, durée minimale)
* secret zero trust: aucun secret sensible ne DOIT être stocké ou transporté en clair sans justification explicite
* secure by default: sans preuve positive d'autorisation, refuser

## 2) Exigences transverses (MUST)

* toutes les communications runtime DOIVENT utiliser TLS
* tout secret applicatif DOIT être redigé des logs, traces et crash reports
* toutes les erreurs 4xx/5xx exposées aux clients DOIVENT rester compatibles `ErrorResponse` (pas de stacktrace, pas de secret)
* tous les tokens DOIVENT avoir `exp` borné et `jti` unique
* tout endpoint mutateur DOIT appliquer authn + authz explicite (acteur + scope + contrainte d'état)
* toute action de sécurité (login, logout, rotate-secret, revoke-token, create/revoke API key, 2FA enable/disable, approval device flow, `PATCH /app/features`, `POST /app/policy`) DOIT être auditée

## 3) Gestion des secrets et credentials (MUST)

* mot de passe utilisateur: hashé Argon2id (jamais stocké en clair)
* `secret_key` client `AGENT`: stockée hashée (jamais persistée en clair côté Core)
* API key `MCP`: stockée hashée (jamais persistée en clair côté Core)
* `secret_key` ou API key ne DOIT être affichée qu'une seule fois lors de l'émission/rotation
* rotation de `secret_key` ou révocation/rotation d'API key DOIT invalider immédiatement les accès techniques associés
* secrets de chiffrement serveur DOIVENT être gérés via KMS/HSM ou équivalent (pas en dur dans le code)

## 4) Tokens et sessions (MUST)

* architecture bearer-only (pas de `SessionCookieAuth`)
* token utilisateur: 1 token actif par `(user_id, client_id)`
* token technique: 1 token actif par `client_id`
* émission d'un nouveau token pour la même cardinalité => révocation immédiate de l'ancien
* JWT/claims minimales: `sub`, `principal_type`, `client_id`, `client_kind`, `scope`, `jti`, `exp`
* aucun PII sensible dans les claims token

## 5) Règles client UI (MUST)

* UI web (`UI_WEB`) DOIT utiliser login utilisateur (`POST /auth/login`)
* le token UI ne DOIT jamais être affiché/exporté en clair
* l'UI ne DOIT pas proposer l'auto-révocation du token actif UI (anti lock-out)
* stockage secret OS obligatoire:
  * macOS: Keychain
  * Windows: DPAPI/Credential Manager
  * Linux: Secret Service (ou store OS équivalent)
* 2FA TOTP optionnelle au niveau compte, mais si active elle DOIT être appliquée au login UI et aux approvals sensibles UI

## 6) Règles client Agent/MCP (MUST)

* `AGENT`:
  * mode interactif: login utilisateur (Bearer user)
  * mode technique: `client_id + secret_key -> POST /auth/clients/token`
* `MCP`: mode technique uniquement via API key bearer créée depuis l'UI
* création d'un `secret_key` `AGENT` DOIT passer par validation UI utilisateur (device flow)
* création d'une API key `MCP` DOIT passer par l'UI utilisateur
* si 2FA utilisateur est active, la validation UI de création `secret_key` ou d'API key DOIT exiger OTP
* secret/token/API key technique ne DOIT jamais être loggé

## 7) Données et exfiltration (MUST)

* minimisation: ne collecter et ne stocker que les données nécessaires au service
* chiffrement au repos pour données sensibles et backups
* standard crypto applicatif cross-client: GPG/OpenPGP selon [`GPG-OPENPGP-STANDARD.md`](GPG-OPENPGP-STANDARD.md)
* chiffrement applicatif (field-level/envelope) obligatoire pour adresse, GPS et transcription
* séparation logique des données opérationnelles et des secrets
* exports/dumps de prod DOIVENT être chiffrés et tracés
* données de debug en prod DOIVENT être minimisées et redigées

## 8) Contrôles anti-abus (MUST)

* rate limiting sur login, reset password, verify email, device flow agent, token mint agent et création d'API key UI
* protection brute-force sur auth (backoff/temporisation et blocage progressif)
* invalidation explicite en cas de credentials/tokens compromis
* détection minimale d'anomalies (tentatives répétées, volumes anormaux, patterns d'échec)

## 9) Contrôles recommandés (SHOULD)

* proof-of-possession (DPoP ou mTLS) pour tokens techniques
* chiffrement de colonnes sensibles (field-level) en plus du chiffrement disque
* rotation automatique périodique des secrets techniques
* alerte sécurité temps réel sur `rotate-secret`, `revoke-token`, échecs auth massifs, activation/désactivation 2FA

## 10) Critères d'acceptation sécurité (gates)

Une livraison est non conforme si au moins un point ci-dessous échoue:

* token/secrets observables en clair dans logs, UI ou telemetry
* endpoint mutateur sans authz explicite
* `SessionCookieAuth` réintroduit
* `secret_key` ou API key persistée en clair
* rotation secret sans invalidation des tokens actifs
* adresse/GPS/transcription lisible(s) en clair dans DB ou backup exfiltré

## Références associées

* [API-CONTRACTS.md](../api/API-CONTRACTS.md)
* [ERROR-MODEL.md](../api/ERROR-MODEL.md)
* [AUTHZ-MATRIX.md](AUTHZ-MATRIX.md)
* [GPG-OPENPGP-STANDARD.md](GPG-OPENPGP-STANDARD.md)
* [CRYPTO-SECURITY-MODEL.md](CRYPTO-SECURITY-MODEL.md)
* [RGPD-DATA-PROTECTION.md](RGPD-DATA-PROTECTION.md)
* [TEST-PLAN.md](../tests/TEST-PLAN.md)
