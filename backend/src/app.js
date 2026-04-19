const express = require('express');
const { dbMode } = require('./config/env');
const authRoutes = require('./routes/authRoutes');
const adminRoutes = require('./routes/adminRoutes');
const studentRoutes = require('./routes/studentRoutes');
const userRoutes = require('./routes/userRoutes');
const levelRoutes = require('./routes/levelRoutes');
const quizRoutes = require('./routes/quizRoutes');
const contentRoutes = require('./routes/contentRoutes');
const syncRoutes = require('./routes/syncRoutes');
const progressRoutes = require('./routes/progressRoutes');
const achievementRoutes = require('./routes/achievementRoutes');
const leaderboardRoutes = require('./routes/leaderboardRoutes');
const { notFoundHandler, errorHandler } = require('./middleware/errorHandler');

const app = express();

app.use((req, res, next) => {
  const origin = req.headers.origin;
  const requestedHeaders = req.headers['access-control-request-headers'];

  if (origin) {
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Vary', 'Origin');
  }

  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,PUT,PATCH,DELETE,OPTIONS');
  res.setHeader(
    'Access-Control-Allow-Headers',
    requestedHeaders || 'Content-Type, Authorization'
  );

  if (req.method === 'OPTIONS') {
    return res.sendStatus(204);
  }

  return next();
});

app.use(express.json());

app.use((req, res, next) => {
  const startedAt = Date.now();
  res.on('finish', () => {
    const elapsed = Date.now() - startedAt;
    console.log(`[API] ${req.method} ${req.originalUrl} -> ${res.statusCode} (${elapsed}ms)`);
  });
  next();
});

const healthHandler = (req, res) => {
  res.status(200).json({
    status: 'ok',
    mode: dbMode,
  });
};

app.get('/api/health', healthHandler);
app.get('/health', healthHandler);

app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/students', studentRoutes);
app.use('/api/users', userRoutes);
app.use('/api/levels', levelRoutes);
app.use('/api/quiz', quizRoutes);
app.use('/api/content', contentRoutes);
app.use('/api/sync', syncRoutes);
app.use('/api/progress', progressRoutes);
app.use('/api/achievements', achievementRoutes);
app.use('/api/leaderboard', leaderboardRoutes);

app.use(notFoundHandler);
app.use(errorHandler);

module.exports = app;
module.exports.createApp = () => app;
