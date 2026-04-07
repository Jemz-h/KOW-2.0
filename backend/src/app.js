const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const { getConnectedAdminCount } = require('./services/wsHub');
const { errorHandler, notFound } = require('./middleware/errorMiddleware');

const authRoutes = require('./routes/authRoutes');
const quizRoutes = require('./routes/quizRoutes');
const userRoutes = require('./routes/userRoutes');
const levelRoutes = require('./routes/levelRoutes');
const progressRoutes = require('./routes/progressRoutes');
const studentRoutes = require('./routes/studentRoutes');
const contentRoutes = require('./routes/contentRoutes');
const syncRoutes = require('./routes/syncRoutes');
const adminRoutes = require('./routes/adminRoutes');

function createApp() {
  const app = express();

  app.use(helmet());
  app.use(cors());
  app.use(express.json({ limit: '1mb' }));
  app.use(express.urlencoded({ extended: false }));

  if (process.env.NODE_ENV === 'development') {
    app.use(morgan('dev'));
  } else {
    app.use(morgan('combined'));
  }

  app.use('/api/auth', authRoutes);
  app.use('/api/quiz', quizRoutes);
  app.use('/api/users', userRoutes);
  app.use('/api/levels', levelRoutes);
  app.use('/api/progress', progressRoutes);
  app.use('/api/students', studentRoutes);
  app.use('/api/content', contentRoutes);
  app.use('/api/sync', syncRoutes);
  app.use('/api/admin', adminRoutes);

  app.get('/api/health', (req, res) => {
    res.status(200).json({
      success: true,
      status: 'ok',
      message: 'API is running successfully',
      ws_clients: getConnectedAdminCount(),
      uptime_seconds: Math.floor(process.uptime()),
    });
  });

  app.use(notFound);
  app.use(errorHandler);

  return app;
}

module.exports = {
  createApp,
};
