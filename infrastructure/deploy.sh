#!/bin/bash

################################################################################
# Script de Deployment Automatizado
#
# Despliega la aplicación desde GitHub y la ejecuta
################################################################################

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           Deployment Automatizado - CI/CD                  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Variables de configuración
APP_DIR="${APP_DIR:-/opt/devops-pipeline}"
REPO_URL="${REPO_URL:-https://github.com/sntramirez/devops-pipeline.git}"
BRANCH="${BRANCH:-master}"
APP_USER="${APP_USER:-appuser}"
DEPLOY_METHOD="${DEPLOY_METHOD:-pm2}"  # pm2, systemd, docker

log_info "Configuración de deployment:"
echo "  - Directorio: $APP_DIR"
echo "  - Repositorio: $REPO_URL"
echo "  - Rama: $BRANCH"
echo "  - Usuario: $APP_USER"
echo "  - Método: $DEPLOY_METHOD"
echo ""

################################################################################
# Verificar prerrequisitos
################################################################################
log_info "Verificando prerrequisitos..."

if ! command -v git &> /dev/null; then
    log_error "Git no está instalado. Ejecuta bootstrap.sh primero."
    exit 1
fi

if ! command -v node &> /dev/null; then
    log_error "Node.js no está instalado. Ejecuta bootstrap.sh primero."
    exit 1
fi

log_info "✓ Prerrequisitos verificados"

################################################################################
# Función para clonar o actualizar repositorio
################################################################################
deploy_from_git() {
    log_info "Paso 1/6: Obteniendo código desde Git..."

    if [ -d "$APP_DIR/.git" ]; then
        log_info "Repositorio existente, actualizando..."
        cd "$APP_DIR"
        git fetch origin
        git checkout $BRANCH
        git pull origin $BRANCH
        log_info "✓ Repositorio actualizado"
    else
        log_info "Clonando repositorio..."
        sudo rm -rf "$APP_DIR"
        sudo mkdir -p "$APP_DIR"
        git clone -b $BRANCH $REPO_URL $APP_DIR
        sudo chown -R $APP_USER:$APP_USER $APP_DIR
        log_info "✓ Repositorio clonado"
    fi

    cd "$APP_DIR"
    CURRENT_COMMIT=$(git rev-parse --short HEAD)
    log_info "Commit actual: $CURRENT_COMMIT"
}

################################################################################
# Función para instalar dependencias
################################################################################
install_dependencies() {
    log_info "Paso 2/6: Instalando dependencias..."

    cd "$APP_DIR"

    # Backup de node_modules si existe
    if [ -d "node_modules" ]; then
        log_info "Creando backup de node_modules..."
        mv node_modules node_modules.backup 2>/dev/null || true
    fi

    # Instalar dependencias
    if [ -f "infrastructure/install-dependencies.sh" ]; then
        bash infrastructure/install-dependencies.sh
    else
        npm ci --production
    fi

    # Limpiar backup si la instalación fue exitosa
    rm -rf node_modules.backup 2>/dev/null || true

    log_info "✓ Dependencias instaladas"
}

################################################################################
# Función para ejecutar tests
################################################################################
run_tests() {
    log_info "Paso 3/6: Ejecutando tests..."

    cd "$APP_DIR"

    if [ "${SKIP_TESTS}" = "true" ]; then
        log_warn "Tests omitidos (SKIP_TESTS=true)"
        return
    fi

    # Instalar dependencias de desarrollo si es necesario
    if [ ! -d "node_modules/jest" ]; then
        log_info "Instalando dependencias de desarrollo para tests..."
        npm install --only=dev
    fi

    # Ejecutar tests
    if npm test; then
        log_info "✓ Tests pasaron correctamente"
    else
        log_error "Tests fallaron"
        read -p "¿Continuar con el deployment? (s/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Ss]$ ]]; then
            log_error "Deployment cancelado"
            exit 1
        fi
    fi
}

################################################################################
# Función para build
################################################################################
run_build() {
    log_info "Paso 4/6: Ejecutando build..."

    cd "$APP_DIR"
    npm run build

    log_info "✓ Build completado"
}

################################################################################
# Función para detener aplicación
################################################################################
stop_application() {
    log_info "Paso 5/6: Deteniendo aplicación anterior..."

    case $DEPLOY_METHOD in
        pm2)
            if command -v pm2 &> /dev/null; then
                pm2 stop devops-pipeline 2>/dev/null || true
                pm2 delete devops-pipeline 2>/dev/null || true
                log_info "✓ PM2 detenido"
            fi
            ;;
        systemd)
            sudo systemctl stop devops-pipeline 2>/dev/null || true
            log_info "✓ Servicio systemd detenido"
            ;;
        docker)
            docker-compose down 2>/dev/null || true
            log_info "✓ Contenedores Docker detenidos"
            ;;
    esac
}

################################################################################
# Función para iniciar aplicación
################################################################################
start_application() {
    log_info "Paso 6/6: Iniciando aplicación..."

    cd "$APP_DIR"

    case $DEPLOY_METHOD in
        pm2)
            if command -v pm2 &> /dev/null; then
                if [ -f "ecosystem.config.js" ]; then
                    pm2 start ecosystem.config.js
                else
                    pm2 start src/index.js --name devops-pipeline
                fi
                pm2 save
                log_info "✓ Aplicación iniciada con PM2"
                pm2 status
            else
                log_error "PM2 no está instalado"
                exit 1
            fi
            ;;
        systemd)
            sudo systemctl start devops-pipeline
            sudo systemctl enable devops-pipeline
            log_info "✓ Servicio systemd iniciado"
            sudo systemctl status devops-pipeline --no-pager
            ;;
        docker)
            docker-compose up -d --build
            log_info "✓ Contenedores Docker iniciados"
            docker-compose ps
            ;;
    esac
}

################################################################################
# Función para health check
################################################################################
health_check() {
    log_info "Ejecutando health check..."

    sleep 3

    MAX_ATTEMPTS=10
    ATTEMPT=1

    while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
        if curl -f http://localhost:3000/health &>/dev/null; then
            log_info "✓ Health check exitoso"
            return 0
        fi

        log_warn "Intento $ATTEMPT/$MAX_ATTEMPTS fallido, esperando..."
        sleep 2
        ATTEMPT=$((ATTEMPT + 1))
    done

    log_error "Health check falló después de $MAX_ATTEMPTS intentos"
    return 1
}

################################################################################
# Ejecutar deployment
################################################################################
main() {
    deploy_from_git
    install_dependencies
    run_tests
    run_build
    stop_application
    start_application

    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         Deployment Completado Exitosamente                 ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    if health_check; then
        log_info "Aplicación desplegada y funcionando en http://localhost:3000"
    else
        log_warn "Aplicación desplegada pero health check falló"
    fi

    echo ""
    log_info "Comandos útiles:"
    echo "  - Ver logs (PM2): pm2 logs devops-pipeline"
    echo "  - Ver logs (systemd): sudo journalctl -u devops-pipeline -f"
    echo "  - Ver logs (Docker): docker-compose logs -f"
    echo "  - Reiniciar: bash infrastructure/deploy.sh"
    echo ""
}

# Ejecutar
main
