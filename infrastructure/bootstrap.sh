#!/bin/bash

################################################################################
# Script de Bootstrap - Configuración Completa desde Cero
#
# Este script configura un servidor Ubuntu desde cero con todo lo necesario
# para ejecutar el pipeline CI/CD
#
# Uso: curl -fsSL https://raw.githubusercontent.com/tu-repo/devops-pipeline/master/infrastructure/bootstrap.sh | bash
# O: bash infrastructure/bootstrap.sh
################################################################################

set -e  # Salir si hay errores

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Bootstrap - Configuración de Servidor desde Cero      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Función para logging
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar que se ejecuta en Ubuntu
if [ ! -f /etc/lsb-release ]; then
    log_error "Este script solo funciona en Ubuntu"
    exit 1
fi

log_info "Sistema operativo: $(lsb_release -d | cut -f2)"
log_info "Usuario actual: $(whoami)"

# Obtener directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

log_info "Directorio del proyecto: $PROJECT_ROOT"

# Variables de configuración
APP_USER="${APP_USER:-appuser}"
APP_DIR="${APP_DIR:-/opt/devops-pipeline}"
NODE_VERSION="${NODE_VERSION:-20}"

echo ""
log_info "Configuración:"
echo "  - Usuario de aplicación: $APP_USER"
echo "  - Directorio de aplicación: $APP_DIR"
echo "  - Versión de Node.js: $NODE_VERSION"
echo ""

read -p "¿Continuar con la instalación? (s/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    log_warn "Instalación cancelada"
    exit 0
fi

################################################################################
# 1. Actualizar sistema
################################################################################
log_info "Paso 1/8: Actualizando sistema..."
sudo apt-get update -qq
sudo apt-get upgrade -y -qq
log_info "✓ Sistema actualizado"

################################################################################
# 2. Instalar dependencias del sistema
################################################################################
log_info "Paso 2/8: Instalando dependencias del sistema..."
sudo apt-get install -y -qq \
    curl \
    wget \
    git \
    build-essential \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    ufw \
    fail2ban \
    htop \
    vim \
    unzip

log_info "✓ Dependencias instaladas"

################################################################################
# 3. Instalar Node.js
################################################################################
log_info "Paso 3/8: Instalando Node.js ${NODE_VERSION}..."

# Eliminar instalaciones antiguas
sudo apt-get remove -y nodejs npm 2>/dev/null || true

# Instalar desde NodeSource
curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verificar instalación
NODE_INSTALLED=$(node --version)
NPM_INSTALLED=$(npm --version)
log_info "✓ Node.js instalado: $NODE_INSTALLED"
log_info "✓ npm instalado: v$NPM_INSTALLED"

# Instalar PM2 globalmente
sudo npm install -g pm2
log_info "✓ PM2 instalado: $(pm2 --version)"

################################################################################
# 4. Instalar Docker
################################################################################
log_info "Paso 4/8: Instalando Docker..."

# Eliminar versiones antiguas
sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
rm get-docker.sh

# Añadir usuario actual a grupo docker
sudo usermod -aG docker $USER || true

# Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

DOCKER_VERSION=$(docker --version)
COMPOSE_VERSION=$(docker-compose --version)
log_info "✓ Docker instalado: $DOCKER_VERSION"
log_info "✓ Docker Compose instalado: $COMPOSE_VERSION"

################################################################################
# 5. Configurar usuario de aplicación
################################################################################
log_info "Paso 5/8: Configurando usuario de aplicación..."

# Crear usuario si no existe
if ! id "$APP_USER" &>/dev/null; then
    sudo useradd -m -s /bin/bash $APP_USER
    log_info "✓ Usuario $APP_USER creado"
else
    log_warn "Usuario $APP_USER ya existe"
fi

# Dar permisos de docker al usuario
sudo usermod -aG docker $APP_USER || true

################################################################################
# 6. Configurar directorio de aplicación
################################################################################
log_info "Paso 6/8: Configurando directorio de aplicación..."

sudo mkdir -p $APP_DIR
sudo chown -R $APP_USER:$APP_USER $APP_DIR

# Si estamos en el repo, copiar archivos
if [ -d "$PROJECT_ROOT/.git" ]; then
    log_info "Copiando archivos del proyecto..."
    sudo cp -r $PROJECT_ROOT/* $APP_DIR/
    sudo chown -R $APP_USER:$APP_USER $APP_DIR
    log_info "✓ Archivos copiados a $APP_DIR"
fi

################################################################################
# 7. Configurar firewall
################################################################################
log_info "Paso 7/8: Configurando firewall..."

sudo ufw --force enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 3000/tcp comment 'Node.js App'
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'

log_info "✓ Firewall configurado"

################################################################################
# 8. Configurar servicios
################################################################################
log_info "Paso 8/8: Configurando servicios systemd..."

# Ejecutar script de configuración de servicios
if [ -f "$SCRIPT_DIR/setup-services.sh" ]; then
    bash "$SCRIPT_DIR/setup-services.sh"
    log_info "✓ Servicios configurados"
else
    log_warn "Script setup-services.sh no encontrado, saltando configuración de servicios"
fi

################################################################################
# Finalización
################################################################################
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           Bootstrap Completado Exitosamente               ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
log_info "Resumen de instalación:"
echo "  ✓ Sistema actualizado"
echo "  ✓ Node.js $NODE_INSTALLED instalado"
echo "  ✓ Docker instalado"
echo "  ✓ PM2 instalado"
echo "  ✓ Usuario $APP_USER configurado"
echo "  ✓ Firewall configurado"
echo ""
log_warn "IMPORTANTE: Es necesario reiniciar la sesión para aplicar cambios de grupo docker"
log_info "Ejecuta: su - $USER  (o cierra y vuelve a abrir la terminal)"
echo ""
log_info "Próximos pasos:"
echo "  1. Ejecutar: cd $APP_DIR"
echo "  2. Ejecutar: bash infrastructure/deploy.sh"
echo ""
