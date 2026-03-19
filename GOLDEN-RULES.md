# Golden Rules

Ces règles sont la couche constitutionnelle du projet. Elles priment sur les choix locaux d'implémentation et servent de cadre d'arbitrage pour toutes les specs.

Elles ne sont pas toutes immédiatement simples à lire pour une personne non développeuse. C'est normal: elles condensent des choix d'architecture, de sécurité et d'exploitation. Elles doivent donc être à la fois courtes, opposables et suffisamment précises pour guider les implémentations. Quand une règle semble technique, il faut aussi la lire comme une règle produit: elle existe pour éviter des comportements ambigus, fragiles ou dangereux dans le système réel.

1. **Leak by design**  
   Le système doit être conçu en partant du principe qu’une fuite arrivera.
   En pratique: on ne construit jamais le projet en supposant que la base, les logs ou les métadonnées resteront invisibles pour toujours.

2. **Privacy by design**  
   La protection de la vie privée doit être intégrée dès la conception.
   En pratique: les données sensibles sont minimisées, cloisonnées, chiffrées et non exposées en clair par défaut.

3. **`retaia-docs` est la source de vérité unique du projet**  
   Le repo `retaia-docs` porte la norme cross-project.
   En pratique: si un repo local dit autre chose que `retaia-docs`, c'est `retaia-docs` qui gagne.

4. **Core est la source de vérité unique métier**  
   Toutes les décisions métier, états, transitions, policies, flags et règles vivent dans `Core`.
   En pratique: ni l'UI, ni l'agent, ni le NAS ne décident de leur côté de l'état métier réel.

5. **Le NAS n'est qu'un stockage**  
   Le `NAS` ne décide rien. Il stocke et déplace les fichiers sous le contrôle de `Core`.
   En pratique: le NAS sert à garder les fichiers, pas à porter la logique métier.

6. **L'API doit rester stateless et sessionless**  
   L’API ne doit dépendre d’aucune session serveur implicite.
   En pratique: pas de `SessionCookieAuth`, pas de session web cachée, pas d'état serveur implicite nécessaire pour comprendre une requête.

7. **Tout concept reconnu doit être implémenté avec une bibliothèque reconnue**  
   Lorsqu’un standard, un protocole ou un concept largement reconnu existe, son implémentation doit reposer sur une bibliothèque reconnue par consensus et maintenue.
   En pratique: on n'écrit pas d'OpenPGP maison, pas de WebAuthn maison, pas de parser ou protocole critique maison quand un standard sérieux existe déjà.

8. **Les identités humaines et techniques doivent rester séparées**  
   Un utilisateur humain, une UI interactive, un daemon technique ou un client MCP ne sont pas le même acteur.
   En pratique: un agent technique ne récupère jamais implicitement l'identité ou les droits d'un humain connecté.

9. **La vérité runtime doit toujours être relue dans `Core`; le push ne sert qu’à signaler un changement**  
   Les états, policies, feature flags et disponibilités fonctionnelles doivent être lus depuis `Core` via les endpoints contractuels.
   En pratique: un push, un websocket ou une notif dit "va relire", mais ne suffit jamais seul à établir la vérité métier.

10. **Les feature flags gouvernent le runtime**  
   Toute évolution progressive, incomplète ou non nominale doit être pilotée par des feature flags contrôlés par `Core`.
   En pratique: un client ne doit jamais supposer qu'une feature est disponible parce qu'elle existe dans le code.

11. **Le système doit être safe by default**  
   Sans preuve explicite qu’une action est autorisée, elle doit être refusée.
   En pratique: ce qui n'est pas clairement permis est bloqué par défaut.

12. **Toute action sensible doit être authentifiée, autorisée et auditée**  
   Rien d’important ne doit dépendre d’un implicite, d’un effet de bord ou d’un privilège hérité tacitement.
   En pratique: on doit toujours pouvoir répondre à trois questions: qui a fait l'action, pourquoi elle était autorisée, et où elle a été tracée.

13. **Le bulk appartient à l'UI; le Core reste unitaire**  
   Le traitement par lot est un concept d’interface.
   En pratique: l'UI peut sélectionner plusieurs assets, mais `Core` traite toujours des mutations asset par asset.

14. **Toute identité technique sensible doit être asymétrique**  
   Les clients techniques doivent reposer sur des identités asymétriques: clé publique enregistrée côté `Core`, clé privée locale côté client, signatures obligatoires sur les écritures sensibles.
   En pratique: l'identité d'un agent ou d'un MCP ne repose pas seulement sur un secret partagé; elle doit pouvoir être prouvée cryptographiquement.
