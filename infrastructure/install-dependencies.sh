#!/bin/bash

################################################################################
# Script de Instalación de Dependencias
#
# Instala todas las dependencias necesarias para el proyecto
################################################################################

set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Obtener directorio del proyecto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

log_info "Instalando dependencias en: $PROJECT_ROOT"

################################################################################
# Verificar Node.js y npm
################################################################################
if ! command -v node &> /dev/null; then
    log_warn "Node.js no está instalado. Ejecuta bootstrap.sh primero."
    exit 1
fi

if ! command -v npm &> /dev/null; then
    log_warn "npm no está instalado. Ejecuta bootstrap.sh primero."
    exit 1
fi

log_info "Node.js: $(node --version)"
log_info "npm: $(npm --version)"

################################################################################
# Limpiar instalaciones previas
################################################################################
log_info "Limpiando instalaciones previas..."
rm -rf node_modules package-lock.json 2>/dev/null || true

################################################################################
# Instalar dependencias de producción
################################################################################
log_info "Instalando dependencias de producción..."
npm ci --production

################################################################################
# Instalar dependencias de desarrollo (si no es producción)
################################################################################
if [ "${NODE_ENV}" != "production" ]; then
    log_info "Instalando dependencias de desarrollo..."
    npm ci
fi

################################################################################
# Verificar instalación
################################################################################
log_info "Verificando instalación..."

EXPECTED_DEPS="express"
for dep in $EXPECTED_DEPS; do
    if npm list $dep &> /dev/null; then
        log_info "✓ $dep instalado"
    else
        log_warn "✗ $dep NO instalado"
    fi
done

log_info "✓ Dependencias instaladas correctamente"

################################################################################
# Audit de seguridad
################################################################################
log_info "Ejecutando audit de seguridad..."
npm audit --production || log_warn "Se encontraron vulnerabilidades. Revisa con: npm audit"

log_info "Instalación completada"
