const http = require('http');
require('dotenv').config();

const db = require('./config/db');
const { initWebSocket } = require('./services/wsHub');
const { createApp } = require('./app');
const port = process.env.PORT || 3000;

async function startServer() {
  await db.initialize();
  const app = createApp();
  const server = http.createServer(app);
  initWebSocket(server);

  server.listen(port, () => {
    console.log(`Server running in ${process.env.NODE_ENV || 'development'} mode on http://localhost:${port}`);
  });
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
