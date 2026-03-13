# Auth Incident Runbook

Runbook fonctionnel de diagnostic et traitement des incidents lies a l'authentification.

Statut:

* non normatif
* aligne sur les contrats API et politiques securite

## 1) Objectif

Fournir une procedure unique pour:

* identifier rapidement la classe d'incident auth
* distinguer erreur utilisateur, throttling, token invalide et probleme de policy
* escalader proprement sans fuite de secret

## 2) Signaux principaux

Codes API courants:

* `401 UNAUTHORIZED`
* `403 EMAIL_NOT_VERIFIED`
* `429 TOO_MANY_ATTEMPTS`
* `400 INVALID_TOKEN`
* `422 VALIDATION_FAILED`

Evenements d'observabilite pertinents:

* `auth.login.failure`
* `auth.login.success`
* `auth.login.throttled`
* `auth.password_reset.*`
* `auth.email_verification.*`
* `authz.denied`

## 3) Verification rapide

1. verifier la sante API generale
2. verifier la policy/runtime effective si un feature flag ou une policy peut bloquer le flux
3. corriger la fenetre temporelle avec les evenements d'observabilite
4. verifier l'etat metier de l'utilisateur:
   * email verifie ou non
   * verrouillage ou throttling
   * validite/expiration du token concerne

## 4) Procedures standard

### Utilisateur non verifie

1. confirmer que l'erreur retournee est `EMAIL_NOT_VERIFIED`
2. relancer le flux de verification d'email
3. utiliser une confirmation admin uniquement selon les regles d'exploitation autorisees
4. verifier ensuite un login normal

### Trop de `429`

1. confirmer le pattern de throttling
2. distinguer tentative abusive, client boucleur ou erreur operateur
3. ne pas desserrer une policy de throttling hors circuit de changement valide

### `INVALID_TOKEN` recurrent

1. verifier expiration TTL et horodatages
2. verifier alteration/encodage du token cote client
3. distinguer environnement de test et environnement reel

## 5) Escalade

Escalader si:

* indisponibilite auth persistante > 30 minutes
* suspicion de brute force ou de compromission
* incoherence entre policy attendue et runtime effectif

Livrables minimum:

* horodatage UTC
* endpoint concerne
* code de reponse
* correlation_id/request_id
* extrait de log structure sans secret

## References associees

* [../api/API-CONTRACTS.md](../api/API-CONTRACTS.md)
* [../api/OBSERVABILITY-CONTRACT.md](../api/OBSERVABILITY-CONTRACT.md)
* [../policies/INCIDENT-RESPONSE.md](../policies/INCIDENT-RESPONSE.md)
* [../policies/SECURITY-BASELINE.md](../policies/SECURITY-BASELINE.md)
