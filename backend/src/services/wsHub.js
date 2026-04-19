const { WebSocketServer } = require('ws');
const crypto = require('crypto');

const TOKEN_SECRET =
  process.env.TOKEN_SECRET ||
  process.env.JWT_SECRET ||
  'kow-dev-secret-change-me';

let wss;
const adminClients = new Set();

function base64UrlDecode(value) {
  const normalized = value.replace(/-/g, '+').replace(/_/g, '/');
  const padLength = (4 - (normalized.length % 4)) % 4;
  const padded = normalized + '='.repeat(padLength);
  return Buffer.from(padded, 'base64').toString('utf8');
}

function verifyToken(token) {
  const parts = String(token || '').split('.');
  if (parts.length !== 3) {
    throw new Error('Malformed token');
  }

  const [encodedHeader, encodedPayload, providedSignature] = parts;
  const data = `${encodedHeader}.${encodedPayload}`;

  const expectedSignature = crypto
    .createHmac('sha256', TOKEN_SECRET)
    .update(data)
    .digest('base64')
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');

  if (providedSignature !== expectedSignature) {
    throw new Error('Invalid token signature');
  }

  const payload = JSON.parse(base64UrlDecode(encodedPayload));
  const now = Math.floor(Date.now() / 1000);
  if (typeof payload.exp === 'number' && payload.exp < now) {
    throw new Error('Token expired');
  }

  return payload;
}

function extractToken(req) {
  const url = new URL(req.url, 'http://localhost');
  const tokenFromQuery = url.searchParams.get('token');
  if (tokenFromQuery) {
    return tokenFromQuery;
  }

  const authHeader = req.headers.authorization || '';
  const match = authHeader.match(/^Bearer\s+(.+)$/i);
  return match ? match[1] : null;
}

function initWebSocket(server) {
  wss = new WebSocketServer({ server, path: '/ws' });

  wss.on('connection', (socket, req) => {
    try {
      const token = extractToken(req);
      const payload = verifyToken(token);
      const role = payload?.role;

      if (role !== 'admin' && role !== 'readonly') {
        socket.close(1008, 'Forbidden');
        return;
      }

      adminClients.add(socket);

      socket.send(JSON.stringify({ type: 'connected', role }));

      socket.on('close', () => {
        adminClients.delete(socket);
      });
    } catch (_) {
      socket.close(1008, 'Unauthorized');
    }
  });
}

function broadcastToAdmins(payload) {
  const message = JSON.stringify(payload);

  for (const socket of adminClients) {
    if (socket.readyState === 1) {
      socket.send(message);
    }
  }
}

function getConnectedAdminCount() {
  return adminClients.size;
}

module.exports = {
  initWebSocket,
  broadcastToAdmins,
  getConnectedAdminCount,
};
