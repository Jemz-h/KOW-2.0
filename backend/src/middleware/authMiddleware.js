const crypto = require('crypto');

const TOKEN_SECRET = process.env.TOKEN_SECRET || 'kow-dev-secret-change-me';

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

function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const match = header.match(/^Bearer\s+(.+)$/i);

  if (!match) {
    return res.status(401).json({
      error: 'Missing or invalid Authorization header',
      code: 'AUTH_REQUIRED',
      details: {},
    });
  }

  try {
    const payload = verifyToken(match[1]);
    req.auth = payload;
    return next();
  } catch (error) {
    return res.status(401).json({
      error: error.message || 'Invalid token',
      code: 'AUTH_INVALID',
      details: {},
    });
  }
}

function requireRole(allowedRoles) {
  const allowed = new Set(Array.isArray(allowedRoles) ? allowedRoles : [allowedRoles]);

  return (req, res, next) => {
    const role = req.auth?.role;
    if (!role || !allowed.has(role)) {
      return res.status(403).json({
        error: 'Insufficient role',
        code: 'AUTH_FORBIDDEN',
        details: { required: [...allowed] },
      });
    }

    return next();
  };
}

module.exports = {
  requireAuth,
  requireRole,
};
