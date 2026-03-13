# Rapports — TP 4 CI/CD Docker Compose

## Architecture de la stack

- **Frontend** : Nginx (Alpine) servant les fichiers statiques (build multi-stage : builder Alpine + runtime Nginx).
- **Backend** : Node.js (Express) exposant l’API REST, connecté à MongoDB.
- **MongoDB** : Base de données NoSQL pour la persistance des messages.
- **Mongo Express** : Interface d’administration web pour MongoDB (optionnel en dev).

En mode **Docker Swarm**, seuls backend et frontend sont déployés en tant que services (images tirées du registre). La base MongoDB peut être gérée séparément ou intégrée selon l’environnement.

## Taille des images avant/après multi-stage

Tailles mesurées avec `docker images` :

| Image    | Single-stage (avant)      | Multi-stage (après)       |
|----------|---------------------------|----------------------------|
| Backend  | 233MB (todo-backend:single)   | 210MB (todo-backend:latest)  |
| Frontend | 75.9MB (todo-frontend:single) | 75.9MB (todo-frontend:latest) |

**Conclusion** : le multi-stage réduit la taille de l'image backend (233MB → 210MB) et donc la surface d'attaque. Pour le frontend, le gain est neutre dans cette configuration (même base Nginx et même contenu), ce qui montre que l'intérêt du multi-stage dépend aussi de la complexité de l'étape de build.

## Résultats du scan de vulnérabilités (Trivy)

- **todo-backend** : rapport texte `todo-backend-trivy.txt`, & `todo-backend-bom.json`.
- **todo-frontend** : rapport texte `todo-frontend-trivy.txt` & `todo-frontend-bom.json`.

Actions possibles sur les vulnérabilités détectées :
- **Mise à jour de l’image de base** (ex. Alpine, Node) pour intégrer les correctifs.
- **Pinning des versions** des dépendances (package.json, etc.) pour limiter les régressions.
- **Exclusion justifiée** : si une CVE ne s’applique pas au contexte d’usage, documenter l’exclusion dans la config Trivy.

## Procédure de mise en production

1. Build des images : `docker compose build` ou `make up` (build inclus).
2. Tests : `make test`.
3. Scan : `make scan` (génère les rapports dans `reports/`).
4. Tag et push vers le registre :  
   `docker tag todo-backend:latest $REGISTRY/todo-backend:1.0.0` puis `docker push ...`
5. Déploiement Swarm : `docker stack deploy -c compose.swarm.yml todo`
6. Vérification : `docker service ls`, `docker service ps todo_backend`, santé des réplicas.

## Export des commandes clés

Voir le **Makefile** à la racine : `make help`, `make up`, `make down`, `make logs`, `make ps`, `make test`, `make scan`, `make stats`, `make events`.

Les captures d’écran (interface front, Mongo Express, `docker compose ps`, `docker service ls`, test de kill) sont dans le README principal à la fin du document.

## Situation de diagnostic (observabilité)

**Exemple : API indisponible.** Pour diagnostiquer :
1. **Healthcheck** : `docker compose ps` ou `docker service ps todo_backend` indique si le conteneur est healthy / unhealthy.
2. **Logs** : `make logs` ou `docker compose logs backend` pour voir les erreurs (connexion MongoDB, crash, etc.).
3. **Métriques / événements** : `make stats` (utilisation CPU/RAM des conteneurs), `make events` (`docker events --since 10m`) pour voir les démarrages, arrêts et échecs de healthcheck.
4. En Swarm, un réplica en échec est recréé automatiquement ; les logs et events permettent d'identifier la cause (ex. image manquante, secret invalide).
