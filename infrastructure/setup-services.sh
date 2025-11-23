#!/bin/bash

################################################################################
# Script de Configuración de Servicios Systemd
#
# Configura los servicios systemd para ejecutar la aplicación automáticamente
################################################################################

set -e

# Colores
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

# Variables de configuración
APP_USER="${APP_USER:-appuser}"
APP_DIR="${APP_DIR:-/opt/devops-pipeline}"
APP_NAME="devops-pipeline"

log_info "Configurando servicios systemd..."

################################################################################
# Crear archivo de servicio systemd
################################################################################
log_info "Creando servicio systemd: $APP_NAME"

sudo tee /etc/systemd/system/$APP_NAME.service > /dev/null <<EOF
[Unit]
Description=DevOps Pipeline Application
Documentation=https://github.com/tu-repo/devops-pipeline
After=network.target

[Service]
Type=simple
User=$APP_USER
WorkingDirectory=$APP_DIR
Environment=NODE_ENV=production
Environment=PORT=3000
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=$APP_NAME

# Límites de recursos
LimitNOFILE=65536
LimitNPROC=4096

# Seguridad
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$APP_DIR

[Install]
WantedBy=multi-user.target
EOF

log_info "✓ Archivo de servicio creado: /etc/systemd/system/$APP_NAME.service"

################################################################################
# Crear servicio PM2 alternativo
################################################################################
log_info "Configurando PM2 como alternativa..."

# Crear configuración de PM2
sudo -u $APP_USER tee $APP_DIR/ecosystem.config.js > /dev/null <<'EOF'
module.exports = {
  apps: [{
    name: 'devops-pipeline',
    script: './src/index.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true,
    autorestart: true,
    max_memory_restart: '500M',
    watch: false,
    ignore_watch: ['node_modules', 'logs'],
    merge_logs: true,
    max_restarts: 10,
    min_uptime: '10s'
  }]
};
EOF

# Crear directorio de logs
sudo mkdir -p $APP_DIR/logs
sudo chown -R $APP_USER:$APP_USER $APP_DIR/logs

log_info "✓ Configuración de PM2 creada: $APP_DIR/ecosystem.config.js"

################################################################################
# Configurar PM2 startup
################################################################################
if command -v pm2 &> /dev/null; then
    log_info "Configurando PM2 para inicio automático..."

    # Generar script de startup
    sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u $APP_USER --hp /home/$APP_USER

    log_info "✓ PM2 configurado para inicio automático"
else
    log_warn "PM2 no está instalado, saltando configuración de startup"
fi

################################################################################
# Recargar systemd
################################################################################
log_info "Recargando systemd daemon..."
sudo systemctl daemon-reload

log_info "✓ Servicios configurados correctamente"

echo ""
log_info "Servicios disponibles:"
echo "  - Systemd: sudo systemctl start $APP_NAME"
echo "  - PM2: pm2 start $APP_DIR/ecosystem.config.js"
echo ""
log_info "Para habilitar inicio automático:"
echo "  - Systemd: sudo systemctl enable $APP_NAME"
echo "  - PM2: Ya configurado con startup"
echo ""
