const express = require('express');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());

// Ruta principal
app.get('/', (req, res) => {
  res.json({
    message: 'Pipeline CI/CD funcionando correctamente',
    version: '1.0.0',
    status: 'OK'
  });
});

// Ruta de health check
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy' });
});

// Función exportable para testing
const sumar = (a, b) => a + b;

// Solo iniciar servidor si no estamos en modo test
if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`Servidor corriendo en puerto ${PORT}`);
  });
}

module.exports = { app, sumar };
