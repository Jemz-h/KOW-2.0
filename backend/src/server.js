const http = require('http');
const app = require('./app');
const { port, dbMode } = require('./config/env');
const { connectDatabase, closeDatabase } = require('./config/db');

async function bootstrap() {
  await connectDatabase();

  const server = http.createServer(app);
  server.listen(port, () => {
    console.log(`KOW backend listening on port ${port} (${dbMode} mode)`);
  });

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
