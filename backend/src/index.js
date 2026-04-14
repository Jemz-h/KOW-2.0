const http = require('http');
const { loadEnv } = require('./config/loadEnv');
loadEnv();

const db = require('./config/db');
const { initWebSocket } = require('./services/wsHub');
const { createApp } = require('./app');
const preferredPort = Number(process.env.PORT || 3000);
const maxPortAttempts = 20;

function isPortInUseError(error) {
  return error && error.code === 'EADDRINUSE';
}

async function startServer() {
  await db.initialize();
  const app = createApp();
  const server = http.createServer(app);

  for (let attempt = 0; attempt < maxPortAttempts; attempt++) {
    const port = preferredPort + attempt;

    try {
      await new Promise((resolve, reject) => {
        const onError = (error) => {
          server.off('error', onError);
          reject(error);
        };

        server.once('error', onError);
        server.listen(port, () => {
          server.off('error', onError);
          resolve();
        });
      });

      process.env.PORT = String(port);
      initWebSocket(server);

      console.log(`Server running in ${process.env.NODE_ENV || 'development'} mode on http://localhost:${port}`);
      if (port !== preferredPort) {
        console.log(`Preferred port ${preferredPort} was busy; auto-selected ${port}`);
      }

      return;
    } catch (error) {
      if (!isPortInUseError(error)) {
        throw error;
      }

      if (attempt === maxPortAttempts - 1) {
        throw new Error(`Unable to find a free port starting from ${preferredPort}`);
      }
    }
  }
}

if (require.main === module) {
  startServer().catch((error) => {
    console.error('Fatal startup error:', error.message);
    process.exit(1);
  });
}

module.exports = {
  startServer,
};
