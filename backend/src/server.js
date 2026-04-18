const http = require('http');
const { loadEnv } = require('./config/loadEnv');
loadEnv();

const app = require('./app');
const { port, dbMode } = require('./config/env');
const { connectDatabase, closeDatabase } = require('./config/db');

const maxPortAttempts = 20;

function isPortInUseError(error) {
  return error && error.code === 'EADDRINUSE';
}

async function listenWithFallback(server, preferredPort) {
  for (let attempt = 0; attempt < maxPortAttempts; attempt++) {
    const candidatePort = preferredPort + attempt;

    try {
      await new Promise((resolve, reject) => {
        const onError = (error) => {
          server.off('error', onError);
          reject(error);
        };

        server.once('error', onError);
        server.listen(candidatePort, () => {
          server.off('error', onError);
          resolve();
        });
      });

      return candidatePort;
    } catch (error) {
      if (!isPortInUseError(error)) {
        throw error;
      }

      if (attempt === maxPortAttempts - 1) {
        throw new Error(`Unable to find a free port starting from ${preferredPort}`);
      }
    }
  }

  throw new Error(`Unable to find a free port starting from ${preferredPort}`);
}

async function bootstrap() {
  await connectDatabase();

  const server = http.createServer(app);
  const actualPort = await listenWithFallback(server, port);

  console.log(`KOW backend listening on port ${actualPort} (${dbMode} mode)`);
  if (actualPort !== port) {
    console.log(`Preferred port ${port} is busy; using ${actualPort} instead.`);
  }

  const shutdown = async () => {
    server.close(async () => {
      try {
        await closeDatabase();
      } finally {
        process.exit(0);
      }
    });
  };

  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
}

bootstrap().catch((error) => {
  console.error('Failed to bootstrap backend:', error);
  process.exit(1);
});
