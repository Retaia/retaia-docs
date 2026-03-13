# Agent Docs

Documentation fonctionnelle cross-project pour le client `retaia-agent`.

Statut:

* non normatif
* complete `workflows/AGENT-PROTOCOL.md`
* ne remplace pas les choix d'implementation locaux de `retaia-agent`

Contenu:

* [DAEMON-OPERATIONS.md](DAEMON-OPERATIONS.md)
* [CONFIGURATION-UX.md](CONFIGURATION-UX.md)
* [NOTIFICATIONS-UX.md](NOTIFICATIONS-UX.md)
* [DESKTOP-SHELL.md](DESKTOP-SHELL.md)

Regle:

* les comportements operateur, parcours GUI/CLI et attentes fonctionnelles vivent ici
* les choix Rust/Tauri/OpenAPI, stores locaux, fichiers, libs et scripts restent dans `retaia-agent`
