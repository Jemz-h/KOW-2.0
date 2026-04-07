const express = require('express');
const router = express.Router();
const contentController = require('../controllers/contentController');
const { requireAuth, requireRole } = require('../middleware/authMiddleware');

router.get('/', requireAuth, requireRole(['device', 'admin']), contentController.getContent);

module.exports = router;
