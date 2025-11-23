# DevOps Pipeline - CI/CD Completo

Este proyecto implementa un pipeline completo de CI/CD (Integración Continua y Despliegue Continuo) utilizando GitHub Actions.

## 🚀 Características

- ✅ Integración Continua (CI) automática
- ✅ Despliegue Continuo (CD) a producción
- ✅ Tests automatizados
- ✅ Linting de código
- ✅ Build en múltiples versiones de Node.js
- ✅ Análisis de calidad de código
- ✅ Docker support
- ✅ Health checks

## 📋 Estructura del Proyecto

```
devops-pipeline/
├── .github/
│   └── workflows/
│       ├── ci.yml          # Pipeline de CI
│       └── cd.yml          # Pipeline de CD
├── src/
│   ├── index.js            # Aplicación principal
│   └── index.test.js       # Tests
├── package.json            # Dependencias y scripts
├── Dockerfile              # Imagen Docker
├── docker-compose.yml      # Orquestación Docker
└── README.md              # Este archivo
```

## 🔄 Pipeline de CI/CD

### Pipeline de CI (Integración Continua)

Se ejecuta en cada **push** o **pull request** a las ramas `develop`, `master` o `main`.

**Pasos del CI:**

1. **Build y Test** (en Node.js 16, 18 y 20):
   - Checkout del código
   - Instalación de dependencias
   - Ejecución de linter
   - Ejecución de tests
   - Build del proyecto
   - Generación de artefactos

2. **Análisis de Calidad**:
   - Verificación de formato de código
   - Generación de reporte de cobertura

3. **Notificación**:
   - Reporte del estado del pipeline

### Pipeline de CD (Despliegue Continuo)

Se ejecuta solo en **push** a las ramas `master` o `main`.

**Pasos del CD:**

1. **Deploy a Producción**:
   - Checkout del código
   - Instalación de dependencias
   - Ejecución de tests
   - Build de producción
   - Despliegue
   - Creación de tags de release

2. **Post-Deploy**:
   - Health check
   - Notificaciones

## 🛠️ Instalación y Uso

### Requisitos Previos

- Node.js 16.x o superior
- npm o yarn
- Docker (opcional)

### Instalación Local

```bash
# Clonar el repositorio
git clone <tu-repositorio>
cd devops-pipeline

# Instalar dependencias
npm install

# Ejecutar tests
npm test

# Ejecutar la aplicación
npm start
```

### Usando Docker

```bash
# Build de la imagen
docker build -t devops-pipeline .

# Ejecutar el contenedor
docker run -p 3000:3000 devops-pipeline

# O usar docker-compose
docker-compose up
```

## 📝 Scripts Disponibles

```bash
npm start        # Inicia el servidor
npm test         # Ejecuta los tests
npm run build    # Compila el proyecto
npm run lint     # Verifica el código con ESLint
```

## 🌐 Endpoints de la API

- `GET /` - Endpoint principal, retorna información del servicio
- `GET /health` - Health check endpoint

## 🔧 Configuración del Pipeline

### Activar GitHub Actions

1. Ve a tu repositorio en GitHub
2. Click en la pestaña **Actions**
3. Los workflows se activarán automáticamente

### Modificar el Pipeline

Los archivos de configuración están en:
- `.github/workflows/ci.yml` - Configuración de CI
- `.github/workflows/cd.yml` - Configuración de CD

### Variables de Entorno

Puedes añadir secrets en GitHub:
1. Ve a **Settings** > **Secrets and variables** > **Actions**
2. Añade tus secrets (API keys, tokens, etc.)

## 🔀 Flujo de Trabajo

### Para Desarrollo

```bash
# Crear una rama desde develop
git checkout -b feature/mi-feature develop

# Hacer cambios y commits
git add .
git commit -m "feat: nueva característica"

# Push y crear PR
git push origin feature/mi-feature
```

El pipeline de CI se ejecutará automáticamente en el PR.

### Para Producción

```bash
# Merge a master/main
git checkout master
git merge develop
git push origin master
```

El pipeline de CD se ejecutará automáticamente y desplegará a producción.

## 📊 Monitoreo

El pipeline genera:
- ✅ Estado de builds en GitHub Actions
- ✅ Artefactos de build
- ✅ Reportes de cobertura
- ✅ Logs detallados

## 🐛 Solución de Problemas

### El pipeline falla en tests
```bash
# Ejecutar tests localmente
npm test

# Ver cobertura
npm test -- --coverage
```

### El pipeline falla en lint
```bash
# Ejecutar linter localmente
npm run lint

# Auto-fix (si es posible)
npm run lint -- --fix
```

### El build falla
```bash
# Ejecutar build localmente
npm run build

# Verificar dependencias
npm ci
```

## 📚 Próximos Pasos

- [ ] Añadir despliegue a servicios cloud (AWS, Azure, GCP)
- [ ] Integrar análisis de seguridad (Snyk, Dependabot)
- [ ] Añadir tests E2E
- [ ] Implementar feature flags
- [ ] Configurar notificaciones (Slack, Discord)
- [ ] Añadir monitoreo y observabilidad

## 🤝 Contribuir

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

MIT License

## 📞 Soporte

Para preguntas o problemas, abre un issue en el repositorio.

---

**¡Pipeline configurado y listo para usar!** 🎉
