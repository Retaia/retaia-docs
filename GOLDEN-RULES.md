# Golden Rules

Ces règles sont le cadre supérieur du projet. Elles priment sur les choix locaux d'implémentation et servent de grille de lecture pour toutes les specs.

1. **Leak by design**  
   Le système doit être conçu en partant du principe qu’une fuite arrivera un jour. Base de données, logs, backups, métadonnées ou artefacts partiels peuvent être exposés. L’architecture doit rester sûre même dans ce scénario.

2. **Privacy by design**  
   La protection de la vie privée n’est pas une couche ajoutée après coup. Les données sensibles doivent être minimisées, cloisonnées, chiffrées et non exposées en clair, dès la conception.

3. **`retaia-docs` comme source de vérité unique pour tout le projet**  
   Le repo `retaia-docs` porte la norme cross-project. Les contrats, règles métier, modèles de sécurité, workflows et conventions qui y sont définis priment sur les implémentations locales des autres repos.

4. **Core comme source de vérité unique métier**  
   Toutes les décisions métier, états, transitions, policies, flags et règles vivent dans `Core`. Aucun autre composant ne doit devenir une source de vérité concurrente sur le plan fonctionnel.

5. **NAS comme stockage uniquement**  
   Le `NAS` ne décide rien. Il sert à stocker et à déplacer les fichiers sous le contrôle de `Core`. Il n’a pas d’autorité métier propre.

6. **API en mode bearer uniquement**  
   L’API doit rester `bearer-only`. Pas de session serveur classique, pas de `SessionCookieAuth`, pas de dépendance implicite à un état serveur de type session web.

7. **Aucune cryptographie maison**  
   Aucune primitive, protocole ou implémentation cryptographique ne doit être inventé localement. Si un standard existe, il doit être utilisé.

8. **Cryptographie standard uniquement**  
   Les mécanismes cryptographiques doivent s’appuyer sur des standards reconnus et sur des bibliothèques maintenues. Par exemple `WebAuthn` pour le web et `OpenPGP` pour les identités techniques signées.

9. **Séparation stricte des identités humaines et techniques**  
   Un utilisateur humain, une UI interactive, un daemon technique ou un client MCP ne sont pas le même acteur. Leurs identités, leurs droits et leurs modes d’authentification doivent rester distincts.

10. **Le polling comme vérité runtime**  
    La vérité runtime se lit en pollant `Core`. États, policies, feature flags et disponibilité fonctionnelle doivent être synchronisés par les endpoints contractuels.

11. **Le push n’est jamais une source de vérité**  
    WebSocket, SSE, webhook ou autres push peuvent servir à réveiller, notifier ou améliorer l’UX. Mais ils ne doivent jamais être traités comme l’état métier canonique.

12. **Les feature flags gouvernent le runtime**  
    Toute évolution progressive ou non encore nominale doit être gouvernée par des feature flags pilotés par `Core`. Les clients ne doivent rien hardcoder.

13. **Safe by default**  
    Sans preuve explicite qu’une action est autorisée, elle doit être refusée. Une feature absente vaut `false`. Un doute sur l’état ou l’autorisation doit conduire à un comportement conservateur.

14. **Authentification, autorisation et audit explicites**  
    Toute action sensible doit être authentifiée, autorisée et tracée. Rien d’important ne doit dépendre d’un implicite, d’un effet de bord ou d’un privilège hérité tacitement.

15. **Bulk dans l’UI, unitaire dans le Core**  
    Le traitement par lot est un concept d’interface. Côté `Core`, les mutations restent unitaires, asset par asset, avec des transitions et des règles explicites.

16. **Identité technique asymétrique**  
    Les clients techniques doivent reposer à terme sur des identités asymétriques: clé publique enregistrée côté `Core`, clé privée locale côté client, signatures obligatoires sur les écritures sensibles.

17. **Une fuite ne doit rien apprendre d’utile à l’attaquant**  
    C’est la conséquence opérationnelle des deux premières règles. Même si des données fuitent, elles ne doivent pas révéler d’informations exploitables sur les contenus protégés, les secrets longue durée ou l’architecture de sécurité.
