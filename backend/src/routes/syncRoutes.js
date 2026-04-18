const express = require('express');
const router = express.Router();
const syncController = require('../controllers/syncController');
const { requireAuth, requireRole } = require('../middleware/authMiddleware');

router.post('/', requireAuth, requireRole(['device', 'admin']), syncController.syncBatch);

module.exports = router;
