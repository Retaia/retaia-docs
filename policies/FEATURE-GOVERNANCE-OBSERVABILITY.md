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
* `actor_type` (`ADMIN_INTERACTIVE|USER_INTERACTIVE|CLIENT_TECHNICAL|AGENT_TECHNICAL`)
* `actor_id` (ou pseudonymisé si nécessaire)
* `feature_key`
* `old_value` / `new_value` (pour les updates)
* `reason_code` (ex: `ADMIN_DISABLED`, `USER_OPT_OUT`, `DEPENDENCY_OFF`, `CORE_PROTECTED`)
* `request_id` / `trace_id`

## 2) Metrics minimales

Compteurs obligatoires :

* `feature_toggle_admin_total{feature_key,value}`
* `feature_toggle_user_total{feature_key,value}`
* `feature_denied_total{feature_key,reason_code}`
* `feature_effective_off_total{feature_key,reason_code}`

Histogrammes minimum :

* `feature_resolution_duration_ms`

## 3) Alerting minimum

* alerte si `feature_denied_total{reason_code=\"CORE_PROTECTED\"}` augmente brutalement
* alerte si `feature_resolution_duration_ms` dépasse le budget cible
* alerte si `feature_effective_off_total` sur une feature critique augmente de façon anormale

## 4) Confidentialité des logs

* pas de token/secret/PII en clair
* appliquer le standard [`SECURITY-BASELINE.md`](./SECURITY-BASELINE.md)
