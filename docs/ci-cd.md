# CI/CD — Pipeline conceptuel

Ce document décrit comment transposer ce TP dans une industrialisation réelle (GitHub Actions, GitLab CI, ou équivalent).

## Étapes du pipeline

1. **Lint** — Vérification du code (ESLint, Prettier côté frontend ; éventuellement lint Python/Node côté API).
2. **Test** — Exécution des tests dans une image éphémère (builder ou image dédiée), sans dépendre de l’environnement hôte.
3. **Build** — Construction des images Docker (multi-stage) avec tag basé sur le commit ou la version.
4. **Scan** — Analyse de vulnérabilités (Trivy/Grype) et éventuellement blocage si vulnérabilités critiques.
5. **Publish** — Push des images sur un registre (Docker Hub, registry privé, GitHub Container Registry) avec tags `:staging`, `:prod`, ou version sémantique.
6. **Déploiement** — Déploiement sur l’environnement cible (Compose ou Stack Swarm) selon l’environnement (staging/prod).

## Gestion des secrets

**Comment injecter les secrets en CI/CD (sans les committer) :**
- **En CI/CD** : ne jamais committer les secrets. Utiliser :
  - **GitHub Actions** : Secrets du dépôt (Settings → Secrets and variables → Actions).
  - **GitLab CI** : Variables protégées / Masked.
  - **Vault** : via script qui génère un fichier temporaire (ex. `ops/postgres_password`) ou des variables d’environnement, puis lance `docker compose` ou `docker stack deploy`.
- Le fichier `ops/dev.env` (et tout fichier contenant des mots de passe) doit être ignoré par Git (`.gitignore`).

## Promotion des images

- **Tagging** : utiliser des tags explicites pour la promotion :
  - `:latest` ou `:main` pour la branche principale ;
  - `:staging` pour la préproduction ;
  - `:1.0.0`, `:prod` pour la production.
- Le déploiement en production ne doit utiliser que des images déjà testées et scannées (pas de build direct sur le serveur de prod).

## Exemple GitHub Actions (résumé)

```yaml
- run: make test
- run: docker build -t $REGISTRY/todo-backend:$TAG ./backend
- run: make scan
- run: docker push $REGISTRY/todo-backend:$TAG
# Puis déploiement (SSH, kubectl, ou docker stack deploy selon l’infra)
```

Les secrets (`REGISTRY`, credentials, mots de passe) sont stockés dans les Secrets GitHub et injectés comme variables d’environnement.
