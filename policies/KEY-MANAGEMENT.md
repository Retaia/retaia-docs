# Key Management — JWT/KMS/Secrets

Ce document definit la gestion normative des cles cryptographiques et des secrets critiques.

## 1) Portee

* cles de signature des tokens utilisateur JWT
* cles de chiffrement donnees applicatives (KMS/HSM)
* cles OpenPGP pour payloads et donnees sensibles
* secrets runtime sensibles utilises par Core

## 2) Exigences MUST

* toute cle DOIT avoir un identifiant de version (`kid`) unique
* toute emission de token JWT DOIT inclure un `kid` resolvable
* les cles privees de signature ne DOIVENT jamais etre exportees en clair hors du gestionnaire de secrets
* toute cle DOIT avoir un owner, une date de creation et une date de rotation cible
* toute rotation de cle DOIT etre journalisee et auditee

## 3) Rotation standard

* JWT signing keys (tokens utilisateur): rotation reguliere planifiee (max 90 jours)
* cles de chiffrement de donnees: rotation planifiee (max 180 jours) ou selon exigences legales
* secret applicatif critique: rotation immediate en cas de suspicion de fuite

Procedure minimale de rotation JWT utilisateur:

1. generer nouvelle cle et publier son `kid`
2. signer les nouveaux tokens avec la nouvelle cle
3. conserver verification lecture des anciens tokens pendant fenetre de grace bornee
4. revoquer et retirer ancienne cle apres expiration de fenetre

## 4) Compromission (emergency rotation)

En cas de compromission suspectee/averee:

1. declarer incident securite
2. geler emission avec cle compromise
3. basculer sur nouvelle cle (`kid` nouveau)
4. invalider tokens emis avec cle compromise (liste `jti` ou policy par `kid`)
5. declencher communication incident et postmortem

## 5) JWKS et verification

* endpoint JWKS (ou equivalent interne) DOIT exposer uniquement les cles publiques actives des tokens utilisateur JWT
* verifier `alg`, `kid`, `exp`, `jti`, `scope`, `principal_type`, `client_id`
* algorithmes faibles/interdits DOIVENT etre refuses
* ces exigences `JWKS` / `kid` / verification JWT ne s'appliquent pas aux bearers techniques opaques
* l'endpoint `JWKS` (ou equivalent interne) ne fait pas partie de la surface publique REST partagee `v1`; il reste un mecanisme de verification interne/Core

## 5.b) Durees de vie normatives des tokens

* `UserBearerAuth.access_token` : `15 minutes`
* `UI_WEB.refresh_token` : `30 jours`
* `TechnicalBearerAuth.access_token` (`AGENT`/`MCP`) : `24 heures`
* ces durees sont fermees pour `v1`; toute modification requiert une revision de spec

## 6) Controle d'acces aux cles

* acces lecture/ecriture aux cles limite au Core et roles securite autorises
* toute action d'administration cle DOIT etre tracee
* separation des roles: emission cle, deploiement, approbation

## 7) Tests obligatoires

* token signe avec `kid` inconnu => rejet
* token signe avec cle retiree => rejet
* rotation JWT sans downtime verification
* invalidation effective des tokens lors emergency rotation
* audit event present pour create/rotate/revoke de cle
* rotation OpenPGP sans perte de decryptabilite autorisee

## References associees

* [SECURITY-BASELINE.md](SECURITY-BASELINE.md)
* [THREAT-MODEL.md](THREAT-MODEL.md)
* [GPG-OPENPGP-STANDARD.md](GPG-OPENPGP-STANDARD.md)
* [API-CONTRACTS.md](../api/API-CONTRACTS.md)
