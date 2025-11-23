# Makefile para DevOps Pipeline
# Simplifica comandos comunes de infraestructura

.PHONY: help bootstrap install test build deploy start stop restart logs clean

# Variables
APP_DIR ?= /opt/devops-pipeline
BRANCH ?= master
DEPLOY_METHOD ?= pm2

help: ## Mostrar esta ayuda
	@echo "╔════════════════════════════════════════════════════════════╗"
	@echo "║         DevOps Pipeline - Comandos Disponibles             ║"
	@echo "╚════════════════════════════════════════════════════════════╝"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""

bootstrap: ## Configurar servidor desde cero (requiere Ubuntu)
	@echo "Iniciando bootstrap del servidor..."
	bash infrastructure/bootstrap.sh

install: ## Instalar dependencias del proyecto
	@echo "Instalando dependencias..."
	bash infrastructure/install-dependencies.sh

test: ## Ejecutar tests
	@echo "Ejecutando tests..."
	npm test

test-coverage: ## Ejecutar tests con cobertura
	@echo "Ejecutando tests con cobertura..."
	npm test -- --coverage

lint: ## Ejecutar linter
	@echo "Ejecutando linter..."
	npm run lint

build: ## Compilar proyecto
	@echo "Compilando proyecto..."
	npm run build

deploy: ## Desplegar aplicación
	@echo "Desplegando aplicación..."
	bash infrastructure/deploy.sh

deploy-quick: ## Deployment rápido (sin tests)
	@echo "Deployment rápido..."
	SKIP_TESTS=true bash infrastructure/deploy.sh

start: ## Iniciar aplicación (desarrollo)
	@echo "Iniciando aplicación..."
	npm start

start-pm2: ## Iniciar con PM2
	@echo "Iniciando con PM2..."
	pm2 start ecosystem.config.js

start-docker: ## Iniciar con Docker
	@echo "Iniciando con Docker..."
	docker-compose up -d

stop: ## Detener aplicación
	@echo "Deteniendo aplicación..."
	pm2 stop devops-pipeline || true
	docker-compose down || true

restart: ## Reiniciar aplicación
	@echo "Reiniciando aplicación..."
	pm2 restart devops-pipeline || npm start

logs: ## Ver logs de la aplicación
	@echo "Mostrando logs..."
	pm2 logs devops-pipeline --lines 100

logs-follow: ## Seguir logs en tiempo real
	@echo "Siguiendo logs..."
	pm2 logs devops-pipeline

status: ## Ver estado de la aplicación
	@echo "Estado de la aplicación:"
	pm2 status || docker-compose ps || systemctl status devops-pipeline

clean: ## Limpiar archivos temporales
	@echo "Limpiando archivos temporales..."
	rm -rf node_modules
	rm -rf coverage
	rm -rf logs/*.log
	rm -rf *.log

setup-webhook: ## Configurar servidor de webhooks para auto-deploy
	@echo "Configurando webhooks..."
	bash infrastructure/webhook-server.sh

health-check: ## Verificar salud de la aplicación
	@echo "Verificando health check..."
	@curl -f http://localhost:3000/health && echo "✓ Aplicación funcionando" || echo "✗ Aplicación no responde"

docker-build: ## Construir imagen Docker
	@echo "Construyendo imagen Docker..."
	docker build -t devops-pipeline .

docker-run: ## Ejecutar contenedor Docker
	@echo "Ejecutando contenedor Docker..."
	docker run -p 3000:3000 devops-pipeline

docker-compose-up: ## Iniciar con docker-compose
	docker-compose up -d

docker-compose-down: ## Detener docker-compose
	docker-compose down

docker-compose-logs: ## Ver logs de docker-compose
	docker-compose logs -f

# Comandos de utilidad
install-dev: ## Instalar dependencias de desarrollo
	npm install

update-deps: ## Actualizar dependencias
	npm update
	npm audit fix

security-audit: ## Auditoría de seguridad
	npm audit

check-outdated: ## Verificar paquetes desactualizados
	npm outdated

# Comandos de git
git-status: ## Ver estado de git
	git status

git-pull: ## Actualizar desde remoto
	git pull origin $(BRANCH)

git-push: ## Subir cambios
	git push origin $(BRANCH)

# Desarrollo local
dev: ## Iniciar en modo desarrollo con watch
	npm run dev || nodemon src/index.js

dev-debug: ## Iniciar en modo debug
	node --inspect src/index.js
