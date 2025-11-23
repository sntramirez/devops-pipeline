#!/bin/bash

################################################################################
# Servidor de Webhooks para Auto-Deploy
#
# Escucha webhooks de GitHub y ejecuta deploy automáticamente
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

WEBHOOK_PORT="${WEBHOOK_PORT:-9000}"
WEBHOOK_SECRET="${WEBHOOK_SECRET:-changeme}"

log_info "Instalando servidor de webhooks..."

# Crear directorio para webhook
WEBHOOK_DIR="/opt/webhook"
sudo mkdir -p $WEBHOOK_DIR

# Instalar webhook si no existe
if ! command -v webhook &> /dev/null; then
    log_info "Instalando webhook..."

    # Descargar webhook
    cd /tmp
    wget https://github.com/adnanh/webhook/releases/download/2.8.0/webhook-linux-amd64.tar.gz
    tar -xzf webhook-linux-amd64.tar.gz
    sudo mv webhook-linux-amd64/webhook /usr/local/bin/
    sudo chmod +x /usr/local/bin/webhook
    rm -rf webhook-linux-amd64*

    log_info "✓ Webhook instalado"
fi

# Crear configuración de hooks
sudo tee $WEBHOOK_DIR/hooks.json > /dev/null <<EOF
[
  {
    "id": "deploy-master",
    "execute-command": "/opt/devops-pipeline/infrastructure/deploy.sh",
    "command-working-directory": "/opt/devops-pipeline",
    "response-message": "Deployment iniciado",
    "trigger-rule": {
      "and": [
        {
          "match": {
            "type": "payload-hash-sha256",
            "secret": "$WEBHOOK_SECRET",
            "parameter": {
              "source": "header",
              "name": "X-Hub-Signature-256"
            }
          }
        },
        {
          "match": {
            "type": "value",
            "value": "refs/heads/master",
            "parameter": {
              "source": "payload",
              "name": "ref"
            }
          }
        }
      ]
    }
  },
  {
    "id": "deploy-develop",
    "execute-command": "/opt/devops-pipeline/infrastructure/deploy.sh",
    "command-working-directory": "/opt/devops-pipeline",
    "response-message": "Deployment de desarrollo iniciado",
    "pass-environment-to-command": [
      {
        "envname": "BRANCH",
        "source": "string",
        "name": "develop"
      }
    ],
    "trigger-rule": {
      "and": [
        {
          "match": {
            "type": "payload-hash-sha256",
            "secret": "$WEBHOOK_SECRET",
            "parameter": {
              "source": "header",
              "name": "X-Hub-Signature-256"
            }
          }
        },
        {
          "match": {
            "type": "value",
            "value": "refs/heads/develop",
            "parameter": {
              "source": "payload",
              "name": "ref"
            }
          }
        }
      ]
    }
  }
]
EOF

log_info "✓ Configuración de webhooks creada"

# Crear servicio systemd para webhook
sudo tee /etc/systemd/system/webhook.service > /dev/null <<EOF
[Unit]
Description=Webhook Server for Auto-Deploy
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/webhook -hooks $WEBHOOK_DIR/hooks.json -port $WEBHOOK_PORT -verbose
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Recargar systemd y habilitar servicio
sudo systemctl daemon-reload
sudo systemctl enable webhook
sudo systemctl restart webhook

log_info "✓ Servidor de webhooks configurado"

# Configurar firewall
sudo ufw allow $WEBHOOK_PORT/tcp comment 'Webhook Server'

echo ""
log_info "Servidor de webhooks iniciado en puerto $WEBHOOK_PORT"
log_info "URL del webhook: http://tu-servidor:$WEBHOOK_PORT/hooks/deploy-master"
echo ""
log_info "Configuración en GitHub:"
echo "  1. Ve a tu repositorio > Settings > Webhooks > Add webhook"
echo "  2. Payload URL: http://tu-servidor-ip:$WEBHOOK_PORT/hooks/deploy-master"
echo "  3. Content type: application/json"
echo "  4. Secret: $WEBHOOK_SECRET"
echo "  5. Events: Just the push event"
echo ""
log_info "Ver logs: sudo journalctl -u webhook -f"
