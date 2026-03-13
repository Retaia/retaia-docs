# Golden Rules

Ces règles sont la couche constitutionnelle du projet. Elles priment sur les choix locaux d'implémentation et servent de cadre d'arbitrage pour toutes les specs.

1. **Leak by design**  
   Le système doit être conçu en partant du principe qu’une fuite arrivera. Cette hypothèse n’est pas exceptionnelle; elle fait partie du modèle normal de sécurité.

2. **Privacy by design**  
   La protection de la vie privée doit être intégrée dès la conception. Les données sensibles doivent être minimisées, cloisonnées, chiffrées et non exposées en clair.

3. **`retaia-docs` est la source de vérité unique du projet**  
   Le repo `retaia-docs` porte la norme cross-project. Les contrats, règles métier, modèles de sécurité, workflows et conventions qui y sont définis priment sur les implémentations locales.

4. **Core est la source de vérité unique métier**  
   Toutes les décisions métier, états, transitions, policies, flags et règles vivent dans `Core`. Aucun autre composant ne peut devenir une source de vérité concurrente sur le plan fonctionnel.

5. **Le NAS n'est qu'un stockage**  
   Le `NAS` ne décide rien. Il stocke et déplace les fichiers sous le contrôle de `Core`.

6. **L'API est bearer-only**  
   L’API doit rester `bearer-only`. Les sessions serveur implicites, `SessionCookieAuth` et toute dépendance à un état web caché sont interdites.

7. **La cryptographie doit être standard, jamais maison**  
   Aucune primitive, protocole ou implémentation cryptographique locale ne doit être inventé. Seuls des standards reconnus et des bibliothèques maintenues sont autorisés.

8. **Les identités humaines et techniques doivent rester séparées**  
   Un utilisateur humain, une UI interactive, un daemon technique ou un client MCP ne sont pas le même acteur. Leurs identités, leurs droits et leurs modes d’authentification doivent rester distincts.

9. **Le polling porte la vérité runtime; le push ne porte que le signal**  
   Les états, policies, feature flags et disponibilités fonctionnelles doivent être lus depuis `Core` via les endpoints contractuels. Les mécanismes push ne servent qu’à notifier, réveiller ou améliorer l’UX.

10. **Les feature flags gouvernent le runtime**  
   Toute évolution progressive, incomplète ou non nominale doit être pilotée par des feature flags contrôlés par `Core`. Les clients ne doivent rien hardcoder.

11. **Le système doit être safe by default**  
   Sans preuve explicite qu’une action est autorisée, elle doit être refusée. Une feature absente vaut `false`. En cas de doute, le comportement conservateur l’emporte.

12. **Toute action sensible doit être authentifiée, autorisée et auditée**  
   Rien d’important ne doit dépendre d’un implicite, d’un effet de bord ou d’un privilège hérité tacitement.

13. **Le bulk appartient à l'UI; le Core reste unitaire**  
   Le traitement par lot est un concept d’interface. Côté `Core`, les mutations restent unitaires, asset par asset, avec des transitions et des règles explicites.

14. **Toute identité technique sensible doit être asymétrique**  
   Les clients techniques doivent reposer sur des identités asymétriques: clé publique enregistrée côté `Core`, clé privée locale côté client, signatures obligatoires sur les écritures sensibles.
