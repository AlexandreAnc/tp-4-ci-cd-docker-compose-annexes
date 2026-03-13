.PHONY: help up down logs ps test scan stats events

help:
	@echo "TP 4 — CI/CD Docker Compose & Swarm"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  help   - Affiche cette aide (défaut)"
	@echo "  up     - Démarre la stack Compose (build inclus)"
	@echo "  down   - Arrête les conteneurs et supprime les orphelins"
	@echo "  logs   - Affiche les logs avec timestamps (mode suivi)"
	@echo "  ps     - État des services Compose"
	@echo "  test   - Lance les tests backend dans un conteneur"
	@echo "  scan   - Scan Trivy des images + génération SBOM dans reports/"
	@echo "  stats  - docker stats (utilisation ressources)"
	@echo "  events - docker events des 10 dernières minutes"

up:
	docker compose up --build

down:
	docker compose down --remove-orphans

logs:
	docker compose logs -f --timestamps

ps:
	docker compose ps

test:
	docker build -t todo-backend:test --target builder ./backend
	docker run --rm todo-backend:test npm test

scan:
	trivy image --format table --output reports/todo-backend-trivy.txt todo-backend:latest
	trivy image --format cyclonedx --output reports/todo-backend-bom.json todo-backend:latest
	trivy image --format table --output reports/todo-frontend-trivy.txt todo-frontend:latest
	trivy image --format cyclonedx --output reports/todo-frontend-bom.json todo-frontend:latest

stats:
	docker stats

events:
	docker events --since 10m