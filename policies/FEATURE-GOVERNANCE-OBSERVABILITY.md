# Feature Governance Observability (Normatif)

Ce document définit les traces minimales pour piloter `app_feature_enabled` et `user_feature_enabled`.

## 1) Audit events obligatoires

Events minimum :

* `app_feature_enabled.updated`
* `user_feature_enabled.updated`
* `feature_access.denied` (`FORBIDDEN_SCOPE`)
* `feature_effective.resolved`

Champs minimum :

* `event_name`
* `timestamp`
* `actor_type` (`ADMIN_INTERACTIVE|USER_INTERACTIVE|AGENT_TECHNICAL|MCP_TECHNICAL`)
* `actor_id`
* `feature_key`
* `old_value` / `new_value` (pour les updates)
* `reason_code` (ex: `ADMIN_DISABLED`, `USER_OPT_OUT`, `DEPENDENCY_OFF`, `CORE_PROTECTED`)
* `request_id` / `trace_id`

Règle de portée et pseudonymisation :

* dans les journaux d'audit protégés et les événements runtime internes, `actor_id` DOIT être l'identifiant brut canonique (`user_id`, `client_id` ou `agent_id`)
* dans toute exportation hors frontière de confiance prod et dans toute surface métrique low-cardinality, `actor_id` DOIT être remplacé par `actor_id_pseudonymized`
* `actor_id_pseudonymized` DOIT être calculé par `HMAC-SHA-256(secret_scope, actor_id)` puis tronqué aux `16` premiers octets hexadécimaux lowercase, préfixés par `psd_`
* le même `secret_scope` DOIT être utilisé à l'intérieur d'un même environnement pour conserver la corrélabilité, et DOIT être différent entre environnements

Reason codes canoniques `v1` :

* `FEATURE_FLAG_OFF`
* `ADMIN_DISABLED`
* `USER_OPT_OUT`
* `DEPENDENCY_OFF`
* `DISABLE_ESCALATION`
* `CORE_PROTECTED`
* `UNSUPPORTED_CONTRACT_VERSION`

Regles opposables :

* tout calcul `effective=OFF` DOIT pouvoir etre explique par exactement un `reason_code` primaire canonique
* `feature_effective.resolved` DOIT inclure `effective_value`
* `feature_effective.resolved` DOIT inclure `reason_code` quand `effective_value=false`
* si `reason_code=DEPENDENCY_OFF`, le payload DOIT inclure `dependency_key`
* si `reason_code=DISABLE_ESCALATION`, le payload DOIT inclure `parent_feature_key`

## 2) Metrics minimales

Compteurs obligatoires :

* `feature_toggle_admin_total{feature_key,value}`
* `feature_toggle_user_total{feature_key,value}`
* `feature_denied_total{feature_key,reason_code}`
* `feature_effective_off_total{feature_key,reason_code}`

Histogrammes minimum :

* `feature_resolution_duration_ms`

Couplage audit / métriques (obligatoire) :

* tout événement `app_feature_enabled.updated` accepté DOIT produire un audit event et incrémenter `feature_toggle_admin_total`
* tout événement `user_feature_enabled.updated` accepté DOIT produire un audit event et incrémenter `feature_toggle_user_total`
* tout refus `feature_access.denied` DOIT produire un audit event et incrémenter `feature_denied_total`
* tout calcul `feature_effective.resolved` avec `effective_value=false` DOIT produire un audit event, incrémenter `feature_effective_off_total` et observer `feature_resolution_duration_ms`

## 3) Alerting minimum

Seuils canoniques `v1` :

* alerte `feature.core_protected_spike` si `feature_denied_total{reason_code=\"CORE_PROTECTED\"}` augmente d'au moins `5` événements sur une fenêtre glissante de `5 minutes`
* alerte `feature.resolution_latency` si `p95(feature_resolution_duration_ms) > 250ms` sur `15 minutes`
* alerte `feature.critical_effective_off_spike` si `feature_effective_off_total` pour une clé classée critique augmente d'au moins `10` événements sur `10 minutes`

## 4) Confidentialité des logs

* pas de token/secret/PII en clair
* appliquer le standard [`SECURITY-BASELINE.md`](./SECURITY-BASELINE.md)
