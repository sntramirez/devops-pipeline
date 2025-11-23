# Infrastructure as Code (IaC) - Guía Completa

Esta guía explica cómo configurar un servidor Ubuntu desde cero y desplegar la aplicación automáticamente.

## 📋 Tabla de Contenidos

- [Requisitos](#requisitos)
- [Inicio Rápido](#inicio-rápido)
- [Configuración Detallada](#configuración-detallada)
- [Scripts Disponibles](#scripts-disponibles)
- [Métodos de Deployment](#métodos-de-deployment)
- [Auto-Deploy con Webhooks](#auto-deploy-con-webhooks)
- [Monitoreo](#monitoreo)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Requisitos

- **Sistema Operativo**: Ubuntu 20.04 LTS o superior
- **Acceso**: Root o sudo
- **RAM**: Mínimo 1GB, recomendado 2GB+
- **Disco**: Mínimo 10GB libres
- **Red**: Acceso a Internet

---

## 🚀 Inicio Rápido

### Opción 1: Bootstrap Completo (Máquina Nueva)

En una **máquina Ubuntu completamente limpia**, ejecuta:

```bash
# Clonar el repositorio
git clone https://github.com/sntramirez/devops-pipeline.git
cd devops-pipeline

# Ejecutar bootstrap (instala TODO desde cero)
sudo bash infrastructure/bootstrap.sh
```

Este script instalará automáticamente:
- ✅ Node.js 20
- ✅ npm
- ✅ PM2
- ✅ Docker y Docker Compose
- ✅ Servicios systemd
- ✅ Firewall configurado
- ✅ Usuario de aplicación

### Opción 2: Deployment Rápido (Sistema Ya Configurado)

Si ya tienes Node.js y las dependencias instaladas:

```bash
# Desplegar aplicación
bash infrastructure/deploy.sh
```

### Opción 3: Usando Make

```bash
# Ver todos los comandos disponibles
make help

# Bootstrap completo
make bootstrap

# Desplegar
make deploy

# Iniciar aplicación
make start-pm2
```

---

## 🔧 Configuración Detallada

### 1. Bootstrap del Servidor

El script `infrastructure/bootstrap.sh` configura el servidor desde cero.

**Variables de entorno personalizables:**

```bash
# Personalizar configuración
export APP_USER="miusuario"          # Usuario de la aplicación (default: appuser)
export APP_DIR="/opt/mi-app"          # Directorio de instalación (default: /opt/devops-pipeline)
export NODE_VERSION="18"              # Versión de Node.js (default: 20)

# Ejecutar bootstrap
sudo bash infrastructure/bootstrap.sh
```

**Lo que hace el bootstrap:**

1. ✅ Actualiza el sistema operativo
2. ✅ Instala dependencias del sistema (git, curl, build-essential, etc.)
3. ✅ Instala Node.js desde NodeSource
4. ✅ Instala PM2 globalmente
5. ✅ Instala Docker y Docker Compose
6. ✅ Crea usuario de aplicación
7. ✅ Configura directorio de aplicación
8. ✅ Configura firewall (UFW)
9. ✅ Crea servicios systemd

**Puertos abiertos por defecto:**
- `22` - SSH
- `80` - HTTP
- `443` - HTTPS
- `3000` - Aplicación Node.js

### 2. Deployment de la Aplicación

El script `infrastructure/deploy.sh` despliega la aplicación desde Git.

**Variables de configuración:**

```bash
export APP_DIR="/opt/devops-pipeline"                      # Directorio de la app
export REPO_URL="https://github.com/tu-usuario/tu-repo"   # URL del repositorio
export BRANCH="master"                                      # Rama a desplegar
export DEPLOY_METHOD="pm2"                                  # Método: pm2, systemd, docker
export SKIP_TESTS="false"                                   # Saltar tests: true/false

# Ejecutar deployment
bash infrastructure/deploy.sh
```

**Pasos del deployment:**

1. 📥 Clona/actualiza código desde Git
2. 📦 Instala dependencias con npm
3. 🧪 Ejecuta tests (opcional)
4. 🔨 Ejecuta build
5. 🛑 Detiene aplicación anterior
6. ▶️ Inicia nueva versión
7. ✅ Verifica health check

### 3. Métodos de Ejecución

#### A) PM2 (Recomendado para producción)

```bash
# Configuración en ecosystem.config.js
make start-pm2

# O manualmente
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

**Ventajas de PM2:**
- ✅ Modo cluster (múltiples procesos)
- ✅ Auto-restart en caso de crash
- ✅ Logs centralizados
- ✅ Monitoreo en tiempo real
- ✅ Zero-downtime reload

**Comandos útiles de PM2:**
```bash
pm2 list                    # Ver aplicaciones
pm2 logs devops-pipeline    # Ver logs
pm2 restart devops-pipeline # Reiniciar
pm2 stop devops-pipeline    # Detener
pm2 monit                   # Monitor en tiempo real
```

#### B) Systemd (Método tradicional)

```bash
# Iniciar servicio
sudo systemctl start devops-pipeline

# Habilitar inicio automático
sudo systemctl enable devops-pipeline

# Ver estado
sudo systemctl status devops-pipeline

# Ver logs
sudo journalctl -u devops-pipeline -f
```

#### C) Docker (Containerizado)

```bash
# Usando docker-compose
make docker-compose-up

# O manualmente
docker-compose up -d

# Ver logs
docker-compose logs -f

# Detener
docker-compose down
```

---

## 📜 Scripts Disponibles

### Infrastructure Scripts

| Script | Descripción |
|--------|-------------|
| `infrastructure/bootstrap.sh` | Configuración completa del servidor desde cero |
| `infrastructure/deploy.sh` | Deployment automatizado desde Git |
| `infrastructure/install-dependencies.sh` | Instalación de dependencias npm |
| `infrastructure/setup-services.sh` | Configuración de servicios systemd y PM2 |
| `infrastructure/webhook-server.sh` | Servidor de webhooks para auto-deploy |
| `infrastructure/monitoring.sh` | Monitoreo y health checks |

### Uso de Scripts

```bash
# Bootstrap completo
sudo bash infrastructure/bootstrap.sh

# Deploy desde Git
bash infrastructure/deploy.sh

# Deploy rápido (sin tests)
SKIP_TESTS=true bash infrastructure/deploy.sh

# Setup de webhooks
bash infrastructure/webhook-server.sh

# Monitoreo
bash infrastructure/monitoring.sh once          # Una vez
bash infrastructure/monitoring.sh continuous    # Continuo
```

---

## 🔄 Auto-Deploy con Webhooks

Configura deployment automático cuando haces push a GitHub.

### 1. Instalar Servidor de Webhooks

```bash
bash infrastructure/webhook-server.sh
```

Esto instalará y configurará un servidor de webhooks en el puerto `9000`.

### 2. Configurar en GitHub

1. Ve a tu repositorio en GitHub
2. **Settings** → **Webhooks** → **Add webhook**
3. Configura:
   - **Payload URL**: `http://tu-servidor-ip:9000/hooks/deploy-master`
   - **Content type**: `application/json`
   - **Secret**: El secret configurado (default: `changeme`)
   - **Events**: Just the push event
   - **Active**: ✅

4. Guarda el webhook

### 3. Probar Auto-Deploy

```bash
# Hacer un cambio
echo "test" >> test.txt
git add test.txt
git commit -m "test: probar auto-deploy"
git push origin master

# El servidor recibirá el webhook y desplegará automáticamente
```

### 4. Ver Logs de Webhooks

```bash
sudo journalctl -u webhook -f
```

---

## 📊 Monitoreo

### Script de Monitoreo

```bash
# Ejecutar monitoreo una vez
bash infrastructure/monitoring.sh once

# Monitoreo continuo (actualiza cada 60s)
bash infrastructure/monitoring.sh continuous
```

El script verifica:
- ✅ Health check de la aplicación
- ✅ Uso de CPU
- ✅ Uso de memoria
- ✅ Espacio en disco
- ✅ Estado de servicios (PM2, Docker, systemd)
- ✅ Errores en logs

### Monitoreo con PM2

```bash
# Monitor en tiempo real
pm2 monit

# Ver métricas
pm2 status
pm2 info devops-pipeline
```

### Health Check Manual

```bash
# Verificar endpoint de health
curl http://localhost:3000/health

# Usando make
make health-check
```

---

## 🛠️ Troubleshooting

### Problema: Bootstrap falla en instalación de Node.js

**Solución:**
```bash
# Limpiar repositorios de Node.js
sudo rm -rf /etc/apt/sources.list.d/nodesource.list
sudo apt-get update

# Volver a ejecutar bootstrap
sudo bash infrastructure/bootstrap.sh
```

### Problema: No puede conectar a Docker

**Solución:**
```bash
# Reiniciar sesión para aplicar cambios de grupo
su - $USER

# O reiniciar servicio Docker
sudo systemctl restart docker
```

### Problema: Puerto 3000 ya está en uso

**Solución:**
```bash
# Ver qué proceso usa el puerto
sudo lsof -i :3000

# Detener proceso
sudo kill -9 <PID>

# O cambiar puerto
export PORT=3001
npm start
```

### Problema: Tests fallan durante deployment

**Solución:**
```bash
# Deploy sin tests
SKIP_TESTS=true bash infrastructure/deploy.sh

# O ejecutar tests manualmente para debug
cd /opt/devops-pipeline
npm test -- --verbose
```

### Problema: Firewall bloquea acceso

**Solución:**
```bash
# Ver reglas de firewall
sudo ufw status verbose

# Permitir puerto
sudo ufw allow 3000/tcp

# Recargar firewall
sudo ufw reload
```

### Problema: Aplicación no inicia con PM2

**Solución:**
```bash
# Ver logs de error
pm2 logs devops-pipeline --err --lines 50

# Eliminar y reiniciar
pm2 delete devops-pipeline
pm2 start ecosystem.config.js

# Verificar permisos
sudo chown -R appuser:appuser /opt/devops-pipeline
```

---

## 🔐 Seguridad

### Recomendaciones de Seguridad

1. **Cambiar secreto de webhook**
   ```bash
   # Editar archivo
   sudo nano /opt/webhook/hooks.json
   # Cambiar "secret": "changeme" por un valor fuerte
   ```

2. **Configurar HTTPS con Let's Encrypt**
   ```bash
   sudo apt-get install certbot
   sudo certbot --nginx
   ```

3. **Actualizar sistema regularmente**
   ```bash
   sudo apt-get update && sudo apt-get upgrade -y
   ```

4. **Configurar fail2ban**
   ```bash
   sudo systemctl enable fail2ban
   sudo systemctl start fail2ban
   ```

5. **Revisar logs regularmente**
   ```bash
   sudo journalctl -p err -b  # Ver errores del sistema
   pm2 logs --err             # Ver errores de aplicación
   ```

---

## 📝 Comandos Rápidos

```bash
# Bootstrap completo (máquina nueva)
sudo bash infrastructure/bootstrap.sh

# Deploy aplicación
bash infrastructure/deploy.sh

# Iniciar con PM2
pm2 start ecosystem.config.js

# Ver logs
pm2 logs devops-pipeline

# Reiniciar aplicación
pm2 restart devops-pipeline

# Ver estado
pm2 status

# Monitoreo
bash infrastructure/monitoring.sh once

# Health check
curl http://localhost:3000/health

# Detener aplicación
pm2 stop devops-pipeline

# Ver logs de sistema
sudo journalctl -u devops-pipeline -f
```

---

## 🔄 Flujo Completo de Deployment

```
┌─────────────────────────────────────────────┐
│  1. Máquina Ubuntu nueva                    │
└────────────────┬────────────────────────────┘
                 ▼
┌─────────────────────────────────────────────┐
│  2. Ejecutar bootstrap.sh                   │
│     - Instala Node.js, Docker, PM2          │
│     - Configura firewall y servicios        │
└────────────────┬────────────────────────────┘
                 ▼
┌─────────────────────────────────────────────┐
│  3. Clonar/Deploy repositorio               │
│     bash infrastructure/deploy.sh           │
└────────────────┬────────────────────────────┘
                 ▼
┌─────────────────────────────────────────────┐
│  4. Aplicación desplegada y funcionando     │
│     http://localhost:3000                   │
└────────────────┬────────────────────────────┘
                 ▼
┌─────────────────────────────────────────────┐
│  5. (Opcional) Configurar webhooks          │
│     bash infrastructure/webhook-server.sh   │
└────────────────┬────────────────────────────┘
                 ▼
┌─────────────────────────────────────────────┐
│  6. Push a GitHub → Auto-deploy            │
└─────────────────────────────────────────────┘
```

---

## 📚 Recursos Adicionales

- [Documentación de PM2](https://pm2.keymetrics.io/)
- [Docker Docs](https://docs.docker.com/)
- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)
- [Ubuntu Server Guide](https://ubuntu.com/server/docs)

---

**¡Infraestructura configurada y lista para desplegar en cualquier máquina Ubuntu!** 🎉
