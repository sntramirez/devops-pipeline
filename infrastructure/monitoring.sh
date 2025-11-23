#!/bin/bash

################################################################################
# Script de Monitoreo y Alertas
#
# Monitorea el estado de la aplicación y servicios
################################################################################

set -e

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

################################################################################
# Verificar salud de la aplicación
################################################################################
check_app_health() {
    log_info "Verificando salud de la aplicación..."

    if curl -f http://localhost:3000/health &>/dev/null; then
        log_info "✓ Aplicación respondiendo correctamente"
        return 0
    else
        log_error "✗ Aplicación no responde"
        return 1
    fi
}

################################################################################
# Verificar uso de CPU
################################################################################
check_cpu_usage() {
    log_info "Verificando uso de CPU..."

    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    CPU_INT=${CPU_USAGE%.*}

    if [ "$CPU_INT" -gt 80 ]; then
        log_warn "Uso de CPU alto: ${CPU_USAGE}%"
    else
        log_info "✓ Uso de CPU: ${CPU_USAGE}%"
    fi
}

################################################################################
# Verificar uso de memoria
################################################################################
check_memory_usage() {
    log_info "Verificando uso de memoria..."

    MEM_USAGE=$(free | grep Mem | awk '{print ($3/$2) * 100.0}')
    MEM_INT=${MEM_USAGE%.*}

    if [ "$MEM_INT" -gt 80 ]; then
        log_warn "Uso de memoria alto: ${MEM_USAGE}%"
    else
        log_info "✓ Uso de memoria: ${MEM_USAGE}%"
    fi
}

################################################################################
# Verificar espacio en disco
################################################################################
check_disk_usage() {
    log_info "Verificando espacio en disco..."

    DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')

    if [ "$DISK_USAGE" -gt 80 ]; then
        log_warn "Espacio en disco bajo: ${DISK_USAGE}%"
    else
        log_info "✓ Espacio en disco: ${DISK_USAGE}%"
    fi
}

################################################################################
# Verificar servicios
################################################################################
check_services() {
    log_info "Verificando servicios..."

    # PM2
    if command -v pm2 &> /dev/null; then
        if pm2 list | grep -q "devops-pipeline"; then
            log_info "✓ PM2 ejecutando"
        else
            log_warn "✗ PM2 no ejecutando devops-pipeline"
        fi
    fi

    # Docker
    if command -v docker &> /dev/null; then
        if docker ps | grep -q "devops-pipeline"; then
            log_info "✓ Docker ejecutando"
        fi
    fi

    # Systemd
    if systemctl is-active --quiet devops-pipeline; then
        log_info "✓ Servicio systemd activo"
    fi
}

################################################################################
# Verificar logs de errores
################################################################################
check_error_logs() {
    log_info "Verificando logs de errores..."

    LOG_DIR="/opt/devops-pipeline/logs"

    if [ -d "$LOG_DIR" ]; then
        ERROR_COUNT=$(grep -i "error" $LOG_DIR/*.log 2>/dev/null | wc -l || echo "0")

        if [ "$ERROR_COUNT" -gt 10 ]; then
            log_warn "Errores encontrados en logs: $ERROR_COUNT"
        else
            log_info "✓ Errores en logs: $ERROR_COUNT"
        fi
    fi
}

################################################################################
# Generar reporte
################################################################################
generate_report() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║           Reporte de Monitoreo - $(date +'%Y-%m-%d %H:%M:%S')      ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    check_app_health
    check_cpu_usage
    check_memory_usage
    check_disk_usage
    check_services
    check_error_logs

    echo ""
    log_info "Monitoreo completado"
}

################################################################################
# Ejecutar monitoreo continuo
################################################################################
monitor_continuous() {
    log_info "Iniciando monitoreo continuo (Ctrl+C para detener)..."

    while true; do
        clear
        generate_report
        sleep 60
    done
}

################################################################################
# Main
################################################################################
case "${1:-once}" in
    once)
        generate_report
        ;;
    continuous)
        monitor_continuous
        ;;
    *)
        echo "Uso: $0 [once|continuous]"
        exit 1
        ;;
esac
